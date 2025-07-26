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

	QList <MYFLT> oldActive, active;
	oldActive <<  0 << 0 <<0; // perhaps there is better way to define an empty list;
	active <<  0 << 0 <<0;

	while (!mStop  && perfThread.GetStatus() == 0 ) {
		usleep(10000);  // ? et ei teeks tööd kogu aeg
		for (int i=0;i<3;i++) {
			active[i] = getChannel("active"+QString::number(i+1));
			if (active[i]!=oldActive[i]) {
				emit channelValue(i,active[i]); // TEST

				if (active[i]==0) { // instruments has ended
					qDebug()<<"Active "<<i<<" "<<active[i];
					emit sendNewPattern(i);
				}
				oldActive[i] = active[i];
			}
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

	if (message.startsWith("clear") || message.startsWith("mode")) {
		return;
	}
	QStringList messageParts = message.split(",");
	QString voice = messageParts[2];
	QString repeatNtimes = messageParts[3];
	QString afterNSquares = messageParts[4];
	QString panOrSpeaker = messageParts[5];
	// prepare steps for compileOrc:
	QString code = "";
	for (int j=0, i=messageParts.indexOf("steps:")+1 ; i<messageParts.length(); i++, j++ ) { // statements to store steps into 2d array giMartix[voice][step]
		code += "giMatrix["+voice+"]["+QString::number(j) + "] = " + messageParts[i] +  "\n";
	}

	QString instrument = QString::number(66 + (voice.toInt()+1)/10.0); // 66.1 - for low voice, 66.2 vor medium, 66.3 high
	code += "\nschedule "+instrument+",0,0," + repeatNtimes + "," + afterNSquares + "," + voice + "," + panOrSpeaker;
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

void CsEngine::handleChannelChange(QString channel, double value)
{
	setChannel(channel, (MYFLT) value);
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
