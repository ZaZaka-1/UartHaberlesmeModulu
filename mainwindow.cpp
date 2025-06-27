#include "mainwindow.h"
#include <QDebug>

MainWindow::MainWindow(QObject *parent)
    : QObject(parent),
    serial(new QSerialPort(this)),
    m_spo2(""),
    m_pulse(""),
    connectionSent(false),
    currentPacketIndex(0)
{
    serial->setPortName("COM4");
    serial->setBaudRate(375000);
    serial->setDataBits(QSerialPort::Data8);
    serial->setParity(QSerialPort::OddParity);
    serial->setStopBits(QSerialPort::OneStop);
    serial->setFlowControl(QSerialPort::NoFlowControl);

    connect(serial, &QSerialPort::readyRead, this, &MainWindow::readData);
    connect(serial, &QSerialPort::errorOccurred, this, &MainWindow::handleError);

    openSerialPort();

    connectionTimer = new QTimer(this);
    dataRequestTimer = new QTimer(this);
    sequentialTimer = new QTimer(this);

    connectionTimer->setSingleShot(true);
    dataRequestTimer->setSingleShot(false);
    sequentialTimer->setSingleShot(true);

    connect(connectionTimer, &QTimer::timeout, this, &MainWindow::sendConnectionSequence);
    connect(dataRequestTimer, &QTimer::timeout, this, &MainWindow::startSequentialRequests);
    connect(sequentialTimer, &QTimer::timeout, this, &MainWindow::sendNextPacket);

    packetCommands = createIndividualCommands();

    connectionTimer->start(1000);
}

void MainWindow::openSerialPort()
{
    if (!serial->open(QIODevice::ReadWrite)) {
        qWarning() << "Seri port açılamadı:" << serial->errorString();
    } else {
        qDebug() << "Seri port açıldı.";
    }
}

void MainWindow::sendConnectionSequence()
{
    if (connectionSent || !serial->isOpen())
        return;

    QByteArray handshake = QByteArray::fromHex("BF5FFF");
    serial->write(handshake);
    serial->flush();
    serial->waitForBytesWritten(1000);

    connectionSent = true;
    connectionTimer->stop();

    QTimer::singleShot(2000, this, [this]() {
        dataRequestTimer->start(5000);
    });
}

void MainWindow::startSequentialRequests()
{
    if (!serial->isOpen())
        return;

    currentPacketIndex = 0;
    sendNextPacket();
}

void MainWindow::sendNextPacket()
{
    if (!serial->isOpen() || currentPacketIndex >= packetCommands.size())
        return;

    QByteArray packet = packetCommands[currentPacketIndex];
    serial->write(packet);
    serial->flush();
    serial->waitForBytesWritten(100);

    currentPacketIndex++;
    if (currentPacketIndex < packetCommands.size()) {
        sequentialTimer->start(1000);
    }
}

QList<QByteArray> MainWindow::createIndividualCommands()
{
    QList<QByteArray> commands;
    commands.append(createSMMPacket(0x01, QByteArray::fromHex("101102000000000803010F")));
    commands.append(createSMMPacket(0x02, QByteArray()));
    commands.append(createSMMPacket(0x04, QByteArray::fromHex("0100")));
    return commands;
}

QByteArray MainWindow::createSMMPacket(uint8_t code, const QByteArray &data)
{
    QByteArray packet;
    packet.append(0xAA);
    packet.append(0x55);
    uint8_t length = data.size() + 1;
    packet.append(length);
    packet.append(code);
    packet.append(data);

    uint8_t checksum = length + code;
    for (char byte : data) {
        checksum += static_cast<uint8_t>(byte);
    }
    packet.append(checksum);
    return packet;
}

void MainWindow::readData()
{
    QByteArray incoming = serial->readAll();
    if (incoming.isEmpty()) return;

    buffer.append(incoming);
    parseBufferedData();
}

MainWindow::~MainWindow()
{
    // Eğer özel bir temizlik işlemi yapmayacaksanız, boş bırakabilirsiniz.
}

