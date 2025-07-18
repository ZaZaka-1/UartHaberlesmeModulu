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

    // PDF Export fonksiyonları
    Q_INVOKABLE QString exportWaveformToPdf(const QString &fileName = "");
    Q_INVOKABLE QString getDefaultPdfPath();
    Q_INVOKABLE bool exportCurrentWaveformToPdf(const QString &filePath = "");
    Q_INVOKABLE void openPdfFile(const QString &filePath);

    // Session yönetimi
    Q_INVOKABLE void startWaveformSession();
    Q_INVOKABLE void stopWaveformSession();
    Q_INVOKABLE QString exportSessionToPdf();

signals:
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
    void handleWaveformData(uint8_t waveformValue);
    void handleSpo2PulseData(const QString &spo2, const QString &pulse);
    void handleErtData(uint8_t hr, uint8_t rr, float t1, float t2);
    void handleFrequencyChanged(int frequency);
    void onWaveformSampleReceived();
    void onSessionTimeout();

private:
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

    // PDF Export functions
    void drawWaveformChart(QPainter *painter, const QRect &chartRect);
    void drawChartBackground(QPainter *painter, const QRect &chartRect);
    void drawChartGrid(QPainter *painter, const QRect &chartRect);
    void drawWaveformLine(QPainter *painter, const QRect &chartRect);
    void drawChartLabels(QPainter *painter, const QRect &chartRect);
    void drawPatientInfo(QPainter *painter, const QRect &infoRect);

    // Session PDF functions
    void drawSessionInfo(QPainter *painter, const QRect &infoRect);
    void drawSessionWaveformChart(QPainter *painter, const QRect &chartRect);
    void drawSessionWaveformLine(QPainter *painter, const QRect &chartRect);
    void drawSessionChartLabels(QPainter *painter, const QRect &chartRect);
};

#endif // MAINWINDOW_H
