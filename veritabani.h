#ifndef VERITABANI_H
#define VERITABANI_H

#include <QString>
#include <QSqlDatabase>

class Veritabani
{
public:
    Veritabani();
    ~Veritabani();

    bool baglantiAc();
    void tabloOlustur();
    bool veriEkle(const QString &spo2, int pulse);

private:
    QSqlDatabase db;
};

#endif // VERITABANI_H
