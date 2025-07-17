//Tüm seri port işlemleri bu sınıfta toplanmış
//Timer'lar ve paket işlemleri ayrılmış
//Sinyal-slot yapısı ile MainWindow'a veri gönderir

#include "serialcommunication.h"

SerialCommunication::SerialCommunication(QObject *parent)
    : QObject(parent),
    serial(new QSerialPort(this)),
    connectionSent(false),
    currentPacketIndex(0),
    errorLogged(false),
    currentAveraging(4),  // ✅ DÜZELTME: Default değer ekle
    currentMode(0),       // ✅ DÜZELTME: Default değer ekle
    lastValidSpo2(0),
    lastValidPulse(0),
    lastValidSpo2Str("0"),
    lastValidPulseStr("0")
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

    averagingTimer = new QTimer(this);
    averagingTimer->setSingleShot(false);
    averagingTimer->setInterval(1000); // Her saniye kontrol et

    connect(averagingTimer, &QTimer::timeout, this, &SerialCommunication::processAveraging);
    averagingTimer->start();
    averagingTimer = new QTimer(this);
    averagingTimer->setSingleShot(false);
    averagingTimer->setInterval(1000); // Her saniye kontrol et

    connectionTimer->setSingleShot(true);
    dataRequestTimer->setSingleShot(false);
    sequentialTimer->setSingleShot(true);

    connect(averagingTimer, &QTimer::timeout, this, &SerialCommunication::processAveraging);
    averagingTimer->start();
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

// serialcommunication.cpp içindeki parsePacketByCode fonksiyonunu değiştirin:

