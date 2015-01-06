#ifndef CSENGINE_H
#define CSENGINE_H

#include <QThread>
#include <csound/csound.hpp>
#include <csound/csPerfThread.hpp>
#include <QMutex>


class CsEngine : public QThread
{
    Q_OBJECT
private:
    bool mStop;
    Csound cs;
    char *m_csd;
    int errorValue;
    QString errorString;
    int sliderCount;

    //QMutex mutex;

public:
    explicit CsEngine(char *csd);
	 ~CsEngine();
	void run();
    void stop();
    QString getErrorString();
    int getErrorValue();

    void setChannel(QString channel, MYFLT value);



    double getChannel(QString);
    Csound *getCsound();
signals:
	void sendNewPattern(int voice); // sent when a new pattern can be sent for the voice

public slots:
	void handleMessage(QString message); //
	void csEvent(QString event_string);
	void compileOrc(QString code);
	void restart(); // does not work though
};

#endif // CSENGINE_H
