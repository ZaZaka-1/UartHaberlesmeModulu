//Sadece veritabanı ve UI işlemleri - Ana dosya

// mainwindow.cpp

#include <QRandomGenerator>
#include <cmath>
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#include "mainwindow.h"
#include "serialcommunication.h"
#include <QDir>
#include <QDebug>
#include <QStandardPaths>
#include <QApplication>
#include <QDesktopServices>
#include <QUrl>
#include <QDateTime>


MainWindow::MainWindow(QObject *parent)
    : QObject(parent),
    m_currentWaveformSession(QVariantList()),
    m_currentFrequency(50),
    m_spo2(""),
    m_pulse(""),
    m_isRecordingSession(false)
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
        this->m_waveformSample = serialComm->waveformSample();
        emit realTimeWaveformPoint(this->m_waveformSample);
        emit waveformSampleChanged();
    });

    // Session timer için - 10 saniye
    m_sessionTimer = new QTimer(this);
    m_sessionTimer->setSingleShot(true);
    m_sessionTimer->setInterval(10000); // 10 saniye
    connect(m_sessionTimer, &QTimer::timeout, this, &MainWindow::onSessionTimeout);


    m_testTimer = new QTimer(this);
    connect(m_testTimer, &QTimer::timeout, this, &MainWindow::generateTestData);
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

    // Session recording aktifse, session verisine de ekle
    if (m_isRecordingSession) {
        QVariantMap sessionPoint;
        sessionPoint["timestamp"] = QDateTime::currentMSecsSinceEpoch();
        sessionPoint["value"] = static_cast<double>(waveformValue) / 255.0; // Normalize
        sessionPoint["spo2"] = m_spo2;
        sessionPoint["pulse"] = m_pulse;
        m_currentWaveformSession.append(sessionPoint);
    }

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
    bool spo2DataChanged = false;
    bool pulseDataChanged = false;

    qDebug() << "🔄 handleSpo2PulseData çağrıldı - SpO2:" << spo2 << "Pulse:" << pulse << "TestMode:" << m_isTestMode;

    if (spo2 != m_spo2) {
        m_spo2 = spo2;
        spo2DataChanged = true;
    }
    if (pulse != m_pulse) {
        m_pulse = pulse;
        pulseDataChanged = true;
    }

    // DÜZELTME: Test modu kontrolü ve veritabanı yazımı
    if (m_isTestMode) {
        qDebug() << "🧪 Test modu - Veritabanına yazılmıyor";
    } else {
        qDebug() << "📡 Canlı mod - Veritabanına yazılıyor...";
        insertMeasurement(spo2, pulse);
    }

    // Sinyalleri gönder
    if (spo2DataChanged) {
        emit spo2Changed();
        qDebug() << "📊 SpO2 değeri değişti, sinyal gönderildi:" << spo2;
    }

    if (pulseDataChanged) {
        emit pulseChanged();
        qDebug() << "💓 Pulse değeri değişti, sinyal gönderildi:" << pulse;
    }

    if (!spo2DataChanged && !pulseDataChanged) {
        qDebug() << "⚪ SpO2/Pulse değerleri aynı kaldı";
    }
}

