import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: main2Root
    anchors.fill: parent

    signal navigateBack()

    property var waveformDatabase: []
    property string currentWaveformImage: ""
    property int selectedIndex: -1
    property bool isRecording: false
    property int recordingDuration: 0
    property var recordingData: []
    property real currentSpo2: 0
    property real currentPulse: 0
    property bool valuesStarted: false
    property var waveformImages: []

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
            console.log("Veritabanından", measurements.length, "kayıt yüklendi")
            listModel.clear()

            for (var i = 0; i < measurements.length; i++) {
                var record = measurements[i]
                listModel.append({
                    index: i,
                    dbId: record.id,
                    timestamp: new Date(record.timestamp).getTime(),
                    spo2: parseFloat(record.spo2),
                    pulse: parseFloat(record.pulse),
                    ageGroup: "ADULT",
                    isNormalRange: parseFloat(record.spo2) >= 95 && parseFloat(record.pulse) >= 60 && parseFloat(record.pulse) <= 100,
                    duration: 10,
                    imageData: "",
                    recordingData: []
                })
            }
        } catch (e) {
            console.log("Veritabanı yükleme hatası:", e)
        }
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
                pulse: currentPulse,
                timestamp: new Date().getTime()
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
            currentSpo2 = baseSpo2 + (Math.random() - 0.5) * 4
            currentPulse = basePulse + (Math.random() - 0.5) * 20
            currentSpo2 = Math.max(90, Math.min(100, currentSpo2))
            currentPulse = Math.max(50, Math.min(120, currentPulse))
            if (currentWaveformImage === "") {
                currentWaveformImage = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
            }
        }
    }

    function setCurrentWaveformImage(imageData) {
        console.log("Waveform resmi ayarlandı, data uzunluğu:", imageData.length)
        currentWaveformImage = imageData
    }

    function updateCurrentValues(spo2, pulse) {
        currentSpo2 = spo2
        currentPulse = pulse
        console.log("Güncel değerler - SpO2:", spo2, "Pulse:", pulse)
    }

    function startRecording() {
        console.log("10 saniyelik kayıt başlatılıyor...")
        valuesStarted = true
        isRecording = true
        recordingDuration = 0
        recordingData = []
        recordingTimer.start()
    }

    function stopRecording() {
        console.log("Kayıt durduruldu.", recordingData.length, "veri noktası yakalandı")
        isRecording = false
        valuesStarted = false
        recordingTimer.stop()

        if (recordingData.length > 0) {
            var avgSpo2 = 0, avgPulse = 0
            for (var i = 0; i < recordingData.length; i++) {
                avgSpo2 += recordingData[i].spo2
                avgPulse += recordingData[i].pulse
            }
            avgSpo2 = (avgSpo2 / recordingData.length).toFixed(1)
            avgPulse = Math.round(avgPulse / recordingData.length)

            var waveformSnapshot = currentWaveformImage
            waveformImages.push({
                id: Date.now(),
                timestamp: new Date().getTime(),
                imageData: waveformSnapshot,
                spo2: avgSpo2,
                pulse: avgPulse
            })

            mainWindow.insertMeasurement(avgSpo2.toString(), avgPulse.toString())
            console.log("Yeni kayıt veritabanına eklendi - SpO2:", avgSpo2, "Pulse:", avgPulse)
        }
    }

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

                    Button {
                        width: 100; height: 35; enabled: !isRecording
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : (isRecording ? "#7d8590" : "#0969da")
                            radius: 6; border.color: isRecording ? "#7d8590" : "#58a6ff"; border.width: 1
                        }
                        contentItem: Text {
                            text: isRecording ? "KAYIT: " + Math.ceil((10000 - recordingDuration) / 1000) + "s" : "10s KAYDET"
                            font.family: "Consolas, monospace"; font.pointSize: 8; font.bold: true; color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: startRecording()
                    }

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
                        onClicked: mainWindow.clearDatabase()
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

            // Kare SpO2 ve Pulse Tabloları - Yan Yana
            Row {
                width: parent.width
                height: 120
                spacing: 15

                // SpO2 Kare Tablo
                Rectangle {
                    width: (parent.width - 15) / 2
                    height: 120
                    color: "#0d1117"
                    radius: 8
                    border.color: valuesStarted ? (currentSpo2 >= 95 ? "#7ee787" : "#f85149") : "#30363d"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "SpO₂"
                            font.family: "Consolas, monospace"
                            font.pointSize: 14
                            font.bold: true
                            color: "#58a6ff"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: valuesStarted ? currentSpo2.toFixed(1) + "%" : "--"
                            font.family: "Consolas, monospace"
                            font.pointSize: 28
                            font.bold: true
                            color: valuesStarted ? (currentSpo2 >= 95 ? "#7ee787" : "#ff7b72") : "#7d8590"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: valuesStarted ? (currentSpo2 >= 95 ? "NORMAL" : "DÜŞÜK") : "BEKLEMEDE"
                            font.family: "Consolas, monospace"
                            font.pointSize: 9
                            font.bold: true
                            color: valuesStarted ? (currentSpo2 >= 95 ? "#7ee787" : "#ff7b72") : "#7d8590"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Pulse Kare Tablo
                Rectangle {
                    width: (parent.width - 15) / 2
                    height: 120
                    color: "#0d1117"
                    radius: 8
                    border.color: valuesStarted ? "#ff7b72" : "#30363d"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "PULSE"
                            font.family: "Consolas, monospace"
                            font.pointSize: 14
                            font.bold: true
                            color: "#58a6ff"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: valuesStarted ? currentPulse.toFixed(0) : "--"
                            font.family: "Consolas, monospace"
                            font.pointSize: 28
                            font.bold: true
                            color: valuesStarted ? "#ff7b72" : "#7d8590"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: valuesStarted ? "BPM" : "BEKLEMEDE"
                            font.family: "Consolas, monospace"
                            font.pointSize: 9
                            font.bold: true
                            color: valuesStarted ? "#ff7b72" : "#7d8590"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // Kayıt Durumu
            Rectangle {
                width: parent.width; height: 40; color: "#0d1117"; radius: 8
                border.color: isRecording ? "#f85149" : "#30363d"
                border.width: isRecording ? 2 : 1

                Row {
                    anchors.centerIn: parent; spacing: 15

                    Text {
                        text: isRecording ? "KAYIT YAPILIYOR..." : "BEKLEMEDE"
                        font.family: "Consolas, monospace"; font.pointSize: 12; font.bold: true
                        color: isRecording ? "#f85149" : "#7d8590"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 150; height: 8; color: "#21262d"; radius: 4; visible: isRecording
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: parent.width * (recordingDuration / 10000)
                            height: parent.height; color: "#f85149"; radius: 4
                        }
                    }
                }
            }

            // Waveform
            Rectangle {
                width: parent.width; height: 150; color: "#0d1117"; radius: 8
                border.color: "#30363d"; border.width: 1; visible: currentWaveformImage !== ""

                Column {
                    anchors.fill: parent; anchors.margins: 8
                    Rectangle {
                        width: parent.width; height: 25; color: "#21262d"; radius: 4
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter; text: "CANLI WAVEFORM"
                            font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"
                        }
                    }
                    Rectangle {
                        width: parent.width; height: parent.height - 33; color: "#1a1a1a"; radius: 4
                        Image {
                            anchors.fill: parent; anchors.margins: 2; source: currentWaveformImage
                            fillMode: Image.PreserveAspectFit; smooth: true
                        }
                    }
                }
            }

            // Tablo Başlığı
            Rectangle {
                width: parent.width; height: 35; color: "#21262d"; radius: 4
                border.color: "#30363d"; border.width: 1

                Row {
                    anchors.fill: parent; anchors.margins: 8
                    Text { width: 100; text: "ZAMAN"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter }
                    Text { width: 60; text: "SpO₂"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 60; text: "PULSE"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 60; text: "SÜRE"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 80; text: "DURUM"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    Text { width: 40; text: "ID"; font.family: "Consolas, monospace"; font.pointSize: 9; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                }
            }

            // Veri Listesi
            Rectangle {
                width: parent.width
                height: parent.height - 470 - (currentWaveformImage !== "" ? 162 : 0)
                color: "#0d1117"; radius: 8; border.color: "#30363d"; border.width: 1

                ListView {
                    id: dataListView
                    anchors.fill: parent; anchors.margins: 5
                    model: ListModel { id: listModel }
                    clip: true; spacing: 2

                    delegate: Rectangle {
                        width: parent.width; height: 45
                        color: selectedIndex === index ? "#21262d" : (mouseArea.containsMouse ? "#1a1f26" : "transparent")
                        radius: 4; border.color: model.isNormalRange ? "#238636" : "#f85149"
                        border.width: selectedIndex === index ? 2 : 1

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: selectedIndex = (selectedIndex === index) ? -1 : index
                        }

                        Row {
                            anchors.fill: parent; anchors.margins: 8

                            Column {
                                width: 100; anchors.verticalCenter: parent.verticalCenter; spacing: 2
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
                                width: 60; text: model.spo2 + "%"; font.family: "Consolas, monospace"
                                font.pointSize: 11; font.bold: true; color: model.isNormalRange ? "#7ee787" : "#ff7b72"
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: 60; text: model.pulse; font.family: "Consolas, monospace"
                                font.pointSize: 11; font.bold: true; color: "#ff7b72"
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                width: 60; text: "10s"; font.family: "Consolas, monospace"
                                font.pointSize: 9; color: "#7d8590"
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }

                            Rectangle {
                                width: 70; height: 20; radius: 10
                                color: model.isNormalRange ? "#0f5132" : "#58151c"
                                border.color: model.isNormalRange ? "#7ee787" : "#ff7b72"; border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent; text: model.isNormalRange ? "NORMAL" : "KRİTİK"
                                    font.family: "Consolas, monospace"; font.pointSize: 7; font.bold: true
                                    color: model.isNormalRange ? "#7ee787" : "#ff7b72"
                                }
                            }

                            Text {
                                width: 40; text: "#" + (model.dbId || "0"); font.family: "Consolas, monospace"
                                font.pointSize: 8; color: "#7d8590"
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
                    text: "Veritabanında kayıt bulunamadı\n10 saniyelik ölçüm almak için 'KAYDET' butonuna basın"
                    font.family: "Consolas, monospace"; font.pointSize: 11; color: "#7d8590"
                    visible: listModel.count === 0; horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
