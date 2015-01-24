#include "wsserver.h"
#include "QtWebSockets/qwebsocketserver.h"
#include "QtWebSockets/qwebsocket.h"
#include <QtCore/QDebug>


QT_USE_NAMESPACE


WsServer::WsServer(quint16 port, QObject *parent) :
    QObject(parent),
	m_pWebSocketServer(new QWebSocketServer(QStringLiteral("PatternServer"),
                                            QWebSocketServer::NonSecureMode, this)),
    m_clients()
{
    if (m_pWebSocketServer->listen(QHostAddress::Any, port)) {
        qDebug() << "WsServer listening on port" << port;
        connect(m_pWebSocketServer, &QWebSocketServer::newConnection,
                this, &WsServer::onNewConnection);
        connect(m_pWebSocketServer, &QWebSocketServer::closed, this, &WsServer::closed);
    }
	patternQue << QStringList() << QStringList()<<QStringList(); // define the list
	names << QStringList() << QStringList()<<QStringList();
	freeToPlay<<1<<1<<1;
	modeNames<<"Slendro"<<"Pelog"<<"Bohlen-Pierce";
	mode = 0;

}


WsServer::~WsServer()
{
    m_pWebSocketServer->close();
    qDeleteAll(m_clients.begin(), m_clients.end());
}


void WsServer::onNewConnection()
{
    QWebSocket *pSocket = m_pWebSocketServer->nextPendingConnection();

    connect(pSocket, &QWebSocket::textMessageReceived, this, &WsServer::processTextMessage);
    //connect(pSocket, &QWebSocket::binaryMessageReceived, this, &WsServer::processBinaryMessage);
    connect(pSocket, &QWebSocket::disconnected, this, &WsServer::socketDisconnected);

    m_clients << pSocket;
    emit newConnection(m_clients.count());
	pSocket->sendTextMessage("mode,"+QString::number(mode)); // to set the active mode on connect
}

int randInt(int low, int high) {
	return qrand() % ((high + 1) - low) + low;
}

void WsServer::processTextMessage(QString message)
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (!pClient) {
        return;
    }
	qDebug()<<message;

	QStringList messageParts = message.split(",");

	if (message.startsWith("random")) { // create random pattern, add to que format: random,<voice>
		int voice = messageParts[1].toInt();
		QString pattern;
		pattern.sprintf("pattern,tester%d,%d,%d,%d,%d,steps:,%d,%d,%d,%d,%d,%d",randInt(1,100),voice, randInt(0,5),randInt(2,10), randInt(1,8), randInt(-1,5), randInt(-1,5), randInt(-1,5), randInt(-1,5), randInt(-1,5), randInt(-1,5) );
		qDebug()<<"Generated random pattern for voice "<<voice<<": "<<pattern;
		message=pattern; // replace message for further processing
		messageParts = message.split(",");
	}


	// pattern-message format: 'pattern' name voice repeatNtimes afterNsquares steps: pitch_index11 pitch_index2
	if (message.startsWith("pattern")) {
		//emit newMessage(message);
		int voice = messageParts[2].toInt();
		//TODO: add name to namesList
		patternQue[voice].append(message);
		names[voice].append(messageParts[1]); // store names to list
		emit namesChanged(voice, names[voice].join("\n"));
		qDebug()<<"New pattern from "<< messageParts[1] << message;
		qDebug()<<"Messages in list per voice: "<<voice<<": "<<patternQue[voice].count();
		if (freeToPlay[voice]) {
			sendFirstMessage(voice);
		}

	} else 	if (message.startsWith("new")) { // for testing only. send message from js console of browser wit doSend("new 1") or similar
		int voice = messageParts[1].toInt();
		freeToPlay[voice]=1;
		sendFirstMessage(voice);

	} else if (message.startsWith("property")) {
	// send control messages either for brain-headset or csound cahnnels as f.e. "property,attention,0.25", "property,level,0.5"

		emit newPropertyValue(messageParts[1], messageParts[2].toDouble());

	} else if (message.startsWith("square")) { // command to change square duration: squareDuration voice duration. Send to csound as code for compileOrc
		int voice = messageParts[1].toInt();
		float duration = messageParts[2].toFloat();
//		QString code;
//		code.sprintf("schedule \"setSquare\",0,10, %d, %f", voice, duration);
//				// old:"gkSquareDuration["+messageParts[1]+"] init "+ messageParts[2];
		//emit newCodeToComplie(code);
		qDebug()<<"Voice "<<voice<<" New square duration: "<<duration;
		emit newPropertyValue("square"+QString::number(voice+1), messageParts[2].toDouble()); // set via channel

		//TODO: squareDuration to PatternRect

	} else if (message.startsWith("schedule") || message.contains("init")) { //right now only schedule or init commands are accepted
		emit newCodeToComplie(message);
		if (message.contains("setMode"))  {
				mode = messageParts[3].toInt();
				emit newMessage("mode,"+modeNames[mode]); // bit cryptic code, should extract the scale and forward to qml
				foreach (QWebSocket * client, m_clients) {
					client->sendTextMessage("mode,"+messageParts[3]); // tell the clients about mode change
				}
		}

	} else if (message.startsWith("clear") || message.contains("init")) { //right now only schedule or init commands are accepted
		int voice = messageParts[1].toInt();
		patternQue[voice].clear();
		names[voice].clear();
		sendFirstMessage(voice); // to emit siganl to qml to clear
	}



}

//void WsServer::processBinaryMessage(QByteArray message)
//{
//    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
//    if (pClient) {
//        pClient->sendBinaryMessage(message);
//    }
//}

void WsServer::socketDisconnected()
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (pClient) {
        m_clients.removeAll(pClient);
        emit newConnection(m_clients.count());
        pClient->deleteLater();
	}
}


void WsServer::sendMessage(QWebSocket *socket, QString message )
{
    if (socket == 0)
    {
        return;
    }
    socket->sendTextMessage(message);

}

void WsServer::sendFirstMessage(int voice)
{
	if (!freeToPlay[voice]) {
		qDebug()<<"Voice "<<voice<<" is not free to play!";
		return;
	}

	if (voice>=patternQue.length() || voice<0)  {// for any case
		qDebug()<<"patternQue: "<<voice<<" Index out of range";
		return;
	}
	if (patternQue[voice].isEmpty()) {
		qDebug()<<"patternQue["<<voice<<"] is empty";
		emit newMessage("clear,"+QString::number(voice));
		return;
	}

	QString firstMessage = patternQue[voice].takeFirst();
	qDebug()<<"Messages in list per voice: "<<voice<<": "<<patternQue[voice].count();
	freeToPlay[voice]=0;
	emit newMessage(firstMessage);
	if (!names[voice].isEmpty())
		names[voice].removeFirst();
	emit namesChanged(voice, names[voice].join("\n"));

}

void WsServer::setFreeToPlay(int voice)
{
	qDebug()<<"FREE TO PLAY "<<voice;
	freeToPlay[voice]=1;
	sendFirstMessage(voice);
}
