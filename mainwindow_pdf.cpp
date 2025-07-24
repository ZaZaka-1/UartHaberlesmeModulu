// PDF Export işlemleri - Ayrı dosya
// mainwindow_pdf.cpp

#include "mainwindow.h"
#include <QDir>
#include <QDebug>
#include <QStandardPaths>
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
#include <QPdfWriter>
#include <QPainter>
#include <QDateTime>
#include <QDesktopServices>
#include <QUrl>

// Session PDF Export
QString MainWindow::exportSessionToPdf()
{
    if (m_currentWaveformSession.isEmpty()) {
        qWarning() << "Session verisi boş, PDF oluşturulamaz!";
        emit pdfExportError("Session verisi bulunamadı");
        return "";
    }

    try {
        // Dosya yolu oluştur
        QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
        QString filePath = documentsPath + "/SpO2_Session_" + timestamp + ".pdf";

        // PDF dosyasını oluştur
        QPdfWriter pdfWriter(filePath);
        pdfWriter.setPageSize(QPageSize::A4);
        pdfWriter.setResolution(300);

        QPainter painter(&pdfWriter);
        if (!painter.isActive()) {
            emit pdfExportError("PDF dosyası oluşturulamadı");
            return "";
        }

        // Sayfa boyutlarını al
        QRect pageRect = pdfWriter.pageLayout().paintRectPixels(pdfWriter.resolution());

        // Başlık alanı
        QRect titleRect(pageRect.x(), pageRect.y(), pageRect.width(), pageRect.height() * 0.15);

        // Hasta bilgileri alanı
        QRect patientInfoRect(pageRect.x(), titleRect.bottom() + 20, pageRect.width(), pageRect.height() * 0.2);

        // Grafik alanı
        QRect chartRect(pageRect.x() + 50, patientInfoRect.bottom() + 30,
                        pageRect.width() - 100, pageRect.height() * 0.55);

        // Başlık çiz
        painter.setFont(QFont("Arial", 24, QFont::Bold));
        painter.drawText(titleRect, Qt::AlignCenter, "SpO2 Waveform Session Raporu");

        // Hasta bilgilerini çiz
        drawSessionInfo(&painter, patientInfoRect);

        // Session waveform grafiğini çiz
        drawSessionWaveformChart(&painter, chartRect);

        painter.end();

        qDebug() << "Session PDF başarıyla oluşturuldu:" << filePath;
        emit pdfExportCompleted(filePath);
        return filePath;

    } catch (const std::exception& e) {
        QString errorMsg = QString("Session PDF oluşturulurken hata: %1").arg(e.what());
        qWarning() << errorMsg;
        emit pdfExportError(errorMsg);
        return "";
    }
}

