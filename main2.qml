import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: main2Root
    anchors.fill: parent

    signal setWaveformDatabase(var db)
    signal navigateBack()

    property int selectedIndex: -1
    property bool isRecording: false
    property bool showWaveformPage: false
    property var waveformImages: []
    property string currentWaveformImage: ""
    property bool isCapturingWaveform: false
    property int waveformCaptureDuration: 0
    property int recordingDuration: 0
    property var recordingData: []
    property real currentSpo2: 0
    property real currentPulse: 0
    property bool valuesStarted: false

    Component.onCompleted: loadDatabaseRecords()

    Connections {
        target: mainWindow
        function onMeasurementAdded() {
            loadDatabaseRecords()
        }
    }

    function loadDatabaseRecords() {
        try {
            var measurements = mainWindow.getMeasurements()
            console.log("✅ Veritabanından", measurements.length, "kayıt yüklendi")
            listModel.clear()

            for (var i = 0; i < measurements.length; i++) {
                var record = measurements[i]
                var spo2Val = parseFloat(record.spo2)
                var pulseVal = parseFloat(record.pulse)

                listModel.append({
                    index: i,
                    dbId: record.id,
                    timestamp: new Date(record.timestamp).getTime(),
                    spo2: spo2Val,
                    pulse: pulseVal,
                    isNormalRange: spo2Val >= 95 && pulseVal >= 60 && pulseVal <= 100
                })
            }
            console.log("📊 ListModel'e", listModel.count, "kayıt eklendi")
        } catch (e) {
            console.log("❌ Veritabanı yükleme hatası:", e)
        }
    }

    function setCurrentWaveformImage(imageData) {
        currentWaveformImage = imageData

        var newWaveform = {
            id: Date.now(),
            timestamp: new Date().getTime(),
            imageData: currentWaveformImage,
            spo2: currentSpo2.toFixed(1),
            pulse: currentPulse.toFixed(0)
        }
        waveformImages.push(newWaveform)
        console.log("📊 Waveform kaydedildi, toplam:", waveformImages.length)
    }

    Timer {
        id: recordingTimer
        interval: 100
        running: isRecording
        repeat: true
        onTriggered: {
            recordingDuration += 100
            recordingData.push({
                time: recordingDuration,
                spo2: currentSpo2,
                pulse: currentPulse
            })
            if (recordingDuration >= 10000) stopRecording()
        }
    }

    Timer {
        id: testDataTimer
        interval: 500
        running: valuesStarted
        repeat: true
        onTriggered: {
            var baseSpo2 = 97, basePulse = 75
            currentSpo2 = Math.max(90, Math.min(100, baseSpo2 + (Math.random() - 0.5) * 4))
            currentPulse = Math.max(50, Math.min(120, basePulse + (Math.random() - 0.5) * 20))

            // Test waveform image oluştur
            if (currentWaveformImage === "") {
                currentWaveformImage = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
            }
        }
    }

    // Waveform Sayfası
    Rectangle {
        anchors.fill: parent
        anchors.margins: 15
        radius: 10
        color: "#161b22"
        border.color: "#30363d"
        border.width: 2
        visible: showWaveformPage

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            // Waveform Sayfası Header
            Rectangle {
                width: parent.width
                height: 55
                color: "#21262d"
                radius: 8
                border.color: "#30363d"
                border.width: 1

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 15

                    Button {
                        width: 35; height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : "transparent"
                            radius: 6; border.color: "#58a6ff"; border.width: 1
                        }
                        contentItem: Text {
                            text: "←"; font.family: "Consolas, monospace"; font.pointSize: 16
                            font.bold: true; color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: showWaveformPage = false
                    }

                    Text {
                        text: "WAVEFORM GÖRÜNTÜLERİ"; font.family: "Consolas, monospace"
                        font.pointSize: 12; font.bold: true; color: "#58a6ff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Button {
                        width: 120; height: 35; enabled: !isCapturingWaveform
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : (isCapturingWaveform ? "#7d8590" : "#0969da")
                            radius: 6; border.color: isCapturingWaveform ? "#7d8590" : "#58a6ff"; border.width: 1
                        }
                        contentItem: Text {
                            text: isCapturingWaveform ? "YAKALANIYOR: " + Math.ceil((5000 - waveformCaptureDuration) / 1000) + "s" : "WAVEFORM EKLE"
                            font.family: "Consolas, monospace"; font.pointSize: 8; font.bold: true; color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            console.log("🟢 WAVEFORM EKLE butonuna basıldı");

                            // Eğer yakalama yapılmıyorsa, yakalamayı başlat
                            if (!isCapturingWaveform) {
                                startWaveformCapture();
                            }
                        }
                    }

                    Column {
                        spacing: 2; anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.right: parent.right
                            text: Qt.formatDateTime(new Date(), "dd.MM.yyyy hh:mm")
                            font.family: "Consolas, monospace"; font.pointSize: 10; color: "#7d8590"
                        }
                        Text {
                            anchors.right: parent.right; text: waveformImages.length + " Waveform"
                            font.family: "Consolas, monospace"; font.pointSize: 8; color: "#58a6ff"
                        }
                    }
                }
            }

            // Yakalama Durumu
            Rectangle {
                width: parent.width; height: 35; color: "#0d1117"; radius: 8
                border.color: isCapturingWaveform ? "#7ee787" : "#30363d"; border.width: isCapturingWaveform ? 2 : 1

                Row {
                    anchors.centerIn: parent; spacing: 15
                    Text {
                        text: isCapturingWaveform ? "WAVEFORM YAKALANIYOR..." : "BEKLEMEDE"
                        font.family: "Consolas, monospace"; font.pointSize: 11; font.bold: true
                        color: isCapturingWaveform ? "#7ee787" : "#7d8590"
                    }
                    Rectangle {
                        width: 120; height: 6; color: "#21262d"; radius: 3; visible: isCapturingWaveform
                        Rectangle {
                            width: parent.width * (waveformCaptureDuration / 5000)
                            height: parent.height; color: "#7ee787"; radius: 3
                        }
                    }
                }
            }

            // Waveform Tablosu
            Rectangle {
                width: parent.width
                height: parent.height - 142
                color: "#0d1117"; radius: 8; border.color: "#30363d"; border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    // Tablo Başlığı
                    Rectangle {
                        width: parent.width; height: 30; color: "#21262d"; radius: 4
                        border.color: "#30363d"; border.width: 1

                        Row {
                            anchors.fill: parent; anchors.margins: 8
                            Text { width: 150; text: "ZAMAN"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter }
                            Text { width: 80; text: "SpO₂"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                            Text { width: 80; text: "PULSE"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                            Text { width: 200; text: "WAVEFORM"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    // Waveform Listesi
                    ListView {
                        width: parent.width
                        height: parent.height - 35
                        model: waveformImages.length
                        clip: true
                        spacing: 5

                        delegate: Rectangle {
                            width: parent.width; height: 80
                            color: "#1a1f26"; radius: 6; border.color: "#30363d"; border.width: 1

                            Row {
                                anchors.fill: parent; anchors.margins: 10; spacing: 10

                                Column {
                                    width: 150; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                    Text {
                                        text: Qt.formatDateTime(new Date(waveformImages[index].timestamp), "dd.MM.yyyy")
                                        font.family: "Consolas, monospace"; font.pointSize: 8; color: "#e6edf3"
                                    }
                                    Text {
                                        text: Qt.formatDateTime(new Date(waveformImages[index].timestamp), "hh:mm:ss")
                                        font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"
                                    }
                                }

                                Text {
                                    width: 80; text: waveformImages[index].spo2 + "%"
                                    font.family: "Consolas, monospace"; font.pointSize: 11; font.bold: true; color: "#7ee787"
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    width: 80; text: waveformImages[index].pulse
                                    font.family: "Consolas, monospace"; font.pointSize: 11; font.bold: true; color: "#ff7b72"
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                }

                                Rectangle {
                                    width: 200; height: 60; color: "#0d1117"; radius: 4; border.color: "#58a6ff"; border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.fill: parent; anchors.margins: 2
                                        source: waveformImages[index].imageData
                                        fillMode: Image.PreserveAspectFit; smooth: true
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true; policy: ScrollBar.AlwaysOn
                            background: Rectangle { color: "#21262d"; radius: 6 }
                            contentItem: Rectangle { color: "#58a6ff"; radius: 6 }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "📸 Henüz waveform görüntüsü yok\n🔴 'WAVEFORM EKLE' butonuna basarak 5 saniyelik görüntü alın"
                        font.family: "Consolas, monospace"; font.pointSize: 11; color: "#7d8590"
                        visible: waveformImages.length === 0; horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    Timer {
        id: waveformCaptureTimer
        interval: 100
        running: isCapturingWaveform
        repeat: true
        onTriggered: {
            waveformCaptureDuration += 100
            if (waveformCaptureDuration >= 5000) {
                stopWaveformCapture()
            }
        }
    }

    function startRecording() {
        console.log("🔴 10 saniyelik kayıt başlatılıyor...")
        valuesStarted = true
        isRecording = true
        recordingDuration = 0
        recordingData = []
        testDataTimer.start()
        recordingTimer.start()
    }

    function stopRecording() {
        console.log("⏹️ Kayıt durduruldu -", recordingData.length, "veri noktası")
        isRecording = false
        valuesStarted = false
        testDataTimer.stop()
        recordingTimer.stop()

        if (recordingData.length > 0) {
            var avgSpo2 = 0, avgPulse = 0
            for (var i = 0; i < recordingData.length; i++) {
                avgSpo2 += recordingData[i].spo2
                avgPulse += recordingData[i].pulse
            }
            avgSpo2 = (avgSpo2 / recordingData.length).toFixed(1)
            avgPulse = Math.round(avgPulse / recordingData.length)

            // Veritabanına kaydet
            mainWindow.insertMeasurement(avgSpo2.toString(), avgPulse.toString())
            console.log("💾 Kayıt veritabanına eklendi - SpO2:", avgSpo2, "Pulse:", avgPulse)

            // Tabloyu hemen güncelle
            loadDatabaseRecords()
        }
    }

    function stopWaveformCapture() {
        console.log("📸 Waveform yakalama tamamlandı")
        isCapturingWaveform = false
        valuesStarted = false
        testDataTimer.stop()
        waveformCaptureTimer.stop()

        // Waveform resmini kaydet
        var newWaveform = {
            id: Date.now(),
            timestamp: new Date().getTime(),
            imageData: currentWaveformImage,
            spo2: currentSpo2.toFixed(1),
            pulse: currentPulse.toFixed(0)
        }
        waveformImages.push(newWaveform)
        console.log("📊 Waveform kaydedildi, toplam:", waveformImages.length)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 15
        radius: 10
        color: "#161b22"
        border.color: "#30363d"
        border.width: 2
        visible: !showWaveformPage

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            // Header
            Rectangle {
                width: parent.width
                height: 55
                color: "#21262d"
                radius: 8
                border.color: "#30363d"
                border.width: 1

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 15

                    Button {
                        width: 35; height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : "transparent"
                            radius: 6; border.color: "#58a6ff"; border.width: 1
                        }
                        contentItem: Text {
                            text: "←"; font.family: "Consolas, monospace"; font.pointSize: 16
                            font.bold: true; color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: main2Root.navigateBack()
                    }

                    Text {
                        text: "VERİ GEÇMİŞİ (SQLite)"; font.family: "Consolas, monospace"
                        font.pointSize: 12; font.bold: true; color: "#58a6ff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // 10 SANIYE KAYDET BUTONU KALDIRILDI

                    Button {
                        width: 80; height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#f85149" : "transparent"
                            radius: 6; border.color: "#f85149"; border.width: 1
                        }
                        contentItem: Text {
                            text: "TEMİZLE"; font.family: "Consolas, monospace"; font.pointSize: 8
                            font.bold: true; color: "#f85149"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: mainWindow.clearMeasurements()
                    }

                    Button {
                        width: 100; height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : "transparent"
                            radius: 6; border.color: "#7ee787"; border.width: 1
                        }
                        contentItem: Text {
                            text: "WAVEFORM"; font.family: "Consolas, monospace"; font.pointSize: 8
                            font.bold: true; color: "#7ee787"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: showWaveformPage = true
                    }

                    Column {
                        spacing: 2; anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.right: parent.right
                            text: Qt.formatDateTime(new Date(), "dd.MM.yyyy hh:mm")
                            font.family: "Consolas, monospace"; font.pointSize: 10; color: "#7d8590"
                        }
                        Text {
                            anchors.right: parent.right; text: listModel.count + " DB kayıt"
                            font.family: "Consolas, monospace"; font.pointSize: 8; color: "#58a6ff"
                        }
                    }
                }
            }



            // Kayıt Durumu - KALDIRILDI (10 saniye kaydet butonu ile birlikte)

            // Tablo Başlığı
            Rectangle {
                width: parent.width; height: 30; color: "#21262d"; radius: 4
                border.color: "#30363d"; border.width: 1

                Row {
                    anchors.fill: parent; anchors.margins: 8
                    Text { width: 120; text: "ZAMAN"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter }
                    Text { width: 70; text: "SpO₂"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 70; text: "PULSE"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 80; text: "DURUM"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 50; text: "ID"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                }
            }

            // Veri Tablosu (Daha da büyütüldü - kayıt durumu alanı da kaldırıldı)
            Rectangle {
                width: parent.width
                height: parent.height - 100  // Kayıt durumu alanı da kaldırıldığı için daha büyük
                color: "#0d1117"; radius: 8; border.color: "#30363d"; border.width: 1

                ListView {
                    id: dataListView
                    anchors.fill: parent; anchors.margins: 5
                    model: ListModel { id: listModel }
                    clip: true; spacing: 2

                    delegate: Rectangle {
                        width: parent.width; height: 40
                        color: selectedIndex === index ? "#21262d" : (mouseArea.containsMouse ? "#1a1f26" : "transparent")
                        radius: 4; border.color: model.isNormalRange ? "#238636" : "#f85149"; border.width: 1

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: selectedIndex = (selectedIndex === index) ? -1 : index
                        }

                        Row {
                            anchors.fill: parent; anchors.margins: 8

                            Column {
                                width: 120; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                                Text {
                                    text: Qt.formatDateTime(new Date(model.timestamp), "dd.MM.yyyy")
                                    font.family: "Consolas, monospace"; font.pointSize: 8; color: "#e6edf3"
                                }
                                Text {
                                    text: Qt.formatDateTime(new Date(model.timestamp), "hh:mm:ss")
                                    font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"
                                }
                            }

                            Text {
                                width: 70; text: model.spo2.toFixed(1) + "%"
                                font.family: "Consolas, monospace"; font.pointSize: 11; font.bold: true
                                color: model.isNormalRange ? "#7ee787" : "#ff7b72"
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: 70; text: model.pulse.toFixed(0)
                                font.family: "Consolas, monospace"; font.pointSize: 11; font.bold: true; color: "#ff7b72"
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }

                            Rectangle {
                                width: 70; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
                                color: model.isNormalRange ? "#0f5132" : "#58151c"
                                border.color: model.isNormalRange ? "#7ee787" : "#ff7b72"; border.width: 1

                                Text {
                                    anchors.centerIn: parent; text: model.isNormalRange ? "NORMAL" : "KRİTİK"
                                    font.family: "Consolas, monospace"; font.pointSize: 7; font.bold: true
                                    color: model.isNormalRange ? "#7ee787" : "#ff7b72"
                                }
                            }

                            Text {
                                width: 50; text: "#" + model.dbId
                                font.family: "Consolas, monospace"; font.pointSize: 8; color: "#7d8590"
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true; policy: ScrollBar.AlwaysOn
                        background: Rectangle { color: "#21262d"; radius: 6 }
                        contentItem: Rectangle { color: "#58a6ff"; radius: 6 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "📊 Veritabanında kayıt bulunamadı\n📱 Ana sayfadaki kameradan ölçüm yapın"
                    font.family: "Consolas, monospace"; font.pointSize: 11; color: "#7d8590"
                    visible: listModel.count === 0; horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
