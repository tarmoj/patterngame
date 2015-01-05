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

    QQmlApplicationEngine engine;
	//bind object before load
	engine.rootContext()->setContextProperty("wsServer", wsServer); // forward c++ object that can be reached form qml by object name "csound"
	engine.load(QUrl(QStringLiteral("qrc:/main.qml")));


	//QObject *mainQml = engine.rootObjects().first(); // to access qml-s properties

	//mainQml->setProperty("clientsCount",0);


//	CsEngine cs;
//	cs.open("patterngame.csd");
//	qDebug()<<"Csound started";
//	sleep(1);
//	cs.csEvent("i  \"randomPattern\"  0 0 0 1 ");

    return app.exec();
}