void MainWindow::handleErtData(uint8_t hr, uint8_t rr, float t1, float t2)
{
    // ERT verilerini işle (şu an sadece log)
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

// OPSIYONEL: Veri yazma sıklığını kontrol etmek isterseniz
void MainWindow::insertMeasurement(const QString &spo2, const QString &pulse)
{
    if (!db.isOpen()) {
        qDebug() << "❌ Veritabanı kapalı - veri yazılamadı";
        return;
    }

    // DÜZELTME 1: Test modu kontrolü ekle (güvenlik için)
    if (m_isTestMode) {
        qDebug() << "❌ Test modu aktif - veritabanına yazılmadı";
        return;
    }

    // DÜZELTME 2: Spam kontrolünü daha esnek hale getir
    static QDateTime lastWriteTime;
    static QString lastSpo2, lastPulse;
    QDateTime currentTime = QDateTime::currentDateTime();

    // Eğer değerler değiştiyse veya 5 saniye geçtiyse yaz
    bool dataChanged = (spo2 != lastSpo2 || pulse != lastPulse);
    bool timeElapsed = !lastWriteTime.isValid() || lastWriteTime.secsTo(currentTime) >= 5;

    if (!dataChanged && !timeElapsed) {
        qDebug() << "⏸️ Veri değişmedi ve zaman henüz geçmedi - atlanıyor";
        return;
    }

    // Son değerleri güncelle
    lastWriteTime = currentTime;
    lastSpo2 = spo2;
    lastPulse = pulse;

    QSqlQuery query;
    query.prepare("INSERT INTO measurements (timestamp, spo2, pulse) "
                  "VALUES (:timestamp, :spo2, :pulse)");

    QString timestamp = currentTime.toString("yyyy-MM-dd HH:mm:ss");
    query.bindValue(":timestamp", timestamp);
    query.bindValue(":spo2", spo2);
    query.bindValue(":pulse", pulse);

    if (!query.exec()) {
        qWarning() << "❌ Veri eklenemedi:" << query.lastError().text();
    } else {
        qDebug() << "✅ CANLİ VERİ veritabanına eklendi:" << timestamp << spo2 << pulse;
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

// Waveform Session Management Functions
void MainWindow::startWaveformSession()
{
    if (m_isRecordingSession) {
        qDebug() << "Zaten bir session kaydediliyor!";
        return;
    }

    m_currentWaveformSession.clear();
    m_isRecordingSession = true;
    m_sessionTimer->start();

    qDebug() << "10 saniyelik waveform session başlatıldı...";
    emit waveformSessionStarted();
}

void MainWindow::stopWaveformSession()
{
    if (!m_isRecordingSession) {
        qDebug() << "Aktif session yok!";
        return;
    }

    m_sessionTimer->stop();
    m_isRecordingSession = false;

    qDebug() << "Waveform session durduruldu. Toplam veri:" << m_currentWaveformSession.size();
    emit waveformSessionStopped();
}

void MainWindow::onSessionTimeout()
{
    qDebug() << "10 saniyelik session tamamlandı. Veri sayısı:" << m_currentWaveformSession.size();
    m_isRecordingSession = false;
    emit waveformSessionCompleted();
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
        emit measurementAdded();
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
        emit measurementAdded();
    }
}

void MainWindow::onWaveformSampleReceived()
{
    m_waveformSample = serialComm->waveformSample();
    emit realTimeWaveformPoint(m_waveformSample);
    emit waveformSampleChanged();
}

void MainWindow::sendSpo2Settings(int frequency, int mode, int averaging)
{
    if (serialComm) {
        serialComm->sendSpo2Settings(frequency, mode, averaging);
        m_currentFrequency = frequency;
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

void MainWindow::startTestData(int intervalMs)
{
    qDebug() << "🧪 TEST MODU BAŞLATILUYOR, interval:" << intervalMs << "ms";

    // Test modu bayrağını ayarla
    m_isTestMode = true;
    emit testModeChanged();

    // Test değerlerini başlat
    m_testPhase = 0.0;
    m_waveformPhase = 0.0;
    m_testSpo2 = 96 + QRandomGenerator::global()->bounded(5);
    m_testPulse = 65 + QRandomGenerator::global()->bounded(20);
    m_testTimer->setInterval(intervalMs);
    m_testTimer->start();

    qDebug() << "✅ Test modu AKTIF - SpO2:" << m_testSpo2 << "Pulse:" << m_testPulse;
}

void MainWindow::stopTestData()
{
    qDebug() << "🛑 TEST MODU DURDURULUYOR...";

    if (m_testTimer->isActive()) {
        m_testTimer->stop();
    }

    // Test modu bayrağını kaldır
    m_isTestMode = false;
    emit testModeChanged();

    qDebug() << "✅ Test modu DURDURULDU - Artık canlı veriler veritabanına yazılacak";
}

void MainWindow::sendTestValue(int waveformValue)
{
    if (waveformValue < 0) waveformValue = 0;
    if (waveformValue > 255) waveformValue = 255;

    uint8_t testValue = static_cast<uint8_t>(waveformValue);

    qDebug() << "Test waveform değeri gönderiliyor:" << testValue;

    // Waveform verisini işle
    handleWaveformData(testValue);

    // Test SpO2 ve Pulse değerlerini gönder
    QString testSpo2Str = QString::number(m_testSpo2);
    QString testPulseStr = QString::number(m_testPulse);

    handleSpo2PulseData(testSpo2Str, testPulseStr);
}

void MainWindow::generateTestData()
{
    if (!m_isTestMode) return;

    // Waveform için sinüs dalgası oluştur (PPG benzeri)
    m_waveformPhase += 0.15; // Hız ayarı
    if (m_waveformPhase > 2 * M_PI) {
        m_waveformPhase = 0.0;
    }

    // PPG benzeri dalga formu (düzensizlikler eklenmiş)
    double baseWave = sin(m_waveformPhase);
    double noise = (QRandomGenerator::global()->bounded(20) - 10) / 100.0; // ±10% noise
    double secondHarmonic = 0.3 * sin(2 * m_waveformPhase); // İkinci harmonik

    double waveValue = 128 + 60 * (baseWave + secondHarmonic) + 20 * noise;

    // 0-255 arasında sınırla
    if (waveValue < 0) waveValue = 0;
    if (waveValue > 255) waveValue = 255;

    uint8_t waveformValue = static_cast<uint8_t>(waveValue);

    // SpO2 ve Pulse değerlerini ÇOK DAHA YAVAŞ değiştir
    static int spo2ChangeCounter = 0;
    static int pulseChangeCounter = 0;

    // SpO2'yi her 5 saniyede bir değiştir (5000ms / 100ms = 50 iteration)
    spo2ChangeCounter++;
    if (spo2ChangeCounter >= 50) {
        spo2ChangeCounter = 0;
        m_testSpo2 = 96 + QRandomGenerator::global()->bounded(5); // 96-100
        qDebug() << "SpO2 hedef değişti:" << m_testSpo2;
    }

    // Pulse'u her 3 saniyede bir değiştir (3000ms / 100ms = 30 iteration)
    pulseChangeCounter++;
    if (pulseChangeCounter >= 30) {
        pulseChangeCounter = 0;
        m_testPulse = 65 + QRandomGenerator::global()->bounded(20); // 65-85
        qDebug() << "Pulse hedef değişti:" << m_testPulse;
    }

    // Mevcut değerlerden hedefe doğru yavaşça git
    static int currentSpo2Display = m_testSpo2;
    static int currentPulseDisplay = m_testPulse;

    // SpO2'yi hedefe doğru yavaşça değiştir (her 10 iterasyonda 1 birim)
    static int spo2UpdateCounter = 0;
    spo2UpdateCounter++;
    if (spo2UpdateCounter >= 10) { // 1 saniyede bir güncelle
        spo2UpdateCounter = 0;
        if (currentSpo2Display < m_testSpo2) {
            currentSpo2Display++;
        } else if (currentSpo2Display > m_testSpo2) {
            currentSpo2Display--;
        }
    }

    // Pulse'u hedefe doğru yavaşça değiştir (her 5 iterasyonda 1 birim)
    static int pulseUpdateCounter = 0;
    pulseUpdateCounter++;
    if (pulseUpdateCounter >= 5) { // 500ms'de bir güncelle
        pulseUpdateCounter = 0;
        if (currentPulseDisplay < m_testPulse) {
            currentPulseDisplay++;
        } else if (currentPulseDisplay > m_testPulse) {
            currentPulseDisplay--;
        }
    }

    // Çok küçük rastgele varyasyonlar ekle (daha nadir)
    int finalSpo2 = currentSpo2Display;
    int finalPulse = currentPulseDisplay;

    // Her 20 iterasyonda bir küçük varyasyon
    static int variationCounter = 0;
    variationCounter++;
    if (variationCounter >= 20) { // 2 saniyede bir
        variationCounter = 0;
        if (QRandomGenerator::global()->bounded(10) < 3) { // %30 şans
            finalSpo2 += (QRandomGenerator::global()->bounded(3) - 1); // ±1
            finalPulse += (QRandomGenerator::global()->bounded(5) - 2); // ±2
        }
    }

    // Sınırları kontrol et
    if (finalSpo2 < 94) finalSpo2 = 94;
    if (finalSpo2 > 100) finalSpo2 = 100;
    if (finalPulse < 60) finalPulse = 60;
    if (finalPulse > 90) finalPulse = 90;

    // Test verilerini gönder
    handleWaveformData(waveformValue);
    handleSpo2PulseData(QString::number(finalSpo2), QString::number(finalPulse));

    // Her 5 saniyede bir debug mesajı (daha seyrek)
    static int debugCounter = 0;
    debugCounter++;
    if (debugCounter % 50 == 0) { // 100ms * 50 = 5 saniye
        qDebug().noquote() << QString("TEST DATA ➔ SpO2: %1%% (target: %2) | Pulse: %3 bpm (target: %4) | Waveform: %5")
                                  .arg(finalSpo2)
                                  .arg(m_testSpo2)
                                  .arg(finalPulse)
                                  .arg(m_testPulse)
                                  .arg(waveformValue);
    }
}