void MainWindow::drawSessionInfo(QPainter *painter, const QRect &infoRect)
{
    // Debug için PDF'e yazıldığını kontrol et
    qDebug() << "PDF'e session bilgileri yazılıyor...";

    QString currentDateTime = QDateTime::currentDateTime().toString("dd.MM.yyyy HH:mm:ss");
    QString dataSource = getDataSourceText();
    QString status = getStatusText(m_spo2, m_pulse);

    qDebug() << "Session - SpO2:" << m_spo2 << "Pulse:" << m_pulse << "Status:" << status << "DataSource:" << dataSource;

    // Session süresini hesapla
    double sessionDuration = 10.0; // 10 saniye
    if (!m_currentWaveformSession.isEmpty()) {
        qint64 firstTime = m_currentWaveformSession.first().toMap()["timestamp"].toLongLong();
        qint64 lastTime = m_currentWaveformSession.last().toMap()["timestamp"].toLongLong();
        sessionDuration = (lastTime - firstTime) / 1000.0;
    }

    QStringList sessionInfo;
    sessionInfo << QString("Tarih / Saat: %1").arg(currentDateTime);
    sessionInfo << QString("Session Süresi: %1 saniye").arg(QString::number(sessionDuration, 'f', 1));
    sessionInfo << QString("SpO2 Değeri: %1%").arg(m_spo2);
    sessionInfo << QString("Nabız: %1 bpm").arg(m_pulse);
    sessionInfo << QString("Durum: %1").arg(status);
    sessionInfo << QString("Veri Kaynağı: %1").arg(dataSource);
    sessionInfo << QString("Frekans: %1 Hz").arg(m_currentFrequency);
    sessionInfo << QString("Toplam Veri Noktası: %1").arg(m_currentWaveformSession.size());

    // Font büyüklüğü ve satır yüksekliğini ayarla
    int fontSize = 14;  // Daha büyük font
    int lineHeight = 40; // Daha fazla boşluk
    int startY = infoRect.y() + 20; // Başlangıç pozisyonu

    // Her satırı ayrı ayrı çiz
    for (int i = 0; i < sessionInfo.size(); ++i) {
        int currentY = startY + (i * lineHeight);

        // Font ve renk ayarlarını her satır için yap
        if (i == 4) { // Durum satırı (5. satır, index 4)
            if (status == "KRİTİK") {
                painter->setPen(QPen(QColor(255, 0, 0), 2)); // Kırmızı, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            } else {
                painter->setPen(QPen(QColor(0, 128, 0), 2)); // Yeşil, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            }
        } else if (i == 5) { // Veri Kaynağı satırı (6. satır, index 5)
            if (dataSource == "TEST VERİSİ") {
                painter->setPen(QPen(QColor(0, 0, 255), 2)); // Mavi, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            } else {
                painter->setPen(QPen(QColor(0, 0, 139), 2)); // Koyu mavi, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            }
        } else {
            painter->setPen(QPen(QColor(0, 0, 0), 1)); // Siyah, normal
            painter->setFont(QFont("Arial", fontSize, QFont::Normal));
        }

        // Metni çiz
        QRect textRect(infoRect.x() + 10, currentY - 15, infoRect.width() - 20, 30);
        painter->drawText(textRect, Qt::AlignLeft | Qt::AlignVCenter, sessionInfo[i]);

        // Debug çıktısı
        qDebug() << "PDF session satır" << i+1 << "yazıldı:" << sessionInfo[i];
    }
}

void MainWindow::drawSessionWaveformChart(QPainter *painter, const QRect &chartRect)
{
    // Grafik arka planını çiz
    drawChartBackground(painter, chartRect);

    // Grid çizgilerini çiz
    drawChartGrid(painter, chartRect);

    // Session waveform çizgisini çiz
    drawSessionWaveformLine(painter, chartRect);

    // Etiketleri çiz
    drawSessionChartLabels(painter, chartRect);
}

void MainWindow::drawSessionWaveformLine(QPainter *painter, const QRect &chartRect)
{
    if (m_currentWaveformSession.isEmpty()) {
        // Veri yoksa uyarı mesajı
        painter->setFont(QFont("Arial", 14));
        painter->setPen(QPen(Qt::red, 2));
        painter->drawText(chartRect, Qt::AlignCenter, "Session waveform verisi bulunamadı");
        return;
    }

    painter->setPen(QPen(Qt::blue, 2));

    // Session waveform verilerini çiz
    QPolygonF waveformPoints;

    int dataSize = m_currentWaveformSession.size();
    for (int i = 0; i < dataSize; ++i) {
        QVariantMap dataPoint = m_currentWaveformSession[i].toMap();
        double normalizedValue = dataPoint["value"].toDouble();

        // X pozisyonu (zaman)
        double x = chartRect.x() + (static_cast<double>(i) / (dataSize - 1)) * chartRect.width();

        // Y pozisyonu (amplitude) - normalize edilmiş değer (0-1)
        double y = chartRect.bottom() - (normalizedValue * chartRect.height());

        waveformPoints << QPointF(x, y);
    }

    // Çizgiyi çiz
    if (waveformPoints.size() > 1) {
        painter->drawPolyline(waveformPoints);
    }
}

void MainWindow::drawSessionChartLabels(QPainter *painter, const QRect &chartRect)
{
    painter->setFont(QFont("Arial", 10));
    painter->setPen(QPen(Qt::black, 1));

    // Y ekseni etiketi (Amplitude)
    painter->save();
    painter->translate(chartRect.x() - 40, chartRect.center().y());
    painter->rotate(-90);
    painter->drawText(QRect(-50, -10, 100, 20), Qt::AlignCenter, "Normalized Amplitude");
    painter->restore();

    // X ekseni etiketi (Zaman)
    painter->drawText(QRect(chartRect.center().x() - 50, chartRect.bottom() + 10, 100, 20),
                      Qt::AlignCenter, "Session Zaman (10 saniye)");

    // Y ekseni değerleri (0.0 - 1.0)
    painter->setFont(QFont("Arial", 8));
    for (int i = 0; i <= 10; ++i) {
        double value = i / 10.0;
        int y = chartRect.bottom() - (chartRect.height() * i / 10);
        painter->drawText(QRect(chartRect.x() - 35, y - 10, 30, 20),
                          Qt::AlignRight | Qt::AlignVCenter, QString::number(value, 'f', 1));
    }

    // X ekseni zaman etiketleri
    painter->setFont(QFont("Arial", 8));
    for (int i = 0; i <= 4; ++i) {
        double timeValue = (10.0 * i / 4); // 0, 2.5, 5.0, 7.5, 10.0 saniye
        int x = chartRect.x() + (chartRect.width() * i / 4);
        painter->drawText(QRect(x - 15, chartRect.bottom() + 25, 30, 20),
                          Qt::AlignCenter, QString::number(timeValue, 'f', 1) + "s");
    }
}

// Regular Waveform PDF Export
QString MainWindow::exportWaveformToPdf(const QString &fileName)
{
    try {
        // Dosya adını belirle
        QString filePath;
        if (fileName.isEmpty()) {
            QString defaultPath = getDefaultPdfPath();
            filePath = defaultPath;
        } else {
            filePath = fileName;
        }

        // PDF dosyasını oluştur
        QPdfWriter pdfWriter(filePath);
        pdfWriter.setPageSize(QPageSize::A4);
        pdfWriter.setResolution(300);

        QPainter painter(&pdfWriter);
        if (!painter.isActive()) {
            emit pdfExportError("PDF dosyası oluşturulamadı");
            return "";
        }

        // Sayfa boyutlarını al
        QRect pageRect = pdfWriter.pageLayout().paintRectPixels(pdfWriter.resolution());

        // Başlık alanı
        QRect titleRect(pageRect.x(), pageRect.y(), pageRect.width(), pageRect.height() * 0.15);

        // Hasta bilgileri alanı
        QRect patientInfoRect(pageRect.x(), titleRect.bottom() + 20, pageRect.width(), pageRect.height() * 0.2);

        // Grafik alanı
        QRect chartRect(pageRect.x() + 50, patientInfoRect.bottom() + 30,
                        pageRect.width() - 100, pageRect.height() * 0.55);

        // Başlık çiz
        painter.setFont(QFont("Arial", 24, QFont::Bold));
        painter.drawText(titleRect, Qt::AlignCenter, "SpO2 Waveform Raporu");

        // Hasta bilgilerini çiz
        drawPatientInfo(&painter, patientInfoRect);

        // Waveform grafiğini çiz
        drawWaveformChart(&painter, chartRect);

        painter.end();

        qDebug() << "PDF başarıyla oluşturuldu:" << filePath;
        emit pdfExportCompleted(filePath);
        return filePath;

    } catch (const std::exception& e) {
        QString errorMsg = QString("PDF oluşturulurken hata: %1").arg(e.what());
        qWarning() << errorMsg;
        emit pdfExportError(errorMsg);
        return "";
    }
}

bool MainWindow::exportCurrentWaveformToPdf(const QString &filePath)
{
    QString resultPath = exportWaveformToPdf(filePath);
    return !resultPath.isEmpty();
}

QString MainWindow::getDefaultPdfPath()
{
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    return documentsPath + "/SpO2_Waveform_" + timestamp + ".pdf";
}

void MainWindow::drawPatientInfo(QPainter *painter, const QRect &infoRect)
{
    // Debug için PDF'e yazıldığını kontrol et
    qDebug() << "PDF'e hasta bilgileri yazılıyor...";

    QString currentDateTime = QDateTime::currentDateTime().toString("dd.MM.yyyy HH:mm:ss");
    QString dataSource = getDataSourceText();
    QString status = getStatusText(m_spo2, m_pulse);

    qDebug() << "SpO2:" << m_spo2 << "Pulse:" << m_pulse << "Status:" << status << "DataSource:" << dataSource;

    QStringList patientInfo;
    patientInfo << QString("Tarih / Saat: %1").arg(currentDateTime);
    patientInfo << QString("SpO2 Değeri: %1%").arg(m_spo2);
    patientInfo << QString("Nabız: %1 bpm").arg(m_pulse);
    patientInfo << QString("Durum: %1").arg(status);
    patientInfo << QString("Veri Kaynağı: %1").arg(dataSource);
    patientInfo << QString("Frekans: %1 Hz").arg(m_currentFrequency);
    patientInfo << QString("Toplam Veri Noktası: %1").arg(m_waveformData.size());

    // Font büyüklüğü ve satır yüksekliğini ayarla
    int fontSize = 14;  // Daha büyük font
    int lineHeight = 40; // Daha fazla boşluk
    int startY = infoRect.y() + 20; // Başlangıç pozisyonu

    // Her satırı ayrı ayrı çiz
    for (int i = 0; i < patientInfo.size(); ++i) {
        int currentY = startY + (i * lineHeight);

        // Font ve renk ayarlarını her satır için yap
        if (i == 3) { // Durum satırı (4. satır, index 3)
            if (status == "KRİTİK") {
                painter->setPen(QPen(QColor(255, 0, 0), 2)); // Kırmızı, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            } else {
                painter->setPen(QPen(QColor(0, 128, 0), 2)); // Yeşil, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            }
        } else if (i == 4) { // Veri Kaynağı satırı (5. satır, index 4)
            if (dataSource == "TEST VERİSİ") {
                painter->setPen(QPen(QColor(0, 0, 255), 2)); // Mavi, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            } else {
                painter->setPen(QPen(QColor(0, 0, 139), 2)); // Koyu mavi, kalın
                painter->setFont(QFont("Arial", fontSize, QFont::Bold));
            }
        } else {
            painter->setPen(QPen(QColor(0, 0, 0), 1)); // Siyah, normal
            painter->setFont(QFont("Arial", fontSize, QFont::Normal));
        }

        // Metni çiz
        QRect textRect(infoRect.x() + 10, currentY - 15, infoRect.width() - 20, 30);
        painter->drawText(textRect, Qt::AlignLeft | Qt::AlignVCenter, patientInfo[i]);

        // Debug çıktısı
        qDebug() << "PDF satır" << i+1 << "yazıldı:" << patientInfo[i];
    }
}

void MainWindow::drawWaveformChart(QPainter *painter, const QRect &chartRect)
{
    // Grafik arka planını çiz
    drawChartBackground(painter, chartRect);

    // Grid çizgilerini çiz
    drawChartGrid(painter, chartRect);

    // Waveform çizgisini çiz
    drawWaveformLine(painter, chartRect);

    // Etiketleri çiz
    drawChartLabels(painter, chartRect);
}

void MainWindow::drawChartBackground(QPainter *painter, const QRect &chartRect)
{
    // Beyaz arka plan
    painter->fillRect(chartRect, QColor(Qt::white));

    // Siyah çerçeve
    painter->setPen(QPen(Qt::black, 2));
    painter->drawRect(chartRect);
}

void MainWindow::drawChartGrid(QPainter *painter, const QRect &chartRect)
{
    painter->setPen(QPen(Qt::lightGray, 1, Qt::DashLine));

    // Yatay grid çizgileri (amplitude için)
    int gridLines = 10;
    for (int i = 1; i < gridLines; ++i) {
        int y = chartRect.y() + (chartRect.height() * i / gridLines);
        painter->drawLine(chartRect.left(), y, chartRect.right(), y);
    }

    // Dikey grid çizgileri (zaman için)
    for (int i = 1; i < gridLines; ++i) {
        int x = chartRect.x() + (chartRect.width() * i / gridLines);
        painter->drawLine(x, chartRect.top(), x, chartRect.bottom());
    }
}

void MainWindow::drawWaveformLine(QPainter *painter, const QRect &chartRect) {
    if (m_waveformData.isEmpty()) {
        painter->drawText(chartRect, Qt::AlignCenter, "Veri yok!");
        return;
    }

    painter->setPen(QPen(Qt::blue, 2)); // Çizgi rengi ve kalınlığı
    QPolygonF points;

    for (int i = 0; i < m_waveformData.size(); ++i) {
        double x = chartRect.left() + (i * chartRect.width() / m_waveformData.size());
        double y = chartRect.bottom() - (m_waveformData[i].toMap()["amplitude"].toInt() * chartRect.height() / 255.0);
        points << QPointF(x, y);
    }

    painter->drawPolyline(points); // Çizgiyi çiz
}

void MainWindow::drawChartLabels(QPainter *painter, const QRect &chartRect)
{
    painter->setFont(QFont("Arial", 10));
    painter->setPen(QPen(Qt::black, 1));

    // Y ekseni etiketi (Amplitude)
    painter->save();
    painter->translate(chartRect.x() - 40, chartRect.center().y());
    painter->rotate(-90);
    painter->drawText(QRect(-50, -10, 100, 20), Qt::AlignCenter, "Amplitude");
    painter->restore();

    // X ekseni etiketi (Zaman)
    painter->drawText(QRect(chartRect.center().x() - 50, chartRect.bottom() + 10, 100, 20),
                      Qt::AlignCenter, "Zaman");

    // Y ekseni değerleri
    painter->setFont(QFont("Arial", 8));
    for (int i = 0; i <= 10; ++i) {
        int value = (255 * i / 10);
        int y = chartRect.bottom() - (chartRect.height() * i / 10);
        painter->drawText(QRect(chartRect.x() - 35, y - 10, 30, 20),
                          Qt::AlignRight | Qt::AlignVCenter, QString::number(value));
    }
}

// Genel PDF Report Generation
void MainWindow::generatePdfReport(const QString &spo2, const QString &pulse,
                                   const QString &ageGroup, bool isNormalRange,
                                   const QString &recordTime, const QString &normalRange,
                                   const QString &imagePath)
{
    try {
        QString filePath = getDefaultPdfPath();

        QPdfWriter pdfWriter(filePath);
        pdfWriter.setPageSize(QPageSize::A4);
        pdfWriter.setResolution(300);

        QPainter painter(&pdfWriter);
        if (!painter.isActive()) {
            emit pdfExportError("PDF dosyası oluşturulamadı");
            return;
        }

        QRect pageRect = pdfWriter.pageLayout().paintRectPixels(pdfWriter.resolution());

        // Başlık alanı
        QRect titleRect(pageRect.x(), pageRect.y(), pageRect.width(), pageRect.height() * 0.15);

        // Hasta bilgileri alanı
        QRect patientInfoRect(pageRect.x(), titleRect.bottom() + 20, pageRect.width(), pageRect.height() * 0.2);

        // Grafik alanı
        QRect chartRect(pageRect.x() + 50, patientInfoRect.bottom() + 30,
                        pageRect.width() - 100, pageRect.height() * 0.55);

        // Başlık çiz
        painter.setFont(QFont("Arial", 24, QFont::Bold));
        painter.drawText(titleRect, Qt::AlignCenter, "SpO2 Monitor Raporu");

        // Geliştirilmiş hasta bilgileri
        QString dataSource = getDataSourceText();
        QString status = getStatusText(spo2, pulse);

        painter.setFont(QFont("Arial", 12));

        QStringList reportInfo;
        reportInfo << QString("Tarih / Saat: %1").arg(recordTime);
        reportInfo << QString("SpO2 Değeri: %1%").arg(spo2);
        reportInfo << QString("Nabız: %1 bpm").arg(pulse);
        reportInfo << QString("Durum: %1").arg(status);
        reportInfo << QString("Veri Kaynağı: %1").arg(dataSource);
        reportInfo << QString("Yaş Grubu: %1").arg(ageGroup);
        reportInfo << QString("Normal Aralık: %1").arg(normalRange);

        int lineHeight = 25;
        int y = patientInfoRect.y();

        for (int i = 0; i < reportInfo.size(); ++i) {
            if (i == 3) { // Durum satırı
                if (status == "KRİTİK") {
                    painter.setPen(QPen(Qt::red, 1));
                    painter.setFont(QFont("Arial", 12, QFont::Bold));
                } else {
                    painter.setPen(QPen(Qt::darkGreen, 1));
                    painter.setFont(QFont("Arial", 12, QFont::Bold));
                }
            } else if (i == 4) { // Veri Kaynağı satırı
                if (dataSource == "TEST VERİSİ") {
                    painter.setPen(QPen(Qt::blue, 1));
                    painter.setFont(QFont("Arial", 12, QFont::Bold));
                } else {
                    painter.setPen(QPen(Qt::darkBlue, 1));
                    painter.setFont(QFont("Arial", 12, QFont::Bold));
                }
            } else {
                painter.setPen(QPen(Qt::black, 1));
                painter.setFont(QFont("Arial", 12, QFont::Normal));
            }

            painter.drawText(patientInfoRect.x(), y, reportInfo[i]);
            y += lineHeight;
        }

        // Eğer görsel dosyası varsa ekle
        if (!imagePath.isEmpty() && QFile::exists(imagePath)) {
            QImage waveformImage(imagePath);
            if (!waveformImage.isNull()) {
                painter.drawImage(chartRect, waveformImage.scaled(chartRect.size(),
                                                                  Qt::KeepAspectRatio, Qt::SmoothTransformation));
            }
        }

        painter.end();

        emit pdfExportCompleted(filePath);
    } catch (const std::exception& e) {
        emit pdfExportError(QString("PDF oluşturulurken hata: %1").arg(e.what()));
    }
}

// Base64 PNG'den PDF oluşturma
void MainWindow::exportToPdfFromBase64(const QString &base64Png)
{
    QByteArray imageData = QByteArray::fromBase64(base64Png.toUtf8());
    QImage image;
    if (!image.loadFromData(imageData, "PNG")) {
        emit pdfExportError("PNG verisi çözümlenemedi.");
        return;
    }

    QString baseDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QString waveformDir = baseDir + "/WaveformPDF";
    QDir().mkpath(waveformDir); // Klasör yoksa oluşturulur

    QString fileName = "waveform_" + QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss") + ".pdf";
    QString filePath = waveformDir + "/" + fileName;

    QPdfWriter writer(filePath);
    writer.setPageSize(QPageSize::A4);
    writer.setResolution(300);

    QPainter painter(&writer);
    QRect rect = painter.viewport();

    // Görseli sayfaya sığacak şekilde ölçeklendir
    QSize imageSize = image.size();
    imageSize.scale(rect.size(), Qt::KeepAspectRatio);

    painter.setViewport(rect.x(), rect.y(), imageSize.width(), imageSize.height());
    painter.setWindow(image.rect());
    painter.drawImage(0, 0, image);

    // Ek bilgileri ekleyebilirsiniz (isteğe bağlı)
    painter.setFont(QFont("Arial", 12));
    painter.drawText(rect, Qt::AlignBottom | Qt::AlignLeft,
                     QString("SPO2: %1% | Pulse: %2 bpm").arg(m_spo2).arg(m_pulse));

    painter.end();

    emit pdfExportCompleted(filePath);
    qDebug() << "PDF başarıyla kaydedildi:" << filePath;
}

// PDF dosyasını açma
void MainWindow::openPdfFile(const QString &filePath)
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
}

void MainWindow::exportToPdfWithWaveform(const QString &base64Data, const QString &patientJson)
{
    Q_UNUSED(patientJson); // Eğer JSON kullanılmayacaksa geçici olarak sustur

    exportToPdfFromBase64(base64Data);
}

QString MainWindow::getDataSourceText() const
{
    return m_isTestMode ? "TEST VERİSİ" : "CANLI VERİ";
}

QString MainWindow::getStatusText(const QString &spo2, const QString &pulse) const
{
    bool spo2Ok = false;
    bool pulseOk = false;

    // SpO2 kontrolü (95-100 arası normal)
    int spo2Value = spo2.toInt(&spo2Ok);
    if (spo2Ok && spo2Value >= 95 && spo2Value <= 100) {
        spo2Ok = true;
    } else {
        spo2Ok = false;
    }

    // Nabız kontrolü (60-100 arası normal)
    int pulseValue = pulse.toInt(&pulseOk);
    if (pulseOk && pulseValue >= 60 && pulseValue <= 100) {
        pulseOk = true;
    } else {
        pulseOk = false;
    }

    return (spo2Ok && pulseOk) ? "NORMAL" : "KRİTİK";
}
