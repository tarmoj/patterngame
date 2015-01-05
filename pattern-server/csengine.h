#ifndef CSENGINE_H
#define CSENGINE_H

#include <QThread>
#include <csound/csound.hpp>


class CsEngine : public QThread
{
    Q_OBJECT
private:
    bool mStop;
    Csound cs;

public:
    explicit CsEngine();
    void run();
    int open(QString csd);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setChannel(const QString &channel, MYFLT value);
    Q_INVOKABLE void csEvent(const QString &event_string);
    //Q_INVOKABLE double getChannel(const char *channel);

};

#endif // CSENGINE_H
