#include "veritabani.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QCoreApplication>  // Uygulama dizinini almak için gerekli

Veritabani::Veritabani()
{
    // Veritabanı bağlantısını kur ve dosya yolunu belirle
    if (QSqlDatabase::contains("qt_sql_default_connection"))
        db = QSqlDatabase::database("qt_sql_default_connection");
    else
        db = QSqlDatabase::addDatabase("QSQLITE");

    // Uygulamanın çalıştığı dizinde dosyayı oluştur
    QString veritabaniYolu = QCoreApplication::applicationDirPath() + "/veritabani.sqlite";
    db.setDatabaseName(veritabaniYolu);

    if (!db.open()) {
        qWarning() << "Veritabanı açılamadı:" << db.lastError().text();
    } else {
        qDebug() << "Veritabanı açıldı. Yol:" << veritabaniYolu;
        tabloOlustur();  // Veritabanı açıldıysa tabloyu oluştur
    }
}

Veritabani::~Veritabani()
{
    if (db.isOpen())
        db.close();
}

void Veritabani::tabloOlustur()
{
    QSqlQuery query;
    bool success = query.exec(
        "CREATE TABLE IF NOT EXISTS veri ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "spo2 TEXT, "
        "pulse INTEGER, "
        "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)"
        );

    if (!success) {
        qWarning() << "Tablo oluşturulamadı:" << query.lastError().text();
    } else {
        qDebug() << "Tablo başarıyla oluşturuldu (veya zaten vardı)";
    }
}

bool Veritabani::veriEkle(const QString &spo2, int pulse)
{
    QSqlQuery query;
    query.prepare("INSERT INTO veri (spo2, pulse) VALUES (:spo2, :pulse)");
    query.bindValue(":spo2", spo2);
    query.bindValue(":pulse", pulse);

    if (!query.exec()) {
        qWarning() << "Veri eklenemedi:" << query.lastError().text();
        return false;
    }

    qDebug() << "Veri başarıyla eklendi:" << spo2 << pulse;
    return true;
}
