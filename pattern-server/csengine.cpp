#include "csengine.h"
#include <QDebug>
#include <QTemporaryFile>


// NB! use DEFINES += USE_DOUBLE


CsEngine::CsEngine()
{
    mStop=false;
}

void CsEngine::run() {
	//perfthread
}

int CsEngine::open(QString csd)
{
//TODO: use perfThread
	if (!cs.Compile(csd.toLocal8Bit().data()) ){
        cs.Start();
        cs.Perform();
        return 0;
    } else {
        qDebug()<<"Could not open csound file: "<<csd;
        return -1;
    }
}

void CsEngine::stop()
{
    cs.Stop();
}


void CsEngine::setChannel(const QString &channel, MYFLT value)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
    cs.SetChannel(channel.toLocal8Bit(), value);
}

void CsEngine::csEvent(const QString &event_string)
{
    cs.InputMessage(event_string.toLocal8Bit());
}
