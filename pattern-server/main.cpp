#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "csengine.h"
#include "wsserver.h"
#include <QDebug>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);


	WsServer *wsServer;
	wsServer = new WsServer(10010);
	CsEngine cs("patterngame.csd");

    QQmlApplicationEngine engine;
	//bind object before load
	engine.rootContext()->setContextProperty("wsServer", wsServer); // forward c++ object that can be reached form qml by object name "csound"

	engine.rootContext()->setContextProperty("cs", &cs);  // to test
	engine.load(QUrl(QStringLiteral("qrc:/main.qml")));


	//QObject *mainQml = engine.rootObjects().first(); // to access qml-s properties

	//mainQml->setProperty("clientsCount",0);



	cs.start();
	qDebug()<<"Csound started";

	QObject::connect(wsServer,SIGNAL(newMessage(QString)),&cs,SLOT(handleMessage(QString)) );
	QObject::connect(&cs, SIGNAL(sendNewPattern(int)), wsServer, SLOT(setFreeToPlay(int)));
	QObject::connect(wsServer, SIGNAL(newPropertyValue(QString,double)), &cs, SLOT(handleChannelChange(QString,double)));
	QObject::connect(wsServer, SIGNAL(newCodeToComplie(QString)) , &cs, SLOT(compileOrc(QString)));
	//TODO: how to signal UI that an pattern has finished playing? when activeX has turned 0 ?
	//WHAT if there is no message in the que: somewhere keep a flag up - send now ? in wsServer freeToPlay[voice]

    return app.exec();
}
