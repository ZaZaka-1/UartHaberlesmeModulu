//Tüm seri port işlemleri bu sınıfta toplanmış
//Timer'lar ve paket işlemleri ayrılmış
//Sinyal-slot yapısı ile MainWindow'a veri gönderir

#include "serialcommunication.h"

SerialCommunication::SerialCommunication(QObject *parent)
    : QObject(parent),
    serial(new QSerialPort(this)),
    connectionSent(false),
    currentPacketIndex(0),
    errorLogged(false)
{
    serial->setPortName("COM4");
    serial->setBaudRate(375000);
    serial->setDataBits(QSerialPort::Data8);
    serial->setParity(QSerialPort::OddParity);
    serial->setStopBits(QSerialPort::OneStop);
    serial->setFlowControl(QSerialPort::NoFlowControl);

    connect(serial, &QSerialPort::readyRead, this, &SerialCommunication::readData);
    connect(serial, &QSerialPort::errorOccurred, this, &SerialCommunication::handleError);

    // İlk bağlantı denemesi
    openSerialPort();

    connectionTimer = new QTimer(this);
    dataRequestTimer = new QTimer(this);
    sequentialTimer = new QTimer(this);

    connectionTimer->setSingleShot(true);
    dataRequestTimer->setSingleShot(false);
    sequentialTimer->setSingleShot(true);

    connect(connectionTimer, &QTimer::timeout, this, &SerialCommunication::sendConnectionSequence);
    connect(dataRequestTimer, &QTimer::timeout, this, &SerialCommunication::startSequentialRequests);
    connect(sequentialTimer, &QTimer::timeout, this, &SerialCommunication::sendNextPacket);

    packetCommands = createIndividualCommands();

    // Port açık değilse bile timer'ları başlat
    connectionTimer->start(1000);
}

SerialCommunication::~SerialCommunication()
{
    if (serial->isOpen())
        serial->close();
}

void SerialCommunication::openSerialPort()
{
    if (!serial->open(QIODevice::ReadWrite)) {
        // Sadece ilk başta hata mesajı göster
        static bool firstTry = true;
        if (firstTry) {
            qDebug() << "Seri port açılamadı:" << serial->errorString();
            qDebug() << "Program port olmadan da çalışmaya devam edecek...";
            firstTry = false;
        }
        emit connectionStatusChanged(false);
        return; // Yeniden deneme yapma
    } else {
        qDebug() << "Seri port başarıyla açıldı.";
        emit connectionStatusChanged(true);
    }
}

bool SerialCommunication::isConnected() const
{
    return serial && serial->isOpen();
}

void SerialCommunication::sendConnectionSequence()
{
    if (connectionSent || !serial->isOpen()) {
        qDebug() << "Bağlantı dizisi gönderilemiyor - Port kapalı veya zaten gönderildi";
        return;
    }

    QByteArray handshake = QByteArray::fromHex("BF5FFF");
    if (serial->isOpen()) {
        serial->write(handshake);
        serial->flush();
        serial->waitForBytesWritten(1000);
        qDebug() << "Handshake gönderildi";
    }

    connectionSent = true;
    connectionTimer->stop();

    QTimer::singleShot(2000, this, [this]() {
        if (serial->isOpen()) {
            dataRequestTimer->start(5000);
        }
    });
}

void SerialCommunication::startSequentialRequests()
{
    if (!serial->isOpen()) {
        qDebug() << "Sequential request başlatılamıyor - Port kapalı";
        return;
    }

    currentPacketIndex = 0;
    sendNextPacket();
}

void SerialCommunication::sendNextPacket()
{
    if (!serial->isOpen() || currentPacketIndex >= packetCommands.size()) {
        if (!serial->isOpen()) {
            qDebug() << "Packet gönderilemiyor - Port kapalı";
        }
        return;
    }

    QByteArray packet = packetCommands[currentPacketIndex];
    serial->write(packet);
    serial->flush();
    serial->waitForBytesWritten(100);

    currentPacketIndex++;
    if (currentPacketIndex < packetCommands.size()) {
        sequentialTimer->start(1000);
    }
}

QList<QByteArray> SerialCommunication::createIndividualCommands()
{
    QList<QByteArray> commands;
    commands.append(createSMMPacket(0x01, QByteArray::fromHex("101102000000000803010F")));
    commands.append(createSMMPacket(0x02, QByteArray()));
    commands.append(createSMMPacket(0x04, QByteArray::fromHex("0100")));
    return commands;
}

QByteArray SerialCommunication::createSMMPacket(uint8_t code, const QByteArray &data)
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

void SerialCommunication::readData()
{
    QByteArray incoming = serial->readAll();
    if (incoming.isEmpty()) return;

    buffer.append(incoming);
    parseBufferedData();
}