void SerialCommunication::parsePacketByCode(uint8_t code, const QByteArray &payload)
{
    // Bu kodlar için debug mesajını kaldır: 0x02, 0x15, 0x0B, 0x01, 0x06, 0x05, 0x07, 0x03
    if (code != 0x02 && code != 0x15 && code != 0x0B && code != 0x01 && code != 0x06 && code != 0x05 && code != 0x07 && code != 0x03) {
        QString hexDump;
        for (uint8_t byte : payload) {
            hexDump += QString("%1 ").arg(byte, 2, 16, QLatin1Char('0')).toUpper();
        }
        qDebug().noquote() << QString(" Code: 0x%1 Payload: %2")
                                  .arg(code, 2, 16, QLatin1Char('0')).toUpper()
                                  .arg(hexDump.trimmed());
    }

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
            uint8_t waveformRaw = static_cast<uint8_t>(payload[1]);
            uint8_t spo2 = static_cast<uint8_t>(payload[3]);
            uint16_t pulse = (static_cast<uint8_t>(payload[4]) << 8) | static_cast<uint8_t>(payload[5]);

            // ✅ DÜZELTME: QML'den gelen currentMode değerini kullan
            uint8_t mode = currentMode;  // payload'dan değil, QML'den gelen değeri kullan
            QString modeStr = (mode == 0) ? "Adult" : (mode == 1) ? "Newborn" : (mode == 2) ? "Pediatric" : "Unknown";

            // ✅ DÜZELTME: QML'den gelen m_currentFrequency değerini kullan
            uint8_t frequency = m_currentFrequency;  // payload'dan değil, QML'den gelen değeri kullan
            QString frequencyStr = QString("%1Hz").arg(frequency);

            // ✅ DÜZELTME: QML'den gelen currentAveraging değerini kullan
            QString averagingStr = QString("%1s").arg(currentAveraging);

            // Geçerli veri kontrolü ve buffer'a ekleme
            if (isValidSpo2(spo2, mode) && isValidPulse(pulse, mode)) {
                addToBuffer(spo2, pulse);
                lastValidSpo2 = spo2;
                lastValidPulse = pulse;
                lastValidSpo2Str = QString::number(spo2);
                lastValidPulseStr = QString::number(pulse);
            }

            // ✅ GÜNCELLEME: Debug mesajında QML'den gelen değerleri kullan
            qDebug().noquote() << QString("SPO2 (0x15) ➔ SpO2: %1 %% | Pulse: %2 bpm | Waveform: %3 | Mode: %4 (%5) | Freq: %6 | Avg: %7")
                                      .arg(isValidSpo2(spo2, mode) ? QString::number(spo2) : "Geçersiz")
                                      .arg(isValidPulse(pulse, mode) ? QString::number(pulse) : "Geçersiz")
                                      .arg(waveformRaw)
                                      .arg(modeStr)
                                      .arg(mode)
                                      .arg(frequencyStr)
                                      .arg(averagingStr);

            m_waveformSample = waveformRaw;
            emit waveformSampleReceived();
            emit waveformDataReceived(waveformRaw);
            emit frequencyReceived(frequency);
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
    if (averagingTimer && averagingTimer->isActive()) {
        averagingTimer->stop();
    }

    // Seri portu kapat
    if (serial && serial->isOpen()) {
        serial->close();
    }


    // Bayrakları sıfırla
    connectionSent = false;

    qDebug() << "Tüm veri akışı durduruldu - timer'lar ve seri port kapatıldı";

    emit connectionStatusChanged(false);

    spo2Buffer.clear();
    pulseBuffer.clear();
}
void SerialCommunication::sendSpo2Settings(int frequency, int mode, int averaging) {
    qDebug() << "=== sendSpo2Settings BAŞLADI ===";
    qDebug() << "Parametreler - Freq:" << frequency << "Mode:" << mode << "Avg:" << averaging;
    qDebug() << "Seri port durumu:" << (serial->isOpen() ? "AÇIK" : "KAPALI");

    // Frekans değerini güncelle
    m_currentFrequency = frequency;
    currentMode = mode;
    currentAveraging = averaging;

    // Averaging timer'ının interval'ini güncelle
    if (averagingTimer) {
        averagingTimer->stop();
        int timerInterval = 1000; // Her saniye kontrol et
        averagingTimer->setInterval(timerInterval);
        averagingTimer->start();
    }

    if (!serial->isOpen()) {
        qDebug() << "SPO2 ayarları gönderilemez - Port kapalı";
        return;
    }

    // Buffer'ları temizle ve yeniden başlat
    spo2Buffer.clear();
    pulseBuffer.clear();
    lastValidSpo2 = 0;
    lastValidPulse = 0;
    lastValidSpo2Str = "0";
    lastValidPulseStr = "0";

    // Ayar byte'ını hesapla
    uint8_t settingByte = calculateSpo2SettingByte(frequency, mode, averaging);
    qDebug() << "Hesaplanan settingByte:" << QString("0x%1").arg(settingByte, 2, 16, QLatin1Char('0')).toUpper();

    // Paketi oluştur ve gönder
    QByteArray data;
    data.append(settingByte);
    QByteArray packet = createSMMPacket(0x06, data);

    serial->write(packet);
    serial->flush();
    serial->waitForBytesWritten(100);

    qDebug() << QString("SPO2 ayarları GÖNDERİLDİ (0x06 ile) ➜ Freq: %1, Mode: %2, Avg: %3, Byte: 0x%4")
                    .arg(frequency).arg(mode).arg(averaging)
                    .arg(settingByte, 2, 16, QLatin1Char('0')).toUpper();
    qDebug() << "Gönderilen paket:" << packet.toHex(' ').toUpper();
}


uint8_t SerialCommunication::calculateSpo2SettingByte(int frequency, int mode, int averaging)
{
    uint8_t settingByte = 0;

    // Bit 1,0: Frequency ayarı
    switch (frequency) {
    case 50:
        settingByte |= 0x02;  // 10 binary
        break;
    case 60:
        settingByte |= 0x03;  // 11 binary
        break;
    default:
        settingByte |= 0x02;  // Default 50Hz
        break;
    }

    // Bits 4,3,2: Mode ayarı
    switch (mode) {
    case 0:  // Adult
        settingByte |= (0x04 << 2);  // 100 binary shifted left 2
        break;
    case 1:  // Newborn
        settingByte |= (0x05 << 2);  // 101 binary shifted left 2
        break;
    case 2:  // Pediatric
        settingByte |= (0x06 << 2);  // 110 binary shifted left 2
        break;
    default:
        settingByte |= (0x04 << 2);  // Default Adult
        break;
    }

    // Bits 7,6,5: Averaging ayarı
    switch (averaging) {
    case 4:
        settingByte |= (0x04 << 5);  // 100 binary shifted left 5
        break;
    case 8:
        settingByte |= (0x05 << 5);  // 101 binary shifted left 5
        break;
    case 16:
        settingByte |= (0x06 << 5);  // 110 binary shifted left 5
        break;
    default:
        settingByte |= (0x04 << 5);  // Default 4 second
        break;
    }

    return settingByte;
}

