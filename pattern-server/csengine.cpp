#include "csengine.h"
#include <QDebug>
#include <QTemporaryFile>


// NB! use DEFINES += USE_DOUBLE


CsEngine::CsEngine()
{
#ifdef FOR_ADNROID
    cs.setOpenSlCallbacks(); // for android audio to work
#endif
    mStop=false;
    cs.SetOption("-odac");
    cs.SetOption("-d");

}

void CsEngine::run() {
    QString orc =R"(
            sr = 44100
            nchnls = 2
            0dbfs = 1
            ksmps = 32

            instr test
                prints "INSTR TEST"
                kval chnget "value"
                ;printk2 kval
                kfreq = 300+400*kval
                asig vco2 linen(0.5,0.05,p3,0.1), kfreq
                asig moogvcf asig, 400+600*(1-kval), 0.3+(1-kval)/2
                outs asig, asig
            endin)";
    if (!cs.CompileOrc(orc.toLocal8Bit())) {
            cs.Start();
            cs.Perform();
    }
}

int CsEngine::open(QString csd)
{

    QTemporaryFile *tempFile = QTemporaryFile::createNativeFile(csd); //TODO: checi if not 0
//    if (tempFile.open()) {
//        tempFile.write(file.readAll());
//    }

    qDebug()<<tempFile->readAll();

    if (!cs.Compile( tempFile->fileName().toLocal8Bit().data()) ){
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
