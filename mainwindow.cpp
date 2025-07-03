// mainwindow.cpp
#include "mainwindow.h"
#include <QDir>
#include <QDebug>

MainWindow::MainWindow(QObject *parent)
    : QObject(parent),
    serial(new QSerialPort(this)),
    m_spo2(""),
    m_pulse(""),
    connectionSent(false),
    currentPacketIndex(0)
{
    initDatabase();

    serial->setPortName("COM4");
    serial->setBaudRate(375000);
    serial->setDataBits(QSerialPort::Data8);
    serial->setParity(QSerialPort::OddParity);
    serial->setStopBits(QSerialPort::OneStop);
    serial->setFlowControl(QSerialPort::NoFlowControl);

    connect(serial, &QSerialPort::readyRead, this, &MainWindow::readData);
    connect(serial, &QSerialPort::errorOccurred, this, &MainWindow::handleError);

    // İlk bağlantı denemesi
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

    // Port açık değilse bile timer'ları başlat
    connectionTimer->start(1000);
}

MainWindow::~MainWindow()
{
    if (serial->isOpen())
        serial->close();
}


void MainWindow::openSerialPort()
{
    if (!serial->open(QIODevice::ReadWrite)) {
        // Sadece ilk başta hata mesajı göster
        static bool firstTry = true;
        if (firstTry) {
            qDebug() << "Seri port açılamadı:" << serial->errorString();
            qDebug() << "Program port olmadan da çalışmaya devam edecek...";
            firstTry = false;
        }
        emit serialConnectedChanged();
        return; // Yeniden deneme yapma
    } else {
        qDebug() << "Seri port başarıyla açıldı.";
        emit serialConnectedChanged();
    }
}

void MainWindow::tryReconnect()
{
    qDebug() << "Yeniden bağlanma denemesi yapılıyor...";
    openSerialPort();
}

bool MainWindow::isSerialConnected() const {
    return serial && serial->isOpen();
}

void MainWindow::sendConnectionSequence()
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

void MainWindow::startSequentialRequests()
{
    if (!serial->isOpen()) {
        qDebug() << "Sequential request başlatılamıyor - Port kapalı";
        return;
    }

    currentPacketIndex = 0;
    sendNextPacket();
}

void MainWindow::sendNextPacket()
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

void MainWindow::parseBufferedData()
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

