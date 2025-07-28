# 📊 SpO2 ve Nabız İzleme Sistemi

**Gerçek zamanlı sağlık verisi takibi, grafiksel arayüz ve PDF raporlama özellikli masaüstü uygulama**

---

## 🛠️ Geliştirici Bilgileri

- 👤 **Geliştirici:** Arda Hüseyin Uçkun  
- 📅 **Versiyon:** 1.0  
- 🗓️ **Tarih:** 28.07.2025  

---

## 📌 İçindekiler

1. [Giriş](#giriş)  
2. [Proje Genel Bakış](#proje-genel-bakış)  
3. [Sistem Mimarisi](#sistem-mimarisi)  
4. [Kullanılan Teknolojiler](#kullanılan-teknolojiler)  
5. [Veritabanı Yapısı](#veritabanı-yapısı)  
6. [Seri Port İletişimi](#seri-port-iletişimi)  
7. [PDF Raporlama](#pdf-raporlama)  
8. [Test Modülü](#test-modülü)  
9. [Sonuç ve Değerlendirme](#sonuç-ve-değerlendirme)  
10. [Kurulum Rehberi](#kurulum-rehberi)  
11. [Katkı ve İletişim](#katkı-ve-iletişim)

---
Dikkat!
Fotoğraflarda görünen değerler test çıktısıdır.
<img width="926" height="902" alt="Proje_AnaSayfa" src="https://github.com/user-attachments/assets/94c13f3a-c2f8-41f0-be9b-fbb2ae7177ca" />

<img width="924" height="902" alt="Proje_VeriTablosu" src="https://github.com/user-attachments/assets/bbaa475c-bf6a-433d-a4b6-5624f36b6bba" />

<img width="917" height="1004" alt="Proje_Ayarlar" src="https://github.com/user-attachments/assets/564ba342-b858-49fc-baa3-3fa3e5cae49d" />


## 📖 Giriş

Bu proje, hasta sağlık verilerini (SpO2 ve nabız) gerçek zamanlı olarak izlemek, kaydetmek ve raporlamak amacıyla geliştirilmiştir. Modern bir grafiksel arayüz ile verileri hem görsel hem de yazılı olarak kullanıcıya sunar.

### 🎯 Amaçlar:

- SpO2 (Oksijen Doygunluğu) ve nabız verilerini anlık olarak okumak  
- Verileri yerel veritabanında saklamak  
- Kullanıcı dostu arayüz ile görselleştirmek  
- PDF raporları ile çıktı almak

---

## 🧩 Proje Genel Bakış

Qt/QML tabanlı bu masaüstü uygulama şu bileşenlerden oluşur:

- 🔌 **Seri Port İletişimi**: Sensör cihazından veri alma  
- 🗄️ **Veritabanı Yönetimi**: Ölçüm verilerini kalıcı olarak saklama  
- 🖥️ **QML Arayüzü**: Modern grafiksel kullanıcı arayüzü  
- 📄 **PDF Raporlama**: Ölçüm raporlarını PDF formatında dışa aktarma  
- 🧪 **Test Modülü**: Simülasyon verileriyle test imkânı

---

## 🧱 Sistem Mimarisi

MVVM (Model-View-ViewModel) mimarisi esas alınmıştır.

| Bileşen            | Açıklama                                     |
|--------------------|----------------------------------------------|
| `MainWindow`       | Veri işleme, veritabanı, PDF raporlama       |
| `SerialCommunication` | Cihazla seri port üzerinden iletişim      |
| `QML UI`           | Kullanıcı arayüzü ve görselleştirme          |
| `SQLite`           | Kalıcı veri saklama                          |

---

## 🧰 Kullanılan Teknolojiler

| Teknoloji        | Kullanım Amacı                   |
|------------------|----------------------------------|
| Qt Framework     | Uygulama geliştirme              |
| QML              | Dinamik kullanıcı arayüzü        |
| SQLite           | Veritabanı                       |
| QPdfWriter       | PDF raporlama                    |
| QSerialPort      | Seri port veri alışverişi        |

---

## 🗃️ Veritabanı Yapısı

SQLite veritabanı ile veriler saklanmaktadır.

**Tablo: `measurements`**

| Sütun      | Veri Tipi | Açıklama                        |
|------------|-----------|---------------------------------|
| `id`       | INTEGER   | Birincil anahtar                |
| `timestamp`| TEXT      | Ölçüm zaman damgası             |
| `spo2`     | TEXT      | Oksijen doygunluğu              |
| `pulse`    | TEXT      | Nabız değeri                    |
| `imageData`| TEXT      | Waveform görseli (Base64 PNG)   |

**Örnek Sorgular:**

```sql
-- Yeni veri ekleme
INSERT INTO measurements (timestamp, spo2, pulse) 
VALUES ('2023-10-01 14:30:00', '98', '72');

-- Son 10 veri
SELECT * FROM measurements ORDER BY timestamp DESC LIMIT 10;
🔌 Seri Port İletişimi
Bağlantı Ayarları:

Parametre	Değer
Port	COM4
Baud Rate	375000
Data Bits	8
Parity	Odd
Stop Bits	1

Paket Yapısı:

css
Kopyala
Düzenle
[AA 55] [Length] [Code] [Data...] [Checksum]
AA 55: Başlık

Code: Paket türü (örnek: 0x15 = SpO2)

Checksum: Doğrulama baytı

Örnek Kod:

cpp
Kopyala
Düzenle
void SerialCommunication::parsePacketByCode(uint8_t code, const QByteArray &payload) {
    if (code == 0x15) {
        uint8_t spo2 = payload[3];
        uint16_t pulse = (payload[4] << 8) | payload[5];
        emit spo2PulseData(QString::number(spo2), QString::number(pulse));
    }
}
📄 PDF Raporlama
Rapor Tipleri:

Anlık Waveform Raporu

Session Raporu (10 saniyelik veri)

Örnek Kod:

cpp
Kopyala
Düzenle
QString MainWindow::exportWaveformToPdf(const QString &fileName) {
    QPdfWriter pdfWriter(fileName);
    QPainter painter(&pdfWriter);
    painter.setFont(QFont("Arial", 24, QFont::Bold));
    painter.drawText(100, 100, "SpO2 Raporu");
    drawWaveformChart(&painter, QRect(50, 150, 500, 300));
    painter.end();
    return fileName;
}
🧪 Test Modülü
Gerçek sensör verisi olmadan çalışma/test imkânı sunar.

cpp
Kopyala
Düzenle
void MainWindow::generateTestData() {
    m_testSpo2 = 96 + rand() % 5;  // 96-100 arası
    m_testPulse = 65 + rand() % 20; // 65-85 arası
    emit spo2Changed();
    emit pulseChanged();
}
✅ Sonuç ve Değerlendirme
Proje, hasta izleme süreçlerinde kullanılabilir bir temel sunmaktadır.

Geliştirilebilecek Özellikler:
☁️ Bulut Entegrasyonu

🌐 Çoklu Dil Desteği

📱 Mobil Platformlara Uyarlama

🧭 Kurulum Rehberi
Gereksinimler
Qt Creator 6.5+

CMake 3.25+

Gerekli Serial Port Sürücüleri (örn: CP210x)

Projeyi Qt Creator ile açtıktan sonra CMake ile derleyip çalıştırabilirsiniz.

📬 Katkı ve İletişim
Her türlü geri bildirim ve katkı için iletişime geçebilirsiniz.

📧 E-posta: ardaauckun2005@gmail.com
