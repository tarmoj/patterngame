#ifndef WSSERVER_H
#define WSSERVER_H

#include <QObject>
#include <QList>
#include <QByteArray>
#include <QStringList>

QT_FORWARD_DECLARE_CLASS(QWebSocketServer)
QT_FORWARD_DECLARE_CLASS(QWebSocket)


class WsServer : public QObject
{
    Q_OBJECT
public:
    explicit WsServer(quint16 port, QObject *parent = NULL);
    ~WsServer();

    void sendMessage(QWebSocket *socket, QString message);
	//TODO: rename Message->Pattern
	void sendFirstMessage(int voice); // sends signals and necessary info about first message in the que to UI and Csound


public Q_SLOTS:
	void setFreeToPlay(int voice);

Q_SIGNALS:
    void closed();
    void newConnection(int connectionsCount);
	void newMessage(QString messageString);
	void namesChanged(int voice, QString names);
	void newPropertyValue(QString property, double value);
	void newCodeToComplie(QString code);


private Q_SLOTS:
    void onNewConnection();
    void processTextMessage(QString message);
    //void processBinaryMessage(QByteArray message);
    void socketDisconnected();


private:
	int mode;
    QWebSocketServer *m_pWebSocketServer;
    QList<QWebSocket *> m_clients;
	QList <QStringList> patternQue; // basically verctor of 3 stringlists, one for every voice
	QList <QStringList> names;
	QList <int> freeToPlay;  // flags for voices
	QStringList modeNames;
};



#endif // WSSERVER_H