void SerialCommunication::processAveraging()
{
    if (spo2Buffer.isEmpty() || pulseBuffer.isEmpty()) {
        // Buffer boşsa son geçerli değerleri gönder
        emit spo2PulseData(lastValidSpo2Str, lastValidPulseStr);
        return;
    }

    // ✅ DÜZELTME: currentAveraging değerini kullan
    int maxBufferSize = currentAveraging; // QML'den gelen averaging değeri

    qDebug() << "processAveraging çalışıyor - currentAveraging:" << currentAveraging
             << "Buffer size:" << spo2Buffer.size() << "Max size:" << maxBufferSize;

    // Buffer boyutunu sınırla
    while (spo2Buffer.size() > maxBufferSize) {
        spo2Buffer.removeFirst();
    }
    while (pulseBuffer.size() > maxBufferSize) {
        pulseBuffer.removeFirst();
    }

    // ✅ DÜZELTME: Minimum sample sayısını averaging'e göre ayarla
    int minSamples = qMax(1, currentAveraging / 2); // En az averaging/2 sample olsun

    if (spo2Buffer.size() >= minSamples && pulseBuffer.size() >= minSamples) {
        double avgSpo2 = 0;
        double avgPulse = 0;

        for (uint8_t value : spo2Buffer) {
            avgSpo2 += value;
        }
        avgSpo2 /= spo2Buffer.size();

        for (uint16_t value : pulseBuffer) {
            avgPulse += value;
        }
        avgPulse /= pulseBuffer.size();

        // Ortalama değerleri gönder
        emit spo2PulseData(QString::number(qRound(avgSpo2)), QString::number(qRound(avgPulse)));

        qDebug().noquote() << QString("ORTALAMA (%1s) ➔ SpO2: %2%% | Pulse: %3 bpm | Buffer: %4/%5 samples")
                                  .arg(currentAveraging)
                                  .arg(qRound(avgSpo2))
                                  .arg(qRound(avgPulse))
                                  .arg(spo2Buffer.size())
                                  .arg(maxBufferSize);
    } else {
        // Yeterli veri yoksa son geçerli değerleri gönder
        emit spo2PulseData(lastValidSpo2Str, lastValidPulseStr);

        qDebug() << "Yeterli sample yok - minSamples:" << minSamples
                 << "mevcut:" << spo2Buffer.size() << "- Son geçerli değerler gönderildi";
    }
}

bool SerialCommunication::isValidSpo2(uint8_t spo2, uint8_t mode)
{
    switch (mode) {
    case 0: // Adult
        return !(spo2 == 0x7F || spo2 > 100 || spo2 < 70);
    case 1: // Newborn
        return !(spo2 == 0x7F || spo2 > 100 || spo2 < 85);
    case 2: // Pediatric
        return !(spo2 == 0x7F || spo2 > 100 || spo2 < 75);
    default:
        return !(spo2 == 0x7F || spo2 > 100 || spo2 < 70);
    }
}

bool SerialCommunication::isValidPulse(uint16_t pulse, uint8_t mode)
{
    switch (mode) {
    case 0: // Adult
        return !(pulse > 240 || pulse < 30 || pulse == 0 || pulse == 0xFFFF);
    case 1: // Newborn
        return !(pulse > 180 || pulse < 80 || pulse == 0 || pulse == 0xFFFF);
    case 2: // Pediatric
        return !(pulse > 200 || pulse < 60 || pulse == 0 || pulse == 0xFFFF);
    default:
        return !(pulse > 240 || pulse < 30 || pulse == 0 || pulse == 0xFFFF);
    }
}

void SerialCommunication::addToBuffer(uint8_t spo2, uint16_t pulse)
{
    spo2Buffer.append(spo2);
    pulseBuffer.append(pulse);

    // Buffer boyutunu kontrol et (maksimum 60 saniye veri)
    if (spo2Buffer.size() > 60) {
        spo2Buffer.removeFirst();
    }
    if (pulseBuffer.size() > 60) {
        pulseBuffer.removeFirst();
    }
}
