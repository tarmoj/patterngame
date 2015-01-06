TEMPLATE = app

QT += qml quick widgets websockets

SOURCES += main.cpp \
    wsserver.cpp \
    csengine.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    wsserver.h \
    csengine.h

LIBS += -lcsound64 -lsndfile -ldl -lpthread -lcsnd6
