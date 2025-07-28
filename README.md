# 📊 SpO2 ve Nabız İzleme Sistemi 
**Qt/QML Tabanlı Gerçek Zamanlı Hasta Monitörü**

![Proje Arayüz Örneği](https://via.placeholder.com/800x400?text=SpO2+Monitoring+UI) *(Örnek ekran görüntüsü)*

## 📌 Proje Özeti
UART üzerinden SpO2 ve nabız verilerini okuyan, SQLite'da saklayan ve PDF raporu üretebilen çapraz platform masaüstü uygulaması.

```plaintext
Öne Çıkan Özellikler:
✔ Gerçek zamanlı veri görselleştirme (Waveform grafikleri)
✔ Otomatik PDF rapor üretimi
✔ Test modu ile simülasyon desteği
✔ MVVM Mimarisi ile modüler yapı

🛠️ Teknoloji Stack'i
Bileşen	Açıklama
Qt 6.5	Çekirdek uygulama framework'ü
QML	Dinamik kullanıcı arayüzü
SQLite	Yerel veritabanı yönetimi
QSerialPort	Seri haberleşme modülü
QPdfWriter	PDF rapor oluşturucu

🚀 Kurulum Rehberi
Gereksinimler
Qt Creator 6.5+
CMake 3.25+
Serial Port Driver (CP210x gerekebilir)

Derleme Adımları
bash
git clone https://github.com/ZaZaka-1/UartHaberlesmeModulu_SaturasyonVeNabiz.git
cd UartHaberlesmeModulu_SaturasyonVeNabiz
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=/path/to/qt6 ..
make -j4

📖 Kullanım Kılavuzu
Seri Port Bağlantısı
cpp
// Örnek bağlantı parametreleri
serial.setPortName("COM4");
serial.setBaudRate(QSerialPort::Baud375000);
serial.setParity(QSerialPort::OddParity);
Veri Paket Yapısı
plaintext
[AA 55][Length][Code][Data...][Checksum]
▸ AA 55: Header
▸ Code 0x15: SpO2/Nabız verisi
Örnek Veritabanı Sorgusu
sql
-- Son 10 ölçümü getir
SELECT timestamp, spo2, pulse 
FROM measurements 
ORDER BY timestamp DESC 
LIMIT 10;

📂 Proje Yapısı
text
src/
├── core/                  # Arka plan işlemleri
│   ├── SerialManager.cpp  # UART iletişimi
│   └── Database.cpp       # SQLite entegrasyonu
├── qml/                   # Kullanıcı arayüzü
│   ├── Main.qml           # Ana ekran
│   └── Waveform.qml       # Grafik bileşeni
└── reports/               # PDF oluşturucu
🔧 Test Modülü
Simülasyon modunu aktif etmek için:

qml
CheckBox {
    text: "Test Modu"
    onCheckedChanged: backend.enableTestMode(checked)
}
📝 Raporlama Örneği
https://via.placeholder.com/400?text=Sample+PDF+Report

🌟 Geliştirici Bilgileri
Geliştirici	Arda Hüseyin Uçkun
Versiyon	1.0 (28.07.2025)

📬 Katkı & İletişim
✉️ ardaauckun2005@gmail.com

🔗 Öne Çıkan Özellikler:
✔ Gerçek zamanlı veri görselleştirme (Waveform grafikleri)
✔ Otomatik PDF rapor üretimi
✔ Test modu ile simülasyon desteği
✔ MVVM Mimarisi ile modüler yapı

🛠️ Teknoloji Stack'i
Bileşen	Açıklama
Qt 6.5	Çekirdek uygulama framework'ü
QML	Dinamik kullanıcı arayüzü
SQLite	Yerel veritabanı yönetimi
QSerialPort	Seri haberleşme modülü
QPdfWriter	PDF rapor oluşturucu

🚀 Kurulum Rehberi
Gereksinimler
Qt Creator 6.5+
CMake 3.25+
Serial Port Driver (CP210x gerekebilir)

Derleme Adımları
bash
git clone https://github.com/ZaZaka-1/UartHaberlesmeModulu_SaturasyonVeNabiz.git
cd UartHaberlesmeModulu_SaturasyonVeNabiz
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=/path/to/qt6 ..
make -j4

📖 Kullanım Kılavuzu
Seri Port Bağlantısı
cpp
// Örnek bağlantı parametreleri
serial.setPortName("COM4");
serial.setBaudRate(QSerialPort::Baud375000);
serial.setParity(QSerialPort::OddParity);
Veri Paket Yapısı
plaintext
[AA 55][Length][Code][Data...][Checksum]
▸ AA 55: Header
▸ Code 0x15: SpO2/Nabız verisi
Örnek Veritabanı Sorgusu
sql
-- Son 10 ölçümü getir
SELECT timestamp, spo2, pulse 
FROM measurements 
ORDER BY timestamp DESC 
LIMIT 10;

📂 Proje Yapısı
text
src/
├── core/                  # Arka plan işlemleri
│   ├── SerialManager.cpp  # UART iletişimi
│   └── Database.cpp       # SQLite entegrasyonu
├── qml/                   # Kullanıcı arayüzü
│   ├── Main.qml           # Ana ekran
│   └── Waveform.qml       # Grafik bileşeni
└── reports/               # PDF oluşturucu
🔧 Test Modülü
Simülasyon modunu aktif etmek için:

qml
CheckBox {
    text: "Test Modu"
    onCheckedChanged: backend.enableTestMode(checked)
}
📝 Raporlama Örneği
https://via.placeholder.com/400?text=Sample+PDF+Report

🌟 Geliştirici Bilgileri
Geliştirici	Arda Hüseyin Uçkun
Versiyon	1.0 (28.07.2025)

📬 Katkı & İletişim
✉️ ardaauckun2005@gmail.com

🔗 https://word.cloud.microsoft/open/onedrive/?docId=676D125DB75E963B%21s41187050c307492482a0cf45117b0fb9&driveId=676D125DB75E963B





