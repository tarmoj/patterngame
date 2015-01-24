TEMPLATE = app

QT += qml quick widgets websockets

SOURCES += main.cpp \
    wsserver.cpp \
    csengine.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# INCLUDEPATH += /usr/local/include/ # or other folder where csound/csound.hpp and csound/csPerfThread.hpp can be found

# Default rules for deployment.
include(deployment.pri)

HEADERS += \
    wsserver.h \
    csengine.h

LIBS += -lcsound64  -lcsnd6  #-L/usr/local/lib # or folder where are libcsound64 and libcsnd6