void SerialCommunication::parseBufferedData()
{
    while (buffer.size() >= 4) {
        int headerIndex = buffer.indexOf(QByteArray::fromHex("AA55"));
        if (headerIndex == -1) {
            if (buffer.size() > 1)
                buffer.remove(0, buffer.size() - 1);
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

void SerialCommunication::parsePacketByCode(uint8_t code, const QByteArray &payload)
{
    QString hexDump;
    for (uint8_t byte : payload) {
        hexDump += QString("%1 ").arg(byte, 2, 16, QLatin1Char('0')).toUpper();
    }
    qDebug().noquote() << QString(" Code: 0x%1 Payload: %2")
                              .arg(code, 2, 16, QLatin1Char('0')).toUpper()
                              .arg(hexDump.trimmed());

    switch (code) {
    case 0x04: {
        if (payload.size() >= 6) {
            uint8_t rr = static_cast<uint8_t>(payload[0]);
            uint8_t hr = static_cast<uint8_t>(payload[1]);
            uint16_t rawT1 = (static_cast<uint8_t>(payload[2]) << 8) | static_cast<uint8_t>(payload[3]);
            uint16_t rawT2 = (static_cast<uint8_t>(payload[4]) << 8) | static_cast<uint8_t>(payload[5]);

            float t1 = rawT1 < 5000 ? rawT1 / 10.0 : 0.0;
            float t2 = rawT2 < 5000 ? rawT2 / 10.0 : 0.0;

            qDebug().noquote() << QString(" ERT ➔ HR: %1 bpm | RR: %2 rpm | T1: %3 °C | T2: %4 °C")
                                      .arg(hr).arg(rr).arg(t1, 0, 'f', 1).arg(t2, 0, 'f', 1);

            emit ertData(hr, rr, t1, t2);
        }
        break;
    }
    case 0x15: {
        if (payload.size() >= 6) {
            // ✅ 1. Waveform ham verisini oku
            uint8_t waveformRaw = static_cast<uint8_t>(payload[1]);

            // ✅ 2. SpO2 ve pulse değerlerini oku
            uint8_t spo2 = static_cast<uint8_t>(payload[3]);
            uint16_t pulse = (static_cast<uint8_t>(payload[4]) << 8) | static_cast<uint8_t>(payload[5]);

            QString spo2Str = (spo2 == 0x7F || spo2 > 100) ? "Geçersiz" : QString::number(spo2);
            QString pulseStr = (pulse > 240 || pulse == 0 || pulse == 0xFFFF) ? "Geçersiz" : QString::number(pulse);

            qDebug().noquote() << QString("SPO2 (0x15) ➔ SpO2: %1 %% | Pulse: %2 bpm | Waveform: %3")
                                      .arg(spo2Str)
                                      .arg(pulseStr)
                                      .arg(waveformRaw);

            // ✅ 4. Yeni: waveform örneğini sakla ve bildir
            m_waveformSample = waveformRaw;
            emit waveformSampleReceived();

            // ✅ 3. Waveform verisini QML'e gönder
            emit waveformDataReceived(waveformRaw);

            // ✅ 4. SpO2 ve pulse verilerini gönder
            emit spo2PulseData(spo2Str, pulseStr);
        }
        break;
    }

    default:
        break;
    }

    // Genel data received sinyali
    emit dataReceived(code, payload);
}

void SerialCommunication::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::NoError)
        return;

    // Sadece ilk hatayı logla, sonrasında spam yapma
    if (!errorLogged) {
        qDebug() << "Serial Port Hatası:" << error << "-" << serial->errorString();
        qDebug() << "Program port olmadan devam edecek...";
        errorLogged = true;
    }

    if (serial->isOpen()) {
        serial->close();
    }

    emit connectionStatusChanged(false);
    connectionSent = false;

    // Timer'ları durdur
    if (connectionTimer && connectionTimer->isActive()) {
        connectionTimer->stop();
    }
    if (dataRequestTimer && dataRequestTimer->isActive()) {
        dataRequestTimer->stop();
    }
    if (sequentialTimer && sequentialTimer->isActive()) {
        sequentialTimer->stop();
    }
}

void SerialCommunication::reconnect()
{
    qDebug() << "Manuel yeniden bağlanma deneniyor...";

    if (serial->isOpen()) {
        serial->close();
    }

    // Hata bayrağını sıfırla
    errorLogged = false;
    connectionSent = false;

    openSerialPort();

    if (serial->isOpen()) {
        // Bağlantı başarılıysa timer'ları yeniden başlat
        connectionTimer->start(1000);
    }
}

void SerialCommunication::stopDataStream()
{
    qDebug() << "Veri akışı durduruldu!";

    // Tüm timer'ları durdur
    if (connectionTimer && connectionTimer->isActive()) {
        connectionTimer->stop();
    }
    if (dataRequestTimer && dataRequestTimer->isActive()) {
        dataRequestTimer->stop();
    }
    if (sequentialTimer && sequentialTimer->isActive()) {
        sequentialTimer->stop();
    }

    // Seri portu kapat
    if (serial && serial->isOpen()) {
        serial->close();
    }

    // Bayrakları sıfırla
    connectionSent = false;

    qDebug() << "Tüm veri akışı durduruldu - timer'lar ve seri port kapatıldı";

    emit connectionStatusChanged(false);
}
