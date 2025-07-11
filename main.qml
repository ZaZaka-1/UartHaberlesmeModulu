import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    width: 480
    height: 700
    title: "SPO2 Monitor"
    color: "#0a0e14"

    property bool isActive: true
    property bool showMain2: false
    property bool showSettings: false  // ✅ Settings sayfası için property eklendi
    property string spo2Value: mainWindow ? mainWindow.spo2 : "98"
    property string pulseValue: mainWindow ? mainWindow.pulse : "72"
    property int spo2Numeric: parseInt(spo2Value) || 0
    property int pulseNumeric: parseInt(pulseValue) || 0

    // Debug için konsol çıktısı ekle
    Component.onCompleted: {
        console.log("SPO2 Monitor başlatıldı")
        console.log("mainWindow mevcut:", mainWindow ? "Evet" : "Hayır")
    }

    Connections {
        target: mainWindow
        function onNavigateBack() {
            root.showMain2 = false
            root.showSettings = false  // ✅ Settings'den geri dönüş
            root.isActive = true
        }
        function onSpo2Changed() {
            root.spo2Value = mainWindow.spo2
        }
        function onPulseChanged() {
            root.pulseValue = mainWindow.pulse
        }
        // ✅ Waveform verisi geldiğinde tetiklenir
        function onWaveformDataReceived(waveformValue) {
            waveformCanvas.addWaveformData(waveformValue)
        }
        function onWaveformSampleReceived() {
                waveformCanvas.addWaveformData(mainWindow.waveformSample)
            }
        function onSpo2PulseData(spo2, pulse) {
                root.spo2Value = spo2
                root.pulseValue = pulse
            }
        onRealTimeWaveformPoint: {
                waveformCanvas.addWaveformData(amplitude)
            }
    }

    // ✅ Main2 için Loader
    Loader {
        id: pageLoader
        anchors.fill: parent
        source: root.showMain2 ? "main2.qml" : ""
        active: root.showMain2
        onLoaded: {
            if (item) {
                item.navigateBack.connect(function() {
                    root.showMain2 = false
                    root.isActive = true
                })
            }
        }
    }

    // Settings için Loader
    Loader {
        id: settingsLoader
        anchors.fill: parent
        source: root.showSettings ? "settings.qml" : ""
        active: root.showSettings

        onActiveChanged: {
            console.log("settingsLoader aktif durumu değişti:", active)
        }

        onSourceChanged: {
            console.log("settingsLoader source değişti:", source)
        }

        onStatusChanged: {
            console.log("settingsLoader status değişti:", status)
            if (status === Loader.Error) {
                console.log("❌ Settings dosyası yüklenemedi!")
            } else if (status === Loader.Ready) {
                console.log("✅ Settings dosyası başarıyla yüklendi")
            }
        }

        onLoaded: {
            console.log("Settings sayfası yüklendi")
            if (item) {
                console.log("Settings item mevcut")
                item.navigateBack.connect(function() {
                    console.log("Settings'den geri dönüş sinyali alındı")
                    root.showSettings = false
                    root.isActive = true
                })
            } else {
                console.log("❌ Settings item null!")
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: !root.showMain2 && !root.showSettings  // ✅ Her iki sayfa için görünürlük kontrolü

        Rectangle {
            anchors.fill: parent
            anchors.margins: 15
            radius: 10
            color: "#161b22"
            border.color: "#30363d"
            border.width: 2

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                // Başlık
                Rectangle {
                    width: parent.width
                    height: 55
                    color: "#21262d"
                    radius: 8
                    border.color: "#30363d"
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PULSE OXIMETRY MONITOR"
                        font.family: "Consolas, monospace"
                        font.pointSize: 12
                        font.bold: true
                        color: "#58a6ff"
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(new Date(), "hh:mm:ss")
                        font.family: "Consolas, monospace"
                        font.pointSize: 11
                        color: "#7d8590"

                        Timer {
                            interval: 1000
                            running: root.isActive
                            repeat: true
                            onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                        }
                    }
                }

                // SPO2 ve Pulse Paneli
                Row {
                    width: parent.width
                    height: 140
                    spacing: 12

                    // SPO2 Panel
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: parent.height
                        color: "#21262d"
                        radius: 8
                        border.color: root.spo2Numeric >= 95 ? "#238636" : "#f85149"
                        border.width: 2

                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                text: "SpO₂"
                                font.family: "Consolas, monospace"
                                font.pointSize: 14
                                font.bold: true
                                color: "#58a6ff"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Rectangle {
                                width: 100
                                height: 60
                                color: "#0d1117"
                                radius: 6
                                border.color: "#30363d"
                                border.width: 1
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: root.spo2Value + "%"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 28
                                    font.bold: true
                                    color: root.spo2Numeric >= 95 ? "#7ee787" : "#ff7b72"
                                }
                            }
                        }
                    }

                    // Pulse Panel
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: parent.height
                        color: "#21262d"
                        radius: 8
                        border.color: "#da3633"
                        border.width: 2

                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                text: "PULSE"
                                font.family: "Consolas, monospace"
                                font.pointSize: 14
                                font.bold: true
                                color: "#ff7b72"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Rectangle {
                                width: 100
                                height: 60
                                color: "#0d1117"
                                radius: 6
                                border.color: "#30363d"
                                border.width: 1
                                anchors.horizontalCenter: parent.horizontalCenter

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: root.pulseValue
                                        font.family: "Consolas, monospace"
                                        font.pointSize: 24
                                        font.bold: true
                                        color: "#ff7b72"
                                    }

                                    Text {
                                        text: "♥"
                                        font.pointSize: 16
                                        color: "#ff7b72"
                                        anchors.verticalCenter: parent.verticalCenter

                                        SequentialAnimation on scale {
                                            loops: Animation.Infinite
                                            running: root.pulseNumeric > 0 && root.isActive
                                            PropertyAnimation {
                                                from: 1.0; to: 1.5;
                                                duration: 200
                                            }
                                            PropertyAnimation {
                                                from: 1.5; to: 1.0;
                                                duration: 200
                                            }
                                            PauseAnimation {
                                                duration: 800
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "BPM"
                                font.family: "Consolas, monospace"
                                font.pointSize: 9
                                color: "#7d8590"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Waveform Panel - Canlı Veri ile Güncellendi
                Rectangle {
                    width: parent.width
                    height: 200
                    color: "#0d1117"
                    radius: 8
                    border.color: "#30363d"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8

                        Rectangle {
                            width: parent.width
                            height: 30
                            color: "#21262d"
                            radius: 4

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 15

                                Text {
                                    text: "SpO₂ PLETHYSMOGRAPH"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    font.bold: true
                                    color: "#58a6ff"
                                }

                                // Veri alma durumu göstergesi
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: waveformCanvas.isReceivingData ? "#7ee787" : "#ff7b72"

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: waveformCanvas.isReceivingData
                                        PropertyAnimation { from: 1.0; to: 0.3; duration: 500 }
                                        PropertyAnimation { from: 0.3; to: 1.0; duration: 500 }
                                    }
                                }

                                Text {
                                    text: waveformCanvas.isReceivingData ? "LIVE" : "NO DATA"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 8
                                    color: waveformCanvas.isReceivingData ? "#7ee787" : "#ff7b72"
                                }
                            }
                        }

                        // Canvas elemanı
                        Canvas {
                            id: waveformCanvas
                            width: parent.width
                            height: parent.height - 38

                            property var waveformData: []
                            property int maxPoints: 500
                            property bool isReceivingData: false
                            property double lastDataTime: 0

                            // Veri ekleme fonksiyonu
                            function addWaveformData(value) {
                                // Değeri normalize et (0-1 arası)
                                var normalizedValue = Math.max(0, Math.min(1, value / 255.0))

                                // Veriyi diziye ekle
                                waveformData.push(normalizedValue)

                                // Maksimum nokta sayısını aşma kontrolü
                                if (waveformData.length > maxPoints) {
                                    waveformData.shift() // İlk elemanı sil
                                }

                               /* // Veri alma durumunu güncelle
                                isReceivingData = true
                                lastDataTime = Date.now()

                                console.log("Waveform dizisi uzunluğu:", waveformData.length)
                               */

                                // Canvas'ı yeniden çiz
                                requestPaint()
                            }

                            onPaint: {
                                console.log("Canvas yeniden çiziliyor, veri sayısı:", waveformData.length)

                                var ctx = getContext("2d");
                                if (!ctx) {
                                    console.log("Canvas context alınamadı!")
                                    return
                                }

                                ctx.clearRect(0, 0, width, height);

                                // Arka plan
                                ctx.fillStyle = "#0d1117";
                                ctx.fillRect(0, 0, width, height);

                                // Grid çizgileri
                                ctx.strokeStyle = "#30363d";
                                ctx.lineWidth = 0.5;
                                ctx.setLineDash([2, 2]);

                                // Yatay grid çizgileri
                                for (var i = 0; i <= 4; i++) {
                                    var y = (height / 4) * i;
                                    ctx.beginPath();
                                    ctx.moveTo(0, y);
                                    ctx.lineTo(width, y);
                                    ctx.stroke();
                                }

                                // Dikey grid çizgileri
                                for (var j = 0; j <= 8; j++) {
                                    var x = (width / 8) * j;
                                    ctx.beginPath();
                                    ctx.moveTo(x, 0);
                                    ctx.lineTo(x, height);
                                    ctx.stroke();
                                }

                                ctx.setLineDash([]);

                                // Waveform çizimi
                                if (waveformData.length > 1) {
                                    console.log("Waveform çiziliyor, nokta sayısı:", waveformData.length);

                                    // Çizim ayarları
                                    ctx.strokeStyle = "#58a6ff"; // Dalga rengi
                                    ctx.lineWidth = 2;           // Çizgi kalınlığı
                                    ctx.beginPath();             // Yeni çizim başlat

                                    // X ekseni adım aralığı ve başlangıç noktası
                                    const stepX = width / (maxPoints - 1);
                                    const startX = width - (waveformData.length * stepX);

                                    // Tüm veri noktaları üzerinden geç
                                    for (let k = 0; k < waveformData.length; k++) {
                                        const x = startX + (k * stepX);
                                        const y = height - (waveformData[k] * height * 0.8) - (height * 0.1);

                                        if (k === 0) {
                                            ctx.moveTo(x, y); // İlk noktaya git
                                        } else {
                                            ctx.lineTo(x, y); // Çizgiyi diğer noktalara uzat
                                        }
                                    }

                                    ctx.stroke(); // Çizimi tamamla
                                    console.log("Waveform çizimi tamamlandı.");
                                } else {
                                    console.log("Yetersiz veri noktası.");
                                }


                                // Veri yok durumunda bilgi metni
                                if (waveformData.length === 0 || !isReceivingData) {
                                    ctx.fillStyle = "#7d8590";
                                    ctx.font = "12px Consolas, monospace";
                                    ctx.textAlign = "center";
                                    ctx.fillText("Waiting for waveform data...", width/2, height/2);
                                }
                            }

                            // Veri alma durumunu kontrol et
                            Timer {
                                interval: 3000 // 3 saniye (daha uzun süre)
                                running: true
                                repeat: true
                                onTriggered: {
                                    var timeSinceLastData = Date.now() - waveformCanvas.lastDataTime
                                    if (timeSinceLastData > 3000) {
                                        console.log("Veri alma zaman aşımı:", timeSinceLastData)
                                        waveformCanvas.isReceivingData = false
                                        waveformCanvas.requestPaint()
                                    }
                                }
                            }

                            // Test butonu için timer
                            Timer {
                                id: testTimer
                                interval: 100
                                running: false
                                repeat: true
                                onTriggered: {
                                    var testValue = Math.sin(Date.now() * 0.01) * 127 + 128; // 0-255 arası
                                    waveformCanvas.addWaveformData(testValue)
                                }
                            }
                        }
                    }
                }

                // Status Panel
                Rectangle {
                    width: parent.width
                    height: 60
                    color: "#21262d"
                    radius: 8
                    border.color: "#30363d"
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 15

                        Text {
                            text: "STATUS:"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#7d8590"
                        }

                        Rectangle {
                            width: 80
                            height: 22
                            radius: 11
                            color: root.spo2Numeric >= 95 ? "#0f5132" : "#58151c"
                            border.color: root.spo2Numeric >= 95 ? "#7ee787" : "#ff7b72"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: root.spo2Numeric >= 95 ? "NORMAL" : "CRITICAL"
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                font.bold: true
                                color: root.spo2Numeric >= 95 ? "#7ee787" : "#ff7b72"
                            }
                        }

                        Text {
                            text: "WAVEFORM:"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#7d8590"
                        }

                        Rectangle {
                            width: 60
                            height: 22
                            radius: 11
                            color: waveformCanvas.isReceivingData ? "#0f5132" : "#58151c"
                            border.color: waveformCanvas.isReceivingData ? "#7ee787" : "#ff7b72"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: waveformCanvas.isReceivingData ? "LIVE" : "OFF"
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                font.bold: true
                                color: waveformCanvas.isReceivingData ? "#7ee787" : "#ff7b72"
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Button {
                        width: 120
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : "#21262d"
                            radius: 6
                            border.color: "#58a6ff"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: "Başlat"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (mainWindow && !mainWindow.serialConnected) {
                                mainWindow.reconnectSerial()
                                root.isActive = true
                                // Waveform verisini temizle
                                waveformCanvas.waveformData = []
                                waveformCanvas.requestPaint()
                            }
                        }
                    }

                    Button {
                        width: 120
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#2563eb" : "#21262d"
                            radius: 6
                            border.color: "#58a6ff"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: "Veri Tablosu"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (mainWindow) {
                                mainWindow.stopDataStream()
                            }
                            root.isActive = false
                            root.showMain2 = true
                        }
                    }

                    Button {
                        width: 120
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#7c3aed" : "#21262d"
                            radius: 6
                            border.color: "#58a6ff"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: "Ayarlar"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            console.log("Settings butonu tıklandı!")
                            console.log("Önceki showSettings değeri:", root.showSettings)
                            root.showSettings = true
                            console.log("Yeni showSettings değeri:", root.showSettings)
                            console.log("settingsLoader aktif mi:", settingsLoader.active)
                            console.log("settingsLoader source:", settingsLoader.source)
                        }
                    }
                }
            }
        }
    }
}
