import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: main2Root
    anchors.fill: parent

    signal setWaveformDatabase(var db)
    signal navigateBack()

    property int selectedIndex: -1
    property bool isRecording: false
    property int recordingDuration: 0
    property var recordingData: []
    property real currentSpo2: 0
    property real currentPulse: 0
    property bool valuesStarted: false
    property bool showImageModal: false
    property string currentImageData: ""

    function loadMeasurementsWithImages() {
        try {
            var measurements = mainWindow.getMeasurements()
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
                    imageData: record.imageData || "",
                    isNormalRange: spo2Val >= 95 && pulseVal >= 60 && pulseVal <= 100
                })
            }
        } catch (e) {
            console.log("Veri yükleme hatası:", e)
        }
    }

    Component.onCompleted: {
        loadDatabaseRecords();
        valuesStarted = true;
    }

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
                    imageData: record.imageData || "",
                    isNormalRange: spo2Val >= 95 && pulseVal >= 60 && pulseVal <= 100
                })
            }
        } catch (e) {
            console.log("❌ Veritabanı yükleme hatası:", e)
        }
    }

    function showImagePreview(imageData) {
        currentImageData = imageData
        showImageModal = true
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

            mainWindow.insertMeasurement(avgSpo2.toString(), avgPulse.toString())
            console.log("💾 Kayıt veritabanına eklendi - SpO2:", avgSpo2, "Pulse:", avgPulse)

            loadDatabaseRecords()
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 15
        radius: 12
        color: "#0d1117"
        border.color: "#21262d"
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Enhanced Header
            Rectangle {
                width: parent.width
                height: 60
                color: "#161b22"
                radius: 10
                border.color: "#21262d"
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 9
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1f2937" }
                        GradientStop { position: 1.0; color: "#161b22" }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 15

                        Button {
                            width: 40; height: 40
                            background: Rectangle {
                                color: parent.pressed ? "#0969da" : (parent.hovered ? "#1f6feb" : "#21262d")
                                radius: 8; border.color: "#58a6ff"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            contentItem: Text {
                                text: "←"; font.family: "Segoe UI, Arial"; font.pointSize: 16
                                font.bold: true; color: "#58a6ff"
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: main2Root.navigateBack()
                        }

                        Text {
                            text: "📊 VERİ GEÇMİŞİ"; font.family: "Segoe UI, Arial"
                            font.pointSize: 14; font.bold: true; color: "#f0f6fc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 15

                        Button {
                            width: 90; height: 35
                            background: Rectangle {
                                color: parent.pressed ? "#da3633" : (parent.hovered ? "#f85149" : "transparent")
                                radius: 8; border.color: "#f85149"; border.width: 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            contentItem: Text {
                                text: "🗑️ TEMİZLE"; font.family: "Segoe UI, Arial"; font.pointSize: 9
                                font.bold: true; color: "#f85149"
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: mainWindow.clearMeasurements()
                        }

                        Column {
                            spacing: 3; anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.right: parent.right
                                text: Qt.formatDateTime(new Date(), "dd.MM.yyyy - hh:mm")
                                font.family: "Segoe UI, Arial"; font.pointSize: 10; color: "#8b949e"
                            }
                            Text {
                                anchors.right: parent.right; text: "💾 " + listModel.count + " kayıt"
                                font.family: "Segoe UI, Arial"; font.pointSize: 9; color: "#58a6ff"; font.bold: true
                            }
                        }
                    }
                }
            }

            // Enhanced Table Header
            Rectangle {
                width: parent.width; height: 35; color: "#161b22"; radius: 8
                border.color: "#21262d"; border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 7
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1f2937" }
                        GradientStop { position: 1.0; color: "#161b22" }
                    }

                    Row {
                        anchors.fill: parent; anchors.margins: 10
                        Text { width: 110; text: "📅 ZAMAN"; font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter }
                        Text { width: 70; text: "🫁 SpO₂"; font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                        Text { width: 70; text: "❤️ NABIZ"; font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                        Text { width: 80; text: "⚡ DURUM"; font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                        Text { width: 90; text: "📷 GÖRSEL"; font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                        Text { width: 50; text: "🆔 ID"; font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#58a6ff"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }

            // Enhanced Data Table
            Rectangle {
                width: parent.width
                height: parent.height - 110
                color: "#0d1117"; radius: 10; border.color: "#21262d"; border.width: 1

                ListView {
                    id: dataListView
                    anchors.fill: parent; anchors.margins: 8
                    model: ListModel { id: listModel }
                    clip: true; spacing: 3

                    delegate: Rectangle {
                        width: parent.width; height: 55
                        color: selectedIndex === index ? "#1f2937" : (mouseArea.containsMouse ? "#161b22" : "transparent")
                        radius: 8
                        border.color: model.isNormalRange ? "#238636" : "#da3633"
                        border.width: 1

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 7
                            color: "transparent"
                            border.color: model.isNormalRange ? "transparent" : "transparent"

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent; hoverEnabled: true
                                onClicked: selectedIndex = (selectedIndex === index) ? -1 : index
                            }

                            Row {
                                anchors.fill: parent; anchors.margins: 10; spacing: 8

                                Column {
                                    width: 110; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                                    Text {
                                        text: Qt.formatDateTime(new Date(model.timestamp), "dd.MM.yyyy")
                                        font.family: "Segoe UI, Arial"; font.pointSize: 8; color: "#8b949e"
                                    }
                                    Text {
                                        text: Qt.formatDateTime(new Date(model.timestamp), "hh:mm:ss")
                                        font.family: "Segoe UI, Arial"; font.pointSize: 10; font.bold: true; color: "#f0f6fc"
                                    }
                                }

                                Text {
                                    width: 70; text: model.spo2.toFixed(1) + "%"
                                    font.family: "Segoe UI, Arial"; font.pointSize: 12; font.bold: true
                                    color: model.isNormalRange ? "#7ee787" : "#ff7b72"
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    width: 70; text: model.pulse.toFixed(0) + " bpm"
                                    font.family: "Segoe UI, Arial"; font.pointSize: 12; font.bold: true; color: "#ffa657"
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                }

                                Rectangle {
                                    width: 70; height: 20; radius: 10; anchors.verticalCenter: parent.verticalCenter
                                    color: model.isNormalRange ? "#0f5132" : "#58151c"
                                    border.color: model.isNormalRange ? "#238636" : "#da3633"; border.width: 1

                                    Text {
                                        anchors.centerIn: parent; text: model.isNormalRange ? "✓ NORMAL" : "⚠ KRİTİK"
                                        font.family: "Segoe UI, Arial"; font.pointSize: 7; font.bold: true
                                        color: model.isNormalRange ? "#7ee787" : "#ff7b72"
                                    }
                                }

                                Row {
                                    width: 90; spacing: 5; anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 45; height: 35
                                        color: "#161b22"
                                        radius: 6
                                        border.color: model.imageData ? "#58a6ff" : "#30363d"
                                        border.width: 1

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 3
                                            source: model.imageData ? "data:image/png;base64," + model.imageData : ""
                                            fillMode: Image.PreserveAspectFit
                                            visible: model.imageData !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "📷"
                                            font.pointSize: 12
                                            color: "#30363d"
                                            visible: model.imageData === ""
                                        }
                                    }

                                    Button {
                                        width: 35; height: 35
                                        visible: model.imageData !== ""
                                        background: Rectangle {
                                            color: parent.pressed ? "#0969da" : (parent.hovered ? "#1f6feb" : "#21262d")
                                            radius: 6; border.color: "#58a6ff"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        contentItem: Text {
                                            text: "🔍"; font.pointSize: 10; color: "#58a6ff"
                                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: showImagePreview(model.imageData)
                                    }
                                }

                                Text {
                                    width: 50; text: "#" + model.dbId
                                    font.family: "Segoe UI, Arial"; font.pointSize: 8; color: "#8b949e"; font.bold: true
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true; policy: ScrollBar.AlwaysOn; width: 8
                        background: Rectangle { color: "#21262d"; radius: 4 }
                        contentItem: Rectangle { color: "#58a6ff"; radius: 4 }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "📊 Henüz kayıt bulunmuyor\n\n🏥 Ana sayfadan ölçüm yaparak\nveri geçmişinizi oluşturun"
                    font.family: "Segoe UI, Arial"; font.pointSize: 12; color: "#8b949e"
                    visible: listModel.count === 0; horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // Image Preview Modal
    Rectangle {
        id: imageModal
        anchors.fill: parent
        color: "black"
        opacity: showImageModal ? 0.95 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            onClicked: showImageModal = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.8, 400)
            height: Math.min(parent.height * 0.8, 400)
            color: "#161b22"
            radius: 15
            border.color: "#58a6ff"
            border.width: 2

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                Row {
                    width: parent.width
                    height: 40

                    Text {
                        text: "📷 Görsel Önizleme"
                        font.family: "Segoe UI, Arial"
                        font.pointSize: 14
                        font.bold: true
                        color: "#f0f6fc"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Button {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 35; height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#da3633" : (parent.hovered ? "#f85149" : "transparent")
                            radius: 8; border.color: "#f85149"; border.width: 1
                        }
                        contentItem: Text {
                            text: "✕"; font.pointSize: 12; font.bold: true; color: "#f85149"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: showImageModal = false
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - 50
                    color: "#0d1117"
                    radius: 10
                    border.color: "#21262d"
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        anchors.margins: 10
                        source: currentImageData ? "data:image/png;base64," + currentImageData : ""
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }
    }
}
