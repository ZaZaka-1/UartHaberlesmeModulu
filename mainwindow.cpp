//Sadece veritabanı ve UI işlemleri

// mainwindow.cpp
#include "mainwindow.h"
#include "serialcommunication.h"
#include <QDir>
#include <QDebug>

MainWindow::MainWindow(QObject *parent)
    : QObject(parent),
    m_spo2(""),
    m_pulse(""),
    m_currentFrequency(50)
{
    initDatabase();

    // Seri port iletişimini başlat
    serialComm = new SerialCommunication(this);

    // Sinyal-slot bağlantıları
    connect(serialComm, &SerialCommunication::frequencyReceived,
            this, &MainWindow::handleFrequencyChanged);

    connect(serialComm, &SerialCommunication::spo2PulseData,
            this, &MainWindow::handleSpo2PulseData);

    connect(serialComm, &SerialCommunication::connectionStatusChanged,
            this, &MainWindow::serialConnectedChanged);

    connect(serialComm, &SerialCommunication::ertData,
            this, &MainWindow::handleErtData);

    connect(serialComm, &SerialCommunication::waveformDataReceived,
            this, &MainWindow::handleWaveformData);

    connect(serialComm, &SerialCommunication::waveformSampleReceived, this, [this]() {
        this->m_waveformSample = serialComm->waveformSample();  // this-> ekle
        emit realTimeWaveformPoint(this->m_waveformSample);
    });
}


void MainWindow::handleWaveformData(uint8_t waveformValue)
{
    // Mevcut kodun üstüne bu kontrolü ekle
    if (m_waveformData.size() >= MAX_WAVEFORM_POINTS) {
        m_waveformData.removeFirst();
    }

    QVariantMap dataPoint;
    dataPoint["amplitude"] = waveformValue;
    dataPoint["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    m_waveformData.append(dataPoint);

    emit waveformDataChanged();
    emit realTimeWaveformPoint(waveformValue);
}

MainWindow::~MainWindow()
{
    // SerialCommunication otomatik olarak silinecek (parent-child ilişkisi)
}

bool MainWindow::isSerialConnected() const
{
    return serialComm->isConnected();
}

void MainWindow::handleSpo2PulseData(const QString &spo2, const QString &pulse)
{
    bool spo2DataChanged = false;  // Değişken adını değiştir
    bool pulseDataChanged = false; // Değişken adını değiştir

    if (spo2 != m_spo2) {
        m_spo2 = spo2;
        spo2DataChanged = true;
    }
    if (pulse != m_pulse) {
        m_pulse = pulse;
        pulseDataChanged = true;
    }

    // Veritabanına kaydet
    insertMeasurement(spo2, pulse);

    // Sinyalleri gönder
    if (spo2DataChanged) {
        emit spo2Changed();  // Artık sinyal olarak kullanılabilir
    }
    if (pulseDataChanged) {
        emit pulseChanged();
    }
}

void MainWindow::handleErtData(uint8_t hr, uint8_t rr, float t1, float t2)
{
    // ERT verilerini işle (şu an sadece log)
    // Gelecekte bu veriler için de property'ler eklenebilir
    Q_UNUSED(hr)
    Q_UNUSED(rr)
    Q_UNUSED(t1)
    Q_UNUSED(t2)
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
        emit measurementAdded();
    }
}

// Manuel yeniden bağlanma fonksiyonu (QML'den çağırılabilir)
void MainWindow::reconnectSerial()
{
    serialComm->reconnect();
}

void MainWindow::stopDataStream()
{
    serialComm->stopDataStream();
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

void MainWindow::onWaveformSampleReceived()
{
    m_waveformSample = serialComm->waveformSample();  // Veya uygun getter fonksiyonu
    emit realTimeWaveformPoint(m_waveformSample);
}

void MainWindow::sendSpo2Settings(int frequency, int mode, int averaging)
{
    if (serialComm) {
        serialComm->sendSpo2Settings(frequency, mode, averaging);
        m_currentFrequency = frequency; // Yerel değişkeni güncelle
        emit frequencyChanged(frequency);
    }
}

void MainWindow::sendSpo2SettingsFromQml(int frequency, int mode, int averaging)
{
    sendSpo2Settings(frequency, mode, averaging);
}

void MainWindow::handleFrequencyChanged(int frequency)
{
    if (frequency != m_currentFrequency) {
        m_currentFrequency = frequency;
        emit frequencyChanged(frequency);
        qDebug() << "Frekans değişti:" << frequency << "Hz";
    }
}

int currentFrequency; // Global değişken

void MainWindow::someFunction() {
    int currentFrequency; // Yerel değişken (HATA DEĞİL, ama kafa karıştırıcı)
}
