QT       += core gui widgets serialport quick qml quickcontrols2
QT       += sql printsupport
CONFIG   += c++17
CONFIG   += qmltypes
CONFIG   += qtquickcompiler
TEMPLATE = app
TARGET = StajProje_1
QML_IMPORT_NAME = StajProje1
QML_IMPORT_MAJOR_VERSION = 1

SOURCES += \
    main.cpp \
    mainwindow.cpp \
    serialcommunication.cpp

HEADERS += \
    mainwindow.h \
    serialcommunication.h

RESOURCES += \
    Resource.qrc

DISTFILES += \
    main.qml
