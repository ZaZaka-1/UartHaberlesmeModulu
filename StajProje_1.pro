QT       += core gui serialport

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = example
TEMPLATE = app

SOURCES += main.cpp \
           mainwindow.cpp

HEADERS += mainwindow.h

# Eğer Qt versiyonuna göre fark varsa, aşağıdaki gibi ekleyebilirsin
# CONFIG += c++11
