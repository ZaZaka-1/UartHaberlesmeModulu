#include "mainwindow.h"
#include <QDebug>
#include <QSerialPortInfo>
#include <QThread>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent),
    serial(new QSerialPort(this)),
    protocolSwitched(false)
{
    // Seri port ayarları
    serial->setPortName("COM4");  // Cihaza göre değiştir
    serial->setBaudRate(375000);
    serial->setDataBits(QSerialPort::Data8);
    serial->setParity(QSerialPort::OddParity);
    serial->setStopBits(QSerialPort::OneStop);
    serial->setFlowControl(QSerialPort::NoFlowControl);

    connect(serial, &QSerialPort::readyRead, this, &MainWindow::readSerialData);
    connect(serial, &QSerialPort::errorOccurred, this, &MainWindow::handleError);

    openSerialPort();

    connect(&keepAliveTimer, &QTimer::timeout, this, &MainWindow::sendKeepAlive);

    keepAliveTimer.start(100);
}

MainWindow::~MainWindow()
{
    closeSerialPort();
}

void MainWindow::openSerialPort()
{
    qDebug() << "Available ports:";
    const auto ports = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : ports) {
        qDebug() << "Port:" << info.portName()
        << "| Description:" << info.description()
        << "| Manufacturer:" << info.manufacturer();
    }

    if (!serial->open(QIODevice::ReadWrite)) {
        qDebug() << "Seri port açılamadı:" << serial->errorString();
        return;
    } else {
        qDebug() << "Seri port başarıyla açıldı.";
    }

    QByteArray commands;
    commands.append(0xBF);
    commands.append(0x5F);
    commands.append(0xFF);

    serial->write(commands);
}

void MainWindow::closeSerialPort()
{
    if (serial->isOpen()) {
        serial->close();
        qDebug() << "Seri port kapatıldı.";
    }
}

void MainWindow::readSerialData()
{
    QByteArray data = serial->readAll();
    buffer.append(data);

    // Burada buffer’da toplanan veriyi işle
    processBuffer();
}

void MainWindow::processBuffer()
{
    // Örnek: Elindeki çok uzun hex string yerine, seri porttan gelen ham veriyi buffer’da tutup ayrıştırıyoruz
    while (buffer.size() >= 5) {
        int start = buffer.indexOf(QByteArray::fromHex("aa55"));
        if (start == -1) {
            buffer.clear();
            return; // Başlangıç bulunmazsa temizle
        }

        if (start > 0)
            buffer.remove(0, start);

        if (buffer.size() < 5)
            return; // Paket tamamlanmamış

        quint8 length = static_cast<quint8>(buffer[2]); // Paket uzunluğunu protokole göre ayarla

        if (buffer.size() < length + 4)
            return; // Paket tamamlanmamış

        QByteArray packet = buffer.left(length + 4);
        buffer.remove(0, length + 4);

        quint8 receivedChecksum = static_cast<quint8>(packet[length + 3]);
        quint8 calculatedChecksum = calculateChecksum(packet.mid(2, length + 1));

        if (receivedChecksum != calculatedChecksum) {
            qDebug() << "Checksum hatası paket:" << packet.toHex();
            continue; // Hatalı paketi atla
        }

        qDebug() << "Geçerli paket:" << packet.toHex();

        // Burada paketi istediğin gibi işleyebilirsin, örn. payload ayrıştırma vs.
    }
}

quint8 MainWindow::calculateChecksum(const QByteArray &data)
{
    quint8 sum = 0;
    for (auto c : data)
        sum += static_cast<quint8>(c);
    return sum;
}

void MainWindow::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

    qDebug() << "Seri port hatası:" << serial->errorString();
    closeSerialPort();
}

void MainWindow::sendKeepAlive()
{
    QByteArray commands;
    commands.append(0x5F);
    commands.append(0xBF);
    commands.append(0xFF);
    serial->write(commands);
}
