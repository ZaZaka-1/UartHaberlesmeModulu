#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QObject>
#include <QByteArray>
#include <QAbstractListModel>
#include <QVariantMap>
#include <QVariantList>
#include <QTimer>

//SQL KOMUTLARI
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>

// PDF Export için eklenen kütüphaneler
#include <QPdfWriter>
#include <QPainter>
#include <QFileDialog>
#include <QStandardPaths>
#include <QUrl>
#include <QPageSize>
#include <QPageLayout>
#include <QFont>
#include <QRect>
#include <QPolygonF>
#include <QPointF>
#include <QPen>
#include <QBrush>
#include <QColor>
#include <QImage>
#include <QBuffer>
#include <QDesktopServices>

// Forward declaration
class SerialCommunication;

class MainWindow : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString spo2 READ spo2 NOTIFY spo2Changed)
    Q_PROPERTY(QString pulse READ pulse NOTIFY pulseChanged)
    Q_PROPERTY(bool serialConnected READ isSerialConnected NOTIFY serialConnectedChanged)
    Q_PROPERTY(int currentFrequency READ currentFrequency NOTIFY frequencyChanged)
    Q_PROPERTY(QVariantList waveformData READ waveformData NOTIFY waveformDataChanged)
    Q_PROPERTY(int waveformSample READ waveformSample NOTIFY waveformSampleChanged)
    Q_PROPERTY(bool isRecordingSession READ isRecordingSession NOTIFY recordingSessionChanged)

public:

    Q_INVOKABLE QVariantList getWaveformImages();
    Q_INVOKABLE void insertWaveformImage(const QString &spo2, const QString &pulse, const QString &imageData);

    QString generateWaveformImage(const QVariantList &waveformData);
    Q_INVOKABLE void startTestData(int intervalMs = 100);
    Q_INVOKABLE void stopTestData();
    Q_INVOKABLE void sendTestValue(int waveformValue);
    Q_PROPERTY(bool isTestMode READ isTestMode NOTIFY testModeChanged)
    bool isTestMode() const { return m_isTestMode; }


    explicit MainWindow(QObject *parent = nullptr);
    ~MainWindow();

    // Getter fonksiyonları
    QString spo2() const { return m_spo2; }
    QString pulse() const { return m_pulse; }
    bool isSerialConnected() const;
    int currentFrequency() const { return m_currentFrequency; }
    int waveformSample() const { return m_waveformSample; }
    QVariantList waveformData() const { return m_waveformData; }
    bool isRecordingSession() const { return m_isRecordingSession; }

    // Database işlemleri
    Q_INVOKABLE QVariantList getMeasurements();
    Q_INVOKABLE QVariantList getRecentMeasurements(int limit = 50);
    Q_INVOKABLE void clearMeasurements();
    Q_INVOKABLE int getMeasurementCount();
    Q_INVOKABLE QVariantList getMeasurementsFromDatabase(int limit);
    Q_INVOKABLE int getTotalMeasurementCount();
    Q_INVOKABLE void clearDatabase();

    // Ayarlar ve kontrol
    Q_INVOKABLE void sendSpo2SettingsFromQml(int frequency, int mode, int averaging);
    Q_INVOKABLE void reconnectSerial();
    Q_INVOKABLE void stopDataStream();

    // PDF Export fonksiyonları - Regular Waveform
    Q_INVOKABLE QString exportWaveformToPdf(const QString &fileName = "");
    Q_INVOKABLE bool exportCurrentWaveformToPdf(const QString &filePath = "");
    Q_INVOKABLE QString getDefaultPdfPath();

    // PDF Export fonksiyonları - Session
    Q_INVOKABLE QString exportSessionToPdf();

    // PDF Export fonksiyonları - Base64
    Q_INVOKABLE void exportToPdfFromBase64(const QString &base64Png);
    Q_INVOKABLE void exportToPdfWithWaveform(const QString &base64Data, const QString &patientJson);

    // PDF Export fonksiyonları - Genel Report
    void generatePdfReport(const QString &spo2, const QString &pulse,
                           const QString &ageGroup, bool isNormalRange,
                           const QString &recordTime, const QString &normalRange,
                           const QString &imagePath = "");

    // PDF dosyasını açma
    Q_INVOKABLE void openPdfFile(const QString &filePath);

    // Session yönetimi
    Q_INVOKABLE void startWaveformSession();
    Q_INVOKABLE void stopWaveformSession();

signals:
    void testModeChanged();


    void spo2Changed();
    void pulseChanged();
    void serialConnectedChanged();
    void measurementAdded();
    void waveformDataChanged();
    void realTimeWaveformPoint(int amplitude);
    void frequencyChanged(int newFrequency);
    void waveformSampleChanged();
    void recordingSessionChanged();

    // PDF Export sinyalleri
    void pdfExportCompleted(const QString &filePath);
    void pdfExportError(const QString &errorMessage);

    // Session sinyalleri
    void waveformSessionStarted();
    void waveformSessionStopped();
    void waveformSessionCompleted();

private slots:
    void generateTestData();

    void handleWaveformData(uint8_t waveformValue);
    void handleSpo2PulseData(const QString &spo2, const QString &pulse);
    void handleErtData(uint8_t hr, uint8_t rr, float t1, float t2);
    void handleFrequencyChanged(int frequency);
    void onWaveformSampleReceived();
    void onSessionTimeout();

private:

    // Test için eklenen members
    QTimer *m_testTimer;
    bool m_isTestMode = false;
    double m_testPhase = 0.0;
    int m_testSpo2 = 98;
    int m_testPulse = 72;
    double m_waveformPhase = 0.0;

    // Constants
    static const int MAX_WAVEFORM_POINTS = 200;

    // Core components
    SerialCommunication *serialComm;
    QSqlDatabase db;
    QTimer *m_sessionTimer;

    // Data members
    QVariantList m_waveformData;
    QVariantList m_currentWaveformSession;
    int m_waveformSample = 0;
    int m_currentFrequency = 50;
    QString m_spo2;
    QString m_pulse;
    bool m_isRecordingSession = false;

    // Database functions
    void initDatabase();
    void insertMeasurement(const QString &spo2, const QString &pulse);
    void sendSpo2Settings(int frequency, int mode, int averaging);

    // PDF Export functions - Regular Waveform
    void drawWaveformChart(QPainter *painter, const QRect &chartRect);
    void drawChartBackground(QPainter *painter, const QRect &chartRect);
    void drawChartGrid(QPainter *painter, const QRect &chartRect);
    void drawWaveformLine(QPainter *painter, const QRect &chartRect);
    void drawChartLabels(QPainter *painter, const QRect &chartRect);
    void drawPatientInfo(QPainter *painter, const QRect &infoRect);

    QString getDataSourceText() const;
    QString getStatusText(const QString &spo2, const QString &pulse) const;

    // PDF Export functions - Session
    void drawSessionInfo(QPainter *painter, const QRect &infoRect);
    void drawSessionWaveformChart(QPainter *painter, const QRect &chartRect);
    void drawSessionWaveformLine(QPainter *painter, const QRect &chartRect);
    void drawSessionChartLabels(QPainter *painter, const QRect &chartRect);
};

#endif // MAINWINDOW_H
