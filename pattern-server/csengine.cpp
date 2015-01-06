#include "csengine.h"
#include <QDebug>


CsEngine::CsEngine(char *csd)
{
    mStop=false;
    m_csd = csd;
    errorValue=0;
}


CsEngine::~CsEngine()
{
	stop();
	//free cs;

}



//Csound *CsEngine::getCsound() {return &cs;}

void CsEngine::run()
{

    //if ( open(m_csd)) {
    if ( cs.Compile(m_csd)) {
		qDebug()<<"Could not open csound file "<<m_csd;
        return;
    }
    CsoundPerformanceThread perfThread(&cs);
    perfThread.Play();

    // kas siin üldse performance threadi vaja? vt. soundcarpet v CsdPlayerQt

    MYFLT noiseCount = 0;
    while (!mStop  && perfThread.GetStatus() == 0 ) {
        usleep(10000);  // ? et ei teeks tööd kogu aeg
        MYFLT counter = getChannel("counter");
        if (noiseCount!=counter) {
            emit newCounterValue(int(counter));
            noiseCount = counter;
        }
    }
    qDebug()<<"Stopping thread";
    perfThread.Stop();
    perfThread.Join();
    mStop=false; // luba uuesti käivitamine
}

void CsEngine::stop()
{
    // cs.Reset();  // ?kills Csound at all
    mStop = true;

}

QString CsEngine::getErrorString()  // probably not necessry
{
    return errorString;
}

int CsEngine::getErrorValue()
{
    return errorValue;
}


MYFLT CsEngine::getChannel(QString channel)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
	return cs.GetChannel(channel.toLocal8Bit());
}

void CsEngine::handleMessage(QString message)
{
	// message format: 'pattern' name voice repeatNtimes afterNsquares steps: pitch_index11 pitch_index2
	qDebug()<<"Message in csound: "<<message;
	//vaja midagi nagu: 1) compileOrc( giMatrix[voice][0] = step1 etc fillarray )  2) ;schedule "playPattern",0,0,nTimes, afterNsquares
	QStringList messageParts = message.split(",");
	QString voice = messageParts[2];
	QString repeatNtimes = messageParts[3];
	QString afterNSquares = messageParts[4];
	//QString steps = message.right(message.length()-message.indexOf("steps:")); // correct?
	//steps.remove("steps:,");
	QString code = "";
	for (int j=0, i=messageParts.indexOf("steps:")+1 ; i<messageParts.length(); i++, j++ ) { // statements to store steps into 2d array giMartix[voice][step]
		code += "giMatrix["+voice+"]["+QString::number(j) + "] = " + messageParts[i] +  "\n";
	}

	code += "\nschedule \"playPattern\",0,0," + repeatNtimes + "," + afterNSquares + "," + voice;
	qDebug()<<"Message to compile: "<<code;
	compileOrc(code);

}

void CsEngine::compileOrc(QString code)
{

	//qDebug()<<"Code to compile: "<<code;
	QString message;
	errorValue =  cs.CompileOrc(code.toLocal8Bit());
	if ( errorValue )
		message = "Could not compile the code";
	else
		message = "OK";

}

void CsEngine::restart()
{
    stop(); // sets mStop true
    while (mStop) // run sets mStop false again when perftrhead has joined
        usleep(100000);
    start();
}

void CsEngine::setChannel(QString channel, MYFLT value)
{
    //qDebug()<<"setChannel "<<channel<<" value: "<<value;
    cs.SetChannel(channel.toLocal8Bit(), value);
}

void CsEngine::csEvent(QString event_string)
{
    cs.InputMessage(event_string.toLocal8Bit());
}