void MainWindow::parseBufferedData()
{
    while (buffer.size() >= 4) {
        int headerIndex = buffer.indexOf(QByteArray::fromHex("AA55"));
        if (headerIndex == -1) {
            buffer.clear();
            return;
        }

        if (headerIndex > 0)
            buffer.remove(0, headerIndex);

        if (buffer.size() < 4)
            return;

        uint8_t length = static_cast<uint8_t>(buffer[2]);
        int totalSize = 3 + length + 1;

        if (buffer.size() < totalSize)
            return;

        QByteArray packet = buffer.left(totalSize);
        uint8_t code = static_cast<uint8_t>(packet[3]);
        QByteArray payload = packet.mid(4, length - 1);

        uint8_t receivedChecksum = static_cast<uint8_t>(packet[totalSize - 1]);
        uint8_t calculatedChecksum = length + code;
        for (char byte : payload) {
            calculatedChecksum += static_cast<uint8_t>(byte);
        }

        if (receivedChecksum == calculatedChecksum) {
            parsePacketByCode(code, payload);
        } else {
            qWarning() << "Checksum hatası:" << packet.toHex(' ').toUpper();
        }

        buffer.remove(0, totalSize);
    }
}

void MainWindow::parsePacketByCode(uint8_t code, const QByteArray &payload)
{
    QString hexDump;
    for (uint8_t byte : payload) {
        hexDump += QString("%1 ").arg(byte, 2, 16, QLatin1Char('0')).toUpper();
    }
    qDebug().noquote() << QString(" Code: 0x%1 Payload: %2").arg(code, 2, 16, QLatin1Char('0')).toUpper().arg(hexDump.trimmed());

    switch (code) {
    case 0x04: {  // ERT Parameters (isteğe bağlı log)
        if (payload.size() >= 6) {
            uint8_t rr = static_cast<uint8_t>(payload[0]);
            uint8_t hr = static_cast<uint8_t>(payload[1]);
            uint16_t rawT1 = (static_cast<uint8_t>(payload[2]) << 8) | static_cast<uint8_t>(payload[3]);
            uint16_t rawT2 = (static_cast<uint8_t>(payload[4]) << 8) | static_cast<uint8_t>(payload[5]);

            float t1 = rawT1 < 5000 ? rawT1 / 10.0 : 0.0;
            float t2 = rawT2 < 5000 ? rawT2 / 10.0 : 0.0;

            qDebug().noquote() << QString(" ERT (Code 0x04) ➤ HR: %1 bpm | RR: %2 rpm | T1: %3 °C | T2: %4 °C")
                                      .arg(hr)
                                      .arg(rr)
                                      .arg(t1, 0, 'f', 1)
                                      .arg(t2, 0, 'f', 1);
        }
        break;
    }
    case 0x15: {  // Biolight SPO2 verileri
        if (payload.size() >= 6) {
            uint8_t spo2 = static_cast<uint8_t>(payload[3]);
            uint16_t pulse = (static_cast<uint8_t>(payload[4]) << 8) | static_cast<uint8_t>(payload[5]);

            QString spo2Str = (spo2 == 0x7F || spo2 > 100) ? "Geçersiz" : QString::number(spo2);
            QString pulseStr = (pulse > 240 || pulse == 0 || pulse == 0xFFFF) ? "Geçersiz" : QString::number(pulse);

            if (spo2Str != m_spo2) {
                m_spo2 = spo2Str;
                emit spo2Changed();
            }
            if (pulseStr != m_pulse) {
                m_pulse = pulseStr;
                emit pulseChanged();
            }

            qDebug().noquote() << QString(" SPO2 (0x15) ➤ SpO2: %1 %% | Pulse: %2 bpm")
                                      .arg(spo2Str)
                                      .arg(pulseStr);
        }
        break;
    }
    default:
        break;
    }
}

void MainWindow::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

    qWarning() << "️ Serial Port Hatası:" << error << "-" << serial->errorString();

    if (error == QSerialPort::ResourceError || error == QSerialPort::DeviceNotFoundError) {
        connectionSent = false;
        connectionTimer->start(2000);
    }
}