void MainWindow::parsePacketByCode(uint8_t code, const QByteArray &payload)
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
        }
        break;
    }
    case 0x15: {
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

            insertMeasurement(spo2Str, pulseStr);

            qDebug().noquote() << QString(" SPO2 ➔ SpO2: %1 %% | Pulse: %2 bpm")
                                      .arg(spo2Str).arg(pulseStr);
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

    // Sadece ilk hatayı logla, sonrasında spam yapma
    if (!errorLogged) {
        qDebug() << "Serial Port Hatası:" << error << "-" << serial->errorString();
        qDebug() << "Program port olmadan devam edecek...";
        errorLogged = true;
    }

    if (serial->isOpen()) {
        serial->close();
    }

    emit serialConnectedChanged();
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

void MainWindow::initDatabase()
{
    db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(QDir::homePath() + "/Desktop/sqlite_data/measurement_data.db");

    if (!db.open()) {
        qWarning() << "Veritabanı açılamadı:" << db.lastError().text();
        return;
    }

    QSqlQuery query;
    QString createTable =
        "CREATE TABLE IF NOT EXISTS measurements ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "timestamp TEXT, "
        "spo2 TEXT, "
        "pulse TEXT)";

    if (!query.exec(createTable)) {
        qWarning() << "Tablo oluşturulamadı:" << query.lastError().text();
    } else {
        qDebug() << "Veritabanı ve tablo hazır.";
    }
}

void MainWindow::insertMeasurement(const QString &spo2, const QString &pulse)
{
    if (!db.isOpen())
        return;

    QSqlQuery query;
    query.prepare("INSERT INTO measurements (timestamp, spo2, pulse) "
                  "VALUES (:timestamp, :spo2, :pulse)");

    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    query.bindValue(":timestamp", timestamp);
    query.bindValue(":spo2", spo2);
    query.bindValue(":pulse", pulse);

    if (!query.exec()) {
        qWarning() << "Veri eklenemedi:" << query.lastError().text();
    } else {
        qDebug() << "Veri eklendi:" << timestamp << spo2 << pulse;

    }
}

// Manuel yeniden bağlanma fonksiyonu (QML'den çağırılabilir)
void MainWindow::reconnectSerial()
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

QVariantList MainWindow::getMeasurements()
{
    QVariantList measurements;
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return measurements;
    }
    QSqlQuery query;
    query.prepare("SELECT id, timestamp, spo2, pulse FROM measurements ORDER BY timestamp DESC");
    if (!query.exec()) {
        qWarning() << "Ölçümler alınamadı:" << query.lastError().text();
        return measurements;
    }
    while (query.next()) {
        QVariantMap measurement;
        measurement["id"] = query.value("id").toInt();
        measurement["timestamp"] = query.value("timestamp").toString();
        measurement["spo2"] = query.value("spo2").toString();
        measurement["pulse"] = query.value("pulse").toString();
        measurements.append(measurement);
    }
    return measurements;
}
QVariantList MainWindow::getRecentMeasurements(int limit)
{
    QVariantList measurements;
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return measurements;
    }
    QSqlQuery query;
    query.prepare("SELECT id, timestamp, spo2, pulse FROM measurements ORDER BY timestamp DESC LIMIT :limit");
    query.bindValue(":limit", limit);
    if (!query.exec()) {
        qWarning() << "Son ölçümler alınamadı:" << query.lastError().text();
        return measurements;
    }
    while (query.next()) {
        QVariantMap measurement;
        measurement["id"] = query.value("id").toInt();
        measurement["timestamp"] = query.value("timestamp").toString();
        measurement["spo2"] = query.value("spo2").toString();
        measurement["pulse"] = query.value("pulse").toString();
        measurements.append(measurement);
    }
    return measurements;
}
void MainWindow::clearMeasurements()
{
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return;
    }
    QSqlQuery query;
    if (!query.exec("DELETE FROM measurements")) {
        qWarning() << "Ölçümler temizlenemedi:" << query.lastError().text();
    } else {
        qDebug() << "Tüm ölçümler temizlendi";
        emit measurementAdded(); // Tabloyu güncellemek için sinyal gönder
    }
}
int MainWindow::getMeasurementCount()
{
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return 0;
    }
    QSqlQuery query;
    if (!query.exec("SELECT COUNT(*) FROM measurements")) {
        qWarning() << "Ölçüm sayısı alınamadı:" << query.lastError().text();
        return 0;
    }
    if (query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}

//veri akışını durdurmak için
void MainWindow::stopDataStream()
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
}

// Veritabanından son N kaydı al
QVariantList MainWindow::getMeasurementsFromDatabase(int limit)
{
    QVariantList measurements;
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return measurements;
    }

    QSqlQuery query;
    query.prepare("SELECT id, timestamp, spo2, pulse FROM measurements ORDER BY timestamp DESC LIMIT :limit");
    query.bindValue(":limit", limit);

    if (!query.exec()) {
        qWarning() << "Veriler alınamadı:" << query.lastError().text();
        return measurements;
    }

    while (query.next()) {
        QVariantMap row;
        row["id"] = query.value("id").toInt();
        row["timestamp"] = query.value("timestamp").toString();
        row["spo2"] = query.value("spo2").toString();
        row["pulse"] = query.value("pulse").toString();
        measurements.append(row);
    }

    return measurements;
}

// Toplam ölçüm sayısını al
int MainWindow::getTotalMeasurementCount()
{
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return 0;
    }

    QSqlQuery query("SELECT COUNT(*) FROM measurements");
    if (!query.exec() || !query.next()) {
        qWarning() << "Toplam kayıt sayısı alınamadı:" << query.lastError().text();
        return 0;
    }

    return query.value(0).toInt();
}

// Veritabanını temizle
void MainWindow::clearDatabase()
{
    if (!db.isOpen()) {
        qWarning() << "Veritabanı bağlantısı yok";
        return;
    }

    QSqlQuery query;
    if (!query.exec("DELETE FROM measurements")) {
        qWarning() << "Veritabanı temizlenemedi:" << query.lastError().text();
    } else {
        qDebug() << "Tüm veriler silindi";
        emit measurementAdded(); // QML tarafı tabloyu güncellesin
    }
}
