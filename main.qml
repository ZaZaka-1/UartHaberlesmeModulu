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
    property bool showSettings: false
    property string spo2Value: mainWindow ? mainWindow.spo2 : "98"
    property string pulseValue: mainWindow ? mainWindow.pulse : "72"
    property int spo2Numeric: parseInt(spo2Value) || 0
    property int pulseNumeric: parseInt(pulseValue) || 0

    property string currentAgeGroup: "Adult"
    property int normalMinSpo2: 95
    property int normalMaxSpo2: 100
    property bool isInNormalRange: spo2Numeric >= normalMinSpo2 && spo2Numeric <= normalMaxSpo2
    property bool showAlert: false
    property string alertMessage: ""
    property color alertColor: "#ff7b72"

    // Waveform database için özellikler
    property var waveformDatabase: []
    property var currentWaveformSession: []
    property int maxDatabaseSize: 100 // Maksimum kaydedilecek session sayısı
    property int sessionDuration: 10000 // 10 saniye (ms)

    function updateNormalRanges() {
        switch(currentAgeGroup) {
            case "Adult": normalMinSpo2 = 95; normalMaxSpo2 = 100; break
            case "Newborn": normalMinSpo2 = 90; normalMaxSpo2 = 94; break
            case "Pediatric": normalMinSpo2 = 94; normalMaxSpo2 = 100; break
            default: normalMinSpo2 = 95; normalMaxSpo2 = 100
        }
        checkAlert()
    }

    function checkAlert() {
        isInNormalRange = spo2Numeric >= normalMinSpo2 && spo2Numeric <= normalMaxSpo2
        if (!isInNormalRange && spo2Numeric > 0) {
            showAlert = true
            if (spo2Numeric < normalMinSpo2) {
                alertMessage = "SPO2 DÜŞÜK! (" + spo2Numeric + "% < " + normalMinSpo2 + "%)"
                alertColor = "#ff7b72"
            } else {
                alertMessage = "SPO2 YÜKSEK! (" + spo2Numeric + "% > " + normalMaxSpo2 + "%)"
                alertColor = "#ffa500"
            }
            if (mainWindow && mainWindow.playAlertSound) mainWindow.playAlertSound()
        } else {
            showAlert = false
            alertMessage = ""
        }
    }

    function updateAgeGroupFromSettings(mode) {
        currentAgeGroup = mode
    }

    function saveWaveformSession() {
        if (currentWaveformSession.length > 0) {
            var sessionData = {
                timestamp: new Date().toISOString(),
                duration: sessionDuration,
                spo2: spo2Value,
                pulse: pulseValue,
                ageGroup: currentAgeGroup,
                waveformData: currentWaveformSession.slice(), // Kopya oluştur
                isNormalRange: isInNormalRange
            }

            waveformDatabase.push(sessionData)
            console.log("Waveform session kaydedildi:", sessionData.timestamp)

            // Database boyutunu kontrol et
            if (waveformDatabase.length > maxDatabaseSize) {
                waveformDatabase.shift() // En eski kaydı sil
            }

            // Yeni session'ı başlat
            currentWaveformSession = []
        }
    }

    function getWaveformDatabase() {
        return waveformDatabase
    }

    onSpo2NumericChanged: checkAlert()
    onCurrentAgeGroupChanged: updateNormalRanges()
    Component.onCompleted: updateNormalRanges()

    // Waveform session timer - 10 saniyede bir kaydet
    Timer {
        id: waveformSessionTimer
        interval: sessionDuration
        running: root.isActive
        repeat: true
        onTriggered: {
            saveWaveformSession()
        }
    }

    Connections {
        target: mainWindow
        function onNavigateBack() { root.showMain2 = false; root.showSettings = false; root.isActive = true }
        function onSpo2Changed() { root.spo2Value = mainWindow.spo2 }
        function onPulseChanged() { root.pulseValue = mainWindow.pulse }
        function onWaveformDataReceived(waveformValue) { waveformCanvas.addWaveformData(waveformValue) }
        function onWaveformSampleReceived() { waveformCanvas.addWaveformData(mainWindow.waveformSample) }
        function onSpo2PulseData(spo2, pulse) { root.spo2Value = spo2; root.pulseValue = pulse }
        onRealTimeWaveformPoint: { waveformCanvas.addWaveformData(amplitude) }
    }

    Rectangle {
        id: alertPopup
        width: parent.width - 40
        height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        color: alertColor
        radius: 8
        border.color: "#ffffff"
        border.width: 2
        visible: showAlert
        z: 1000

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: showAlert
            PropertyAnimation { from: 1.0; to: 0.3; duration: 500 }
            PropertyAnimation { from: 0.3; to: 1.0; duration: 500 }
        }

        Column {
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: "⚠️ UYARI!"
                font.family: "Consolas, monospace"
                font.pointSize: 16
                font.bold: true
                color: "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: alertMessage
                font.family: "Consolas, monospace"
                font.pointSize: 12
                color: "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "Normal Aralık: " + normalMinSpo2 + "%-" + normalMaxSpo2 + "% (" + currentAgeGroup + ")"
                font.family: "Consolas, monospace"
                font.pointSize: 9
                color: "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: showAlert = false
        }
    }

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
                // Waveform database'ini main2'ye aktar
                if (item.setWaveformDatabase) {
                    item.setWaveformDatabase(root.getWaveformDatabase())
                }
            }
        }
    }

    Loader {
        id: settingsLoader
        anchors.fill: parent
        source: root.showSettings ? "settings.qml" : ""
        active: root.showSettings
        onLoaded: {
            if (item) {
                item.navigateBack.connect(function() {
                    root.showSettings = false
                    root.isActive = true
                })
                item.ageGroupChanged.connect(function(ageGroup) {
                    root.updateAgeGroupFromSettings(ageGroup)
                })
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: !root.showMain2 && !root.showSettings

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

                    Column {
                        anchors.right: parent.right
                        anchors.rightMargin: 15
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            anchors.right: parent.right
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

                        Text {
                            anchors.right: parent.right
                            text: currentAgeGroup + " Mode"
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#58a6ff"
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 140
                    spacing: 12

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: parent.height
                        color: "#21262d"
                        radius: 8
                        border.color: isInNormalRange ? "#238636" : "#f85149"
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
                                    color: isInNormalRange ? "#7ee787" : "#ff7b72"
                                }
                            }

                            Text {
                                text: "Normal: " + normalMinSpo2 + "%-" + normalMaxSpo2 + "%"
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                color: "#7d8590"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

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
                                            PropertyAnimation { from: 1.0; to: 1.5; duration: 200 }
                                            PropertyAnimation { from: 1.5; to: 1.0; duration: 200 }
                                            PauseAnimation { duration: 800 }
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

                        Canvas {
                            id: waveformCanvas
                            width: parent.width
                            height: parent.height - 38

                            property var waveformData: []
                            property int maxPoints: 500
                            property bool isReceivingData: false
                            property double lastDataTime: 0

                            function addWaveformData(value) {
                                var normalizedValue = Math.max(0, Math.min(1, value / 255.0))
                                waveformData.push(normalizedValue)

                                // Current session'a da ekle
                                root.currentWaveformSession.push({
                                    timestamp: Date.now(),
                                    value: normalizedValue,
                                    spo2: root.spo2Value,
                                    pulse: root.pulseValue
                                })

                                if (waveformData.length > maxPoints) waveformData.shift()

                                // Veri alma durumunu güncelle
                                isReceivingData = true
                                lastDataTime = Date.now()

                                requestPaint()
                            }

                            onPaint: {
                                var ctx = getContext("2d");
                                if (!ctx) return

                                ctx.clearRect(0, 0, width, height);
                                ctx.fillStyle = "#0d1117";
                                ctx.fillRect(0, 0, width, height);

                                ctx.strokeStyle = "#30363d";
                                ctx.lineWidth = 0.5;
                                ctx.setLineDash([2, 2]);

                                for (var i = 0; i <= 4; i++) {
                                    var y = (height / 4) * i;
                                    ctx.beginPath();
                                    ctx.moveTo(0, y);
                                    ctx.lineTo(width, y);
                                    ctx.stroke();
                                }

                                for (var j = 0; j <= 8; j++) {
                                    var x = (width / 8) * j;
                                    ctx.beginPath();
                                    ctx.moveTo(x, 0);
                                    ctx.lineTo(x, height);
                                    ctx.stroke();
                                }

                                ctx.setLineDash([]);

                                if (waveformData.length > 1) {
                                    ctx.strokeStyle = "#58a6ff";
                                    ctx.lineWidth = 2;
                                    ctx.beginPath();

                                    const stepX = width / (maxPoints - 1);
                                    const startX = width - (waveformData.length * stepX);

                                    for (let k = 0; k < waveformData.length; k++) {
                                        const x = startX + (k * stepX);
                                        const y = height - (waveformData[k] * height * 0.8) - (height * 0.1);
                                        if (k === 0) {
                                            ctx.moveTo(x, y);
                                        } else {
                                            ctx.lineTo(x, y);
                                        }
                                    }
                                    ctx.stroke();
                                }

                                if (waveformData.length === 0 || !isReceivingData) {
                                    ctx.fillStyle = "#7d8590";
                                    ctx.font = "12px Consolas, monospace";
                                    ctx.textAlign = "center";
                                    ctx.fillText("Waiting for waveform data...", width/2, height/2);
                                }
                            }

                            Timer {
                                interval: 3000
                                running: true
                                repeat: true
                                onTriggered: {
                                    var timeSinceLastData = Date.now() - waveformCanvas.lastDataTime
                                    if (timeSinceLastData > 3000) {
                                        waveformCanvas.isReceivingData = false
                                        waveformCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }
                }

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
                            color: isInNormalRange ? "#0f5132" : "#58151c"
                            border.color: isInNormalRange ? "#7ee787" : "#ff7b72"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: isInNormalRange ? "NORMAL" : "CRITICAL"
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                font.bold: true
                                color: isInNormalRange ? "#7ee787" : "#ff7b72"
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
                            if (mainWindow) mainWindow.stopDataStream()
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
                            root.showSettings = true
                        }
                    }
                }
            }
        }
    }
}
