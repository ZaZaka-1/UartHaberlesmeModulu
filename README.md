# 📊 SpO2 ve Nabız İzleme Sistemi 

Proje Dokümantasyonu


<img width="855" height="786" alt="Ekran görüntüsü 2025-07-11 151131" src="https://github.com/user-attachments/assets/22618bee-303f-408f-a047-662fd1f3b865" />

Hazırlayan: Arda Hüseyin Uçkun
Tarih: 28.07.2025
Versiyon: 1.0

________________________________________
İçindekiler
1.	Giriş
2.	Proje Genel Bakış
3.	Sistem Mimarisi
4.	Kullanılan Teknolojiler
5.	Veritabanı Yapısı
6.	Seri Port İletişimi
7.	PDF Raporlama
8.	Test Modülü
9.	Sonuç ve Değerlendirme

________________________________________
1. Giriş
Bu doküman, SpO2 ve Nabız İzleme Sistemi projesinin teknik detaylarını, mimarisini ve işlevselliğini açıklamaktadır. Proje, hasta sağlık verilerini gerçek zamanlı olarak izlemek, kaydetmek ve raporlamak için geliştirilmiştir.
Projenin Amacı
•	SpO2 (Oksijen Doygunluğu) ve nabız verilerini gerçek zamanlı olarak okumak.
•	Verileri bir veritabanında saklamak.
•	Kullanıcı dostu bir arayüz sunmak.
•	Otomatik PDF raporları oluşturmak.
________________________________________
2. Proje Genel Bakış
Proje, bir Qt/QML tabanlı masaüstü uygulamasıdır ve aşağıdaki bileşenleri içerir:
1.	Seri Port İletişimi – SpO2 sensöründen veri okuma.
2.	Veritabanı Yönetimi – Ölçümlerin saklanması.
3.	Grafiksel Kullanıcı Arayüzü (QML) – Verilerin görselleştirilmesi.
4.	PDF Raporlama – Hasta verilerinin dökümünü oluşturma.
5.	Test Modülü – Gerçek veri olmadan simülasyon yapma.
________________________________________
3. Sistem Mimarisi
Proje, Model-View-ViewModel (MVVM) mimarisi kullanılarak geliştirilmiştir.
Ana Bileşenler
Bileşen	Açıklama
MainWindow	Veri işleme, veritabanı ve PDF oluşturma işlemleri.
SerialCommunication	Seri port üzerinden veri okuma ve gönderme.
QML Arayüzü	Kullanıcı etkileşimi ve veri görselleştirme.
SQLite Veritabanı	Ölçümlerin saklanması.
________________________________________
4. Kullanılan Teknolojiler
Teknoloji	Kullanım Amacı
Qt Framework	Çapraz platform uygulama geliştirme.
QML	Dinamik ve modern kullanıcı arayüzü.
SQLite	Yerel veritabanı yönetimi.
QPdfWriter	PDF rapor oluşturma.
QSerialPort	Seri port iletişimi.
________________________________________
5. Veritabanı Yapısı
Veritabanı, SQLite kullanılarak oluşturulmuştur.
Tablo: measurements
Sütun	Veri Tipi	Açıklama
id	INTEGER	Birincil anahtar.
timestamp	TEXT	Ölçüm zaman damgası.
spo2	TEXT	SpO2 değeri (%).
pulse	TEXT	Nabız değeri (bpm).
imageData	TEXT	Waveform görseli (Base64).
Örnek SQL Sorguları
sql
-- Yeni ölçüm ekleme
INSERT INTO measurements (timestamp, spo2, pulse) 
VALUES ('2023-10-01 14:30:00', '98', '72');
-- Son 10 ölçümü getirme
SELECT * FROM measurements ORDER BY timestamp DESC LIMIT 10;
________________________________________
6. Seri Port İletişimi
SerialCommunication sınıfı, cihazla iletişimi yönetir.
Bağlantı Ayarları
Parametre	Değer
Port	COM4
Baud Rate	375000
Data Bits	8
Parity	Odd
Stop Bits	1
Veri Paket Yapısı
plaintext
[AA 55] [Length] [Code] [Data...] [Checksum]
•	AA 55: Başlık (Header).
•	Length: Veri uzunluğu.
•	Code: Paket türü (Örn: 0x15 = SpO2 verisi).
•	Checksum: Doğrulama için checksum.
Örnek Veri İşleme
cpp
void SerialCommunication::parsePacketByCode(uint8_t code, const QByteArray &payload) {
    if (code == 0x15) { // SpO2 verisi
        uint8_t spo2 = payload[3];
        uint16_t pulse = (payload[4] << 8) | payload[5];
        emit spo2PulseData(QString::number(spo2), QString::number(pulse));
    }
 }
________________________________________
7. PDF Raporlama
MainWindow sınıfı, PDF raporları oluşturur.
Rapor Türleri
1.	Anlık Waveform Raporu
o	SpO2, nabız ve grafik içerir.
2.	Session Raporu
o	10 saniyelik veri kaydını gösterir.
PDF Oluşturma Örneği
cpp
QString MainWindow::exportWaveformToPdf(const QString &fileName) {
    QPdfWriter pdfWriter(fileName);
    QPainter painter(&pdfWriter);
    
    // Başlık ekle
    painter.setFont(QFont("Arial", 24, QFont::Bold));
    painter.drawText(100, 100, "SpO2 Raporu");
    
    // Waveform çiz
    drawWaveformChart(&painter, QRect(50, 150, 500, 300));
    
    painter.end();
    return fileName;
}
________________________________________
8. Test Modülü
Gerçek veri olmadığında test verileri üretir.
Test Verisi Üretme
cpp
void MainWindow::generateTestData() {
    m_testSpo2 = 96 + rand() % 5;  // 96-100 arası
    m_testPulse = 65 + rand() % 20; // 65-85 arası
    emit spo2Changed();
    emit pulseChanged();
}
________________________________________
9. Sonuç ve Değerlendirme
Bu proje, gerçek zamanlı hasta izleme için kullanılabilir.
Geliştirilebilecek Özellikler
•	Bulut Entegrasyonu – Verilerin uzak sunucuya gönderilmesi.
•	Multi-Dil Desteği – Farklı dillerde raporlama.
•	Mobil Uyumluluk – Android/iOS entegrasyonu.
________________________________________
Sonuç:
Bu doküman, SpO2 ve Nabız İzleme Sistemi projesinin teknik detaylarını kapsamaktadır. Proje, Qt ve QML kullanılarak geliştirilmiş olup, veri görselleştirme, raporlama ve veritabanı yönetimi gibi özellikler içermektedir.
Ekler:
•	Kaynak Kodları
•	QML Arayüz Ekran Görüntüleri
•	Örnek PDF Raporları


🌟 Geliştirici Bilgileri
Geliştirici	Arda Hüseyin Uçkun
Versiyon	1.0 (28.07.2025)

🚀 Kurulum Rehberi
Gereksinimler
Qt Creator 6.5+
CMake 3.25+
Serial Port Driver (CP210x gerekebilir)

📬 Katkı & İletişim
✉️ ardaauckun2005@gmail.com







