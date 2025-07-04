import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page2
    signal navigateBack()  // Geri dönüş sinyali

    property var measurements: []
    property bool updatePending: false
    property var seenTimestamps: ({})  // Görülen timestamp'leri takip etmek için
    property int lastDatabaseCount: 0  // Son database kayıt sayısı

    Component.onCompleted: {
        console.log("main2.qml yüklendi - verileri yükleniyor...")
        loadMeasurements()
        // Sayfa açıldığında otomatik güncellemeyi başlat
        autoUpdateTimer.start()
    }

    // Yeni ölçüm eklendiğinde tabloyu güncelle - ancak yavaşlatılmış
    Connections {
        target: mainWindow
        function onMeasurementAdded() {
            // Eğer zaten bir güncelleme bekliyorsa, yeni güncelleme yapma
            if (!updatePending) {
                updatePending = true
                // 1 saniye bekle, sonra güncelle
                updateTimer.start()
            }
        }
    }

    // Güncelleme timer'ı - veri akışını yavaşlatmak için
    Timer {
        id: updateTimer
        interval: 1000  // 1 saniye
        running: false
        repeat: false
        onTriggered: {
            loadMeasurements()
            updatePending = false
        }
    }

    // Otomatik güncelleme timer'ı - belirli aralıklarla tabloyu güncelle
    Timer {
        id: autoUpdateTimer
        interval: 2000  // 2 saniyede bir güncelle
        running: false
        repeat: true
        onTriggered: {
            loadMeasurements()
        }
    }

    function loadMeasurements() {
        // Database'den tüm verileri al
        var allMeasurements = mainWindow.getMeasurementsFromDatabase(1000) // Daha fazla kayıt al

        if (!allMeasurements || allMeasurements.length === 0) {
            console.log("Database'den veri alınamadı")
            return
        }

        // Mevcut database kayıt sayısını kontrol et
        var currentDatabaseCount = mainWindow.getTotalMeasurementCount ? mainWindow.getTotalMeasurementCount() : 0

        // Eğer database'de yeni kayıt yoksa ve mevcut listede veri varsa güncelleme yapma
        if (currentDatabaseCount === lastDatabaseCount && measurements.length > 0) {
            return
        }

        lastDatabaseCount = currentDatabaseCount

        // Yeni verileri filtrele (aynı saniyedeki verileri engelle)
        var newMeasurements = []

        for (var i = 0; i < allMeasurements.length; i++) {
            var measurement = allMeasurements[i]
            var timestamp = measurement.timestamp

            // Saniye seviyesinde timestamp'i al
            var timestampSeconds = timestamp.substring(0, 19) // "YYYY-MM-DD HH:MM:SS" formatında

            // Bu saniye daha önce görülmemişse listeye ekle
            if (!seenTimestamps[timestampSeconds]) {
                seenTimestamps[timestampSeconds] = true
                newMeasurements.push(measurement)
            }
        }

        // Yeni verileri var ise listenin başına ekle (en yeni veriler üstte)
        if (newMeasurements.length > 0) {
            console.log("Yeni " + newMeasurements.length + " veri eklendi")

            // Tarihe göre ters sırala (en yeni üstte)
            newMeasurements.sort(function(a, b) {
                return new Date(b.timestamp) - new Date(a.timestamp)
            })

            // Yeni verileri mevcut verilerin başına ekle
            measurements = newMeasurements.concat(measurements)

            // Maksimum 1000 kayıt tut (performans için)
            if (measurements.length > 1000) {
                measurements = measurements.slice(0, 1000)
            }
        }
    }

    // Measurements dizisini temizle
    function clearMeasurements() {
        measurements = []
        seenTimestamps = {}
        lastDatabaseCount = 0
        console.log("Veriler temizlendi")
    }

    // Tüm verileri yeniden yükle
    function refreshAllData() {
        clearMeasurements()
        loadMeasurements()
        console.log("Tüm veriler yeniden yüklendi")
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0e14"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Başlık kısmı
            Text {
                text: "Ölçüm Verileri (Database)"
                font.pixelSize: 24
                font.family: "Consolas, monospace"
                color: "#58a6ff"
                Layout.alignment: Qt.AlignHCenter
            }

            // Üst kısım - Bilgiler ve butonlar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Toplam Kayıt: " + (mainWindow.getTotalMeasurementCount ? mainWindow.getTotalMeasurementCount() : "N/A") + " (Tabloda: " + measurements.length + ")"
                    font.family: "Consolas, monospace"
                    font.pointSize: 10
                    font.bold: true
                    color: "#58a6ff"
                }

                // Otomatik güncelleme durumu
                Text {
                    text: "Otomatik Güncelleme: " + (autoUpdateTimer.running ? "AÇIK" : "KAPALI")
                    font.family: "Consolas, monospace"
                    font.pointSize: 9
                    color: autoUpdateTimer.running ? "#7ee787" : "#ff6b6b"
                }

                Item { Layout.fillWidth: true } // Spacer

                // Otomatik güncelleme toggle butonu
                Button {
                    text: autoUpdateTimer.running ? "Dur" : "Başlat"
                    width: 80
                    height: 30
                    background: Rectangle {
                        color: parent.pressed ? "#238636" : (parent.hovered ? "#2d333b" : "#21262d")
                        radius: 6
                        border.color: autoUpdateTimer.running ? "#ff6b6b" : "#7ee787"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        font.family: "Consolas, monospace"
                        font.pointSize: 9
                        color: autoUpdateTimer.running ? "#ff6b6b" : "#7ee787"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (autoUpdateTimer.running) {
                            autoUpdateTimer.stop()
                            console.log("Otomatik güncelleme durduruldu")
                        } else {
                            autoUpdateTimer.start()
                            console.log("Otomatik güncelleme başlatıldı")
                        }
                    }
                }

                Button {
                    text: "Yenile"
                    width: 80
                    height: 30
                    background: Rectangle {
                        color: parent.pressed ? "#238636" : (parent.hovered ? "#2d333b" : "#21262d")
                        radius: 6
                        border.color: "#58a6ff"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        font.family: "Consolas, monospace"
                        font.pointSize: 9
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        refreshAllData()
                    }
                }

                Button {
                    text: "Temizle"
                    width: 80
                    height: 30
                    background: Rectangle {
                        color: parent.pressed ? "#da3633" : (parent.hovered ? "#2d333b" : "#21262d")
                        radius: 6
                        border.color: "#ff6b6b"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        font.family: "Consolas, monospace"
                        font.pointSize: 9
                        color: "#ff6b6b"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (mainWindow.clearDatabase) {
                            mainWindow.clearDatabase()
                            console.log("Database temizlendi")
                        }
                        clearMeasurements()
                    }
                }
            }

            // Tablo başlıkları
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#21262d"
                border.color: "#58a6ff"
                border.width: 1
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5

                    Text {
                        Layout.preferredWidth: 50
                        text: "ID"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 150
                        text: "Tarih/Saat"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 100
                        text: "SpO2 (%)"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 100
                        text: "Pulse (bpm)"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Tablo veriler
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                background: Rectangle {
                    color: "#0a0e14"
                    border.color: "#58a6ff"
                    border.width: 1
                    radius: 6
                }

                ListView {
                    id: measurementList
                    model: measurements
                    clip: true  // Performans için

                    delegate: Rectangle {
                        width: measurementList.width
                        height: 35
                        color: index % 2 === 0 ? "#161b22" : "#0d1117"
                        border.color: "#30363d"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5

                            Text {
                                Layout.preferredWidth: 50
                                text: modelData.id || (index + 1)
                                font.family: "Consolas, monospace"
                                color: "#f0f6fc"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.preferredWidth: 150
                                text: modelData.timestamp || "N/A"
                                font.family: "Consolas, monospace"
                                color: "#f0f6fc"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.preferredWidth: 100
                                text: modelData.spo2 || "N/A"
                                font.family: "Consolas, monospace"
                                horizontalAlignment: Text.AlignHCenter
                                color: {
                                    if (modelData.spo2 === "Geçersiz" || modelData.spo2 === "N/A") return "#ff6b6b"
                                    var value = parseInt(modelData.spo2)
                                    if (value < 95) return "#ff6b6b"
                                    else if (value < 98) return "#ffa500"
                                    else return "#7ee787"
                                }
                            }

                            Text {
                                Layout.preferredWidth: 100
                                text: modelData.pulse || "N/A"
                                font.family: "Consolas, monospace"
                                horizontalAlignment: Text.AlignHCenter
                                color: {
                                    if (modelData.pulse === "Geçersiz" || modelData.pulse === "N/A") return "#ff6b6b"
                                    var value = parseInt(modelData.pulse)
                                    if (value < 60 || value > 100) return "#ffa500"
                                    else return "#7ee787"
                                }
                            }
                        }
                    }
                }
            }

            // Durum bilgisi
            Text {
                text: measurements.length > 0 ? "Son güncelleme: " + new Date().toLocaleTimeString() : "Henüz veri yok"
                font.family: "Consolas, monospace"
                font.pointSize: 8
                color: "#7ee787"
                Layout.alignment: Qt.AlignHCenter
            }

            // Butonlar - Yan yana
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Geri dönüş butonu
                Button {
                    id: backButton
                    width: 200
                    height: 40
                    background: Rectangle {
                        color: backButton.pressed ? "#238636" : (backButton.hovered ? "#2d333b" : "#21262d")
                        radius: 6
                        border.color: "#58a6ff"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: "Ana Sayfaya Dön"
                        font.family: "Consolas, monospace"
                        font.pointSize: 11
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                    }
                    onClicked: {
                        console.log("Ana sayfaya dönülüyor - timer'lar durduruluyor")
                        // Timer'ları durdur
                        autoUpdateTimer.stop()
                        updateTimer.stop()
                        page2.navigateBack()
                    }
                }

                // Veri akışı başlat butonu
                Button {
                    width: 200
                    height: 35
                    background: Rectangle {
                        color: parent.pressed ? "#238636" : (parent.hovered ? "#2d333b" : "#21262d")
                        radius: 6
                        border.color: "#58a6ff"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: qsTr("Veri Akışını Başlat")
                        font.family: "Consolas, monospace"
                        font.pointSize: 10
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (!mainWindow.serialConnected) {
                            mainWindow.reconnectSerial()
                            if (typeof root !== 'undefined') {
                                root.isActive = true
                            }
                            console.log("Veri akışı başlatıldı.")
                        } else {
                            console.log("Veri akışı zaten aktif.")
                        }
                    }
                }
            }
        }
    }
}
