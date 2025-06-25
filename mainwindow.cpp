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

    // Keep-alive zamanlayıcısını başlat
    keepAliveTimer.start(100); // 5 saniyede bir keep-alive gönder
}

MainWindow::~MainWindow()
{
    closeSerialPort(); // Portu kapat
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

    // Host'tan SMM'ye veri gönderimi
    QByteArray commands;
    commands.append(0xBF);
    commands.append(0x5F);
    commands.append(0xFF);

    // Verileri gönder
    serial->write(commands);
    /* if (!serial->waitForBytesWritten(100)) {
        qDebug() << "Veri yazma hatası:" << serial->errorString();
    } else {
        qDebug() << "Veri başarıyla gönderildi:" << commands.toHex();
    }*/
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
    //buffer.append();
    qDebug()<<serial->readAll().toHex();
    return;

    while (buffer.size() >= 5) {
        int start = buffer.indexOf(QByteArray::fromHex("AA55"));
        if (start == -1) {
            buffer.clear();
            return; // Başlangıç baytı bulunamazsa buffer'ı temizle
        }

        if (start > 0)
            buffer.remove(0, start); // Başlangıç baytından önceki verileri temizle

        if (buffer.size() < 5)
            return; // Paket tamamlanmamışsa çık

        quint8 length = static_cast<quint8>(buffer[2]);
        if (buffer.size() < length + 4)
            return; // Paket tamamlanmamışsa çık

        QByteArray packet = buffer.left(length + 4);
        buffer.remove(0, length + 4); // Kullanılan veriyi buffer'dan çıkar

        quint8 receivedChecksum = static_cast<quint8>(packet[length + 3]);
        quint8 calculatedChecksum = calculateChecksum(packet.mid(2, length + 1));
        if (receivedChecksum != calculatedChecksum) {
            qDebug() << "Checksum hatası!";
            continue; // Hatalı paketi atla
        }

        quint8 code = static_cast<quint8>(packet[3]);
        QByteArray payload = packet.mid(4, length - 1);

        if (code == 8 || code == 9) {
            if (payload.size() < 3) continue;

            int spo2 = static_cast<quint8>(payload[0]);
            int pulse = static_cast<quint8>(payload[1]);
            int strength = static_cast<quint8>(payload[2]);

            bool weakSignal = (strength < 30);
            qDebug() << "SpO2:" << spo2 << "% | Pulse:" << pulse
                     << "| Strength:" << strength
                     << (weakSignal ? "(Sinyal zayıf)" : "");
        }
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
    commands.append(0xBF);
    commands.append(0x5F);
    commands.append(0xFF);
    serial->write(commands);

    // if (!protocolSwitched || !serial->isOpen())
    return;

    QByteArray keepAlive;
    keepAlive.append('\xAA');
    keepAlive.append('\x55');
    keepAlive.append('\x01');
    keepAlive.append('\x0D'); // Keep-alive komutu
    quint8 checksum = calculateChecksum(keepAlive.mid(2));
    keepAlive.append(static_cast<char>(checksum));

    serial->write(keepAlive);
    qDebug() << "Keep-alive paketi gönderildi.";
}
