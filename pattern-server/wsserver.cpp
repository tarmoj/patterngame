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
}

void WsServer::processTextMessage(QString message)
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (!pClient) {
        return;
    }
	//qDebug()<<message;

	QStringList messageParts = message.split(",");
	// message format: // message format: 'pattern' name voice repeatNtimes afterNsquares steps: pitch_index11 pitch_index2
	if (message.startsWith("pattern")) {
		//emit newEvent(message);
		int voice = messageParts[2].toInt();
		//TODO: add name to namesList
		patternQue[voice].append(message);
		names[voice].append(messageParts[1]); // store names to list
		emit namesChanged(voice, names[voice].join("\n"));
		qDebug()<<"New pattern from "<< messageParts[1] << message;
		qDebug()<<"Messages in list per voice: "<<voice<<": "<<patternQue[voice].count();



	}

	if (message.startsWith("new"))  // for testing only. send message from js console of browser wit doSend("new 1") or similar
		sendFirstMessage(messageParts[1].toInt());


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
	if (voice>=patternQue.length() || voice<0)  {// for any case
		qDebug()<<"patternQue: "<<voice<<" Index out of range";
		return;
	}
	if (patternQue[voice].isEmpty()) {
		qDebug()<<"patternQue["<<voice<<"] is empty";
		return;
	}
	QString firstMessage = patternQue[voice].takeFirst();
	qDebug()<<"Messages in list per voice: "<<voice<<": "<<patternQue[voice].count();
	emit newEvent(firstMessage);
	names[voice].removeFirst();
	emit namesChanged(voice, names[voice].join("\n"));
}
