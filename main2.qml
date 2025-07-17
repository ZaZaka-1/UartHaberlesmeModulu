import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page2
    signal navigateBack()

    property var measurements: []
    property bool updatePending: false
    property var seenTimestamps: ({})
    property int lastDatabaseCount: 0

    // Waveform database için yeni özellikler
    property var waveformDatabase: []
    property bool showWaveformData: false

    Component.onCompleted: {
        console.log("main2.qml yüklendi - verileri yükleniyor...")
        loadMeasurements()
        loadWaveformData()
        autoUpdateTimer.start()
    }

    // Waveform database'ini ana sayfadan al
    function setWaveformDatabase(database) {
        waveformDatabase = database
        console.log("Waveform database alındı - " + database.length + " session")
    }

    function loadWaveformData() {
        if (typeof root !== 'undefined' && root.getWaveformDatabase) {
            waveformDatabase = root.getWaveformDatabase()
            console.log("Waveform database yüklendi - " + waveformDatabase.length + " session")
        }
    }

    Connections {
        target: mainWindow
        function onMeasurementAdded() {
            if (!updatePending) {
                updatePending = true
                updateTimer.start()
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            loadMeasurements()
            loadWaveformData()
            updatePending = false
        }
    }

    Timer {
        id: autoUpdateTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: {
            loadMeasurements()
            loadWaveformData()
        }
    }

    function loadMeasurements() {
        var allMeasurements = mainWindow.getMeasurementsFromDatabase(1000)
        if (!allMeasurements || allMeasurements.length === 0) {
            console.log("Database'den veri alınamadı")
            return
        }

        var currentDatabaseCount = mainWindow.getTotalMeasurementCount ? mainWindow.getTotalMeasurementCount() : 0
        if (currentDatabaseCount === lastDatabaseCount && measurements.length > 0) {
            return
        }
        lastDatabaseCount = currentDatabaseCount

        var newMeasurements = []
        for (var i = 0; i < allMeasurements.length; i++) {
            var measurement = allMeasurements[i]
            var timestampSeconds = measurement.timestamp.substring(0, 19)

            if (!seenTimestamps[timestampSeconds]) {
                seenTimestamps[timestampSeconds] = true
                newMeasurements.push(measurement)
            }
        }

        if (newMeasurements.length > 0) {
            console.log("Yeni " + newMeasurements.length + " veri eklendi")
            newMeasurements.sort(function(a, b) {
                return new Date(b.timestamp) - new Date(a.timestamp)
            })
            measurements = newMeasurements.concat(measurements)
            if (measurements.length > 1000) {
                measurements = measurements.slice(0, 1000)
            }
        }
    }

    function clearMeasurements() {
        measurements = []
        seenTimestamps = {}
        lastDatabaseCount = 0
        console.log("Veriler temizlendi")
    }

    function refreshAllData() {
        clearMeasurements()
        loadMeasurements()
        loadWaveformData()
        console.log("Tüm veriler yeniden yüklendi")
    }

    function formatTimestamp(timestamp) {
        var date = new Date(timestamp)
        return Qt.formatDateTime(date, "dd.MM.yyyy hh:mm:ss")
    }

    function getStatusColor(isNormal) {
        return isNormal ? "#7ee787" : "#ff6b6b"
    }

    function getStatusText(isNormal) {
        return isNormal ? "Normal" : "Kritik"
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0e14"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Ana başlık
            Text {
                text: showWaveformData ? "Waveform Database" : "Ölçüm Verileri (Database)"
                font.pixelSize: 24
                font.family: "Consolas, monospace"
                color: "#58a6ff"
                Layout.alignment: Qt.AlignHCenter
            }

            // Kontrol paneli
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: showWaveformData ?
                        "Waveform Sessions: " + waveformDatabase.length :
                        "Toplam Kayıt: " + (mainWindow.getTotalMeasurementCount ? mainWindow.getTotalMeasurementCount() : "N/A") + " (Tabloda: " + measurements.length + ")"
                    font.family: "Consolas, monospace"
                    font.pointSize: 10
                    font.bold: true
                    color: "#58a6ff"
                }

                Text {
                    text: "Otomatik Güncelleme: " + (autoUpdateTimer.running ? "AÇIK" : "KAPALI")
                    font.family: "Consolas, monospace"
                    font.pointSize: 9
                    color: autoUpdateTimer.running ? "#7ee787" : "#ff6b6b"
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 10

                    Button {
                        text: showWaveformData ? "Measurements" : "Waveforms"
                        width: 100
                        height: 30
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : (parent.hovered ? "#2d333b" : "#21262d")
                            radius: 6
                            border.color: "#ffa500"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            font.family: "Consolas, monospace"
                            font.pointSize: 9
                            color: "#ffa500"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            showWaveformData = !showWaveformData
                            loadWaveformData()
                        }
                    }

                    Button {
                        text: autoUpdateTimer.running ? "Dur" : "Başlat"
                        width: 70
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
                            } else {
                                autoUpdateTimer.start()
                            }
                        }
                    }

                    Button {
                        text: "Yenile"
                        width: 70
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
                        onClicked: refreshAllData()
                    }

                    Button {
                        text: "Temizle"
                        width: 70
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
                            }
                            clearMeasurements()
                        }
                    }
                }
            }

            // Tablo başlığı - Measurements
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#21262d"
                border.color: "#58a6ff"
                border.width: 1
                radius: 6
                visible: !showWaveformData

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

            // Tablo başlığı - Waveforms
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: "#21262d"
                border.color: "#58a6ff"
                border.width: 1
                radius: 6
                visible: showWaveformData

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
                        Layout.preferredWidth: 120
                        text: "Tarih/Saat"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 70
                        text: "SpO2"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 70
                        text: "Pulse"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 80
                        text: "Age Group"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 70
                        text: "Status"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.preferredWidth: 80
                        text: "Samples"
                        font.family: "Consolas, monospace"
                        font.bold: true
                        color: "#58a6ff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Veri tablosu
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                background: Rectangle {
                    color: "#0a0e14"
                    border.color: "#58a6ff"
                    border.width: 1
                    radius: 6
                }

                // Measurements ListView
                ListView {
                    id: measurementList
                    model: measurements
                    clip: true
                    visible: !showWaveformData

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

                // Waveforms ListView
                ListView {
                    id: waveformList
                    model: waveformDatabase
                    clip: true
                    visible: showWaveformData

                    delegate: Rectangle {
                        width: waveformList.width
                        height: 80
                        color: index % 2 === 0 ? "#161b22" : "#0d1117"
                        border.color: "#30363d"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5

                            Text {
                                Layout.preferredWidth: 50
                                text: index + 1
                                font.family: "Consolas, monospace"
                                color: "#f0f6fc"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                Layout.preferredWidth: 120
                                text: formatTimestamp(modelData.timestamp)
                                font.family: "Consolas, monospace"
                                color: "#f0f6fc"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 8
                            }

                            Text {
                                Layout.preferredWidth: 70
                                text: modelData.spo2 + "%"
                                font.family: "Consolas, monospace"
                                color: "#7ee787"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.bold: true
                            }

                            Text {
                                Layout.preferredWidth: 70
                                text: modelData.pulse
                                font.family: "Consolas, monospace"
                                color: "#ff7b72"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.bold: true
                            }

                            Text {
                                Layout.preferredWidth: 80
                                text: modelData.ageGroup
                                font.family: "Consolas, monospace"
                                color: "#58a6ff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pointSize: 8
                            }

                            Text {
                                Layout.preferredWidth: 70
                                text: getStatusText(modelData.isNormalRange)
                                font.family: "Consolas, monospace"
                                color: getStatusColor(modelData.isNormalRange)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.bold: true
                                font.pointSize: 8
                            }

                            Column {
                                Layout.preferredWidth: 80
                                Layout.fillHeight: true

                                Text {
                                    text: modelData.waveformData ? modelData.waveformData.length + " samples" : "0 samples"
                                    font.family: "Consolas, monospace"
                                    color: "#ffa500"
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pointSize: 8
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Rectangle {
                                    width: 70
                                    height: 30
                                    color: "#0d1117"
                                    border.color: "#30363d"
                                    border.width: 1
                                    radius: 3
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Canvas {
                                        id: miniWaveform
                                        anchors.fill: parent
                                        anchors.margins: 2

                                        onPaint: {
                                            var ctx = getContext("2d")
                                            if (!ctx || !modelData.waveformData || modelData.waveformData.length === 0) return

                                            ctx.clearRect(0, 0, width, height)

                                            ctx.strokeStyle = "#58a6ff"
                                            ctx.lineWidth = 1
                                            ctx.beginPath()

                                            var waveData = modelData.waveformData
                                            var stepX = width / (waveData.length - 1)

                                            for (var i = 0; i < waveData.length; i++) {
                                                var x = i * stepX
                                                var y = height - (waveData[i].value * height * 0.8) - (height * 0.1)

                                                if (i === 0) {
                                                    ctx.moveTo(x, y)
                                                } else {
                                                    ctx.lineTo(x, y)
                                                }
                                            }
                                            ctx.stroke()
                                        }

                                        Component.onCompleted: {
                                            if (modelData.waveformData && modelData.waveformData.length > 0) {
                                                requestPaint()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Alt bilgi satırı
            Text {
                text: showWaveformData ?
                    (waveformDatabase.length > 0 ? "Son güncelleme: " + new Date().toLocaleTimeString() : "Henüz waveform verisi yok") :
                    (measurements.length > 0 ? "Son güncelleme: " + new Date().toLocaleTimeString() : "Henüz veri yok")
                font.family: "Consolas, monospace"
                font.pointSize: 8
                color: "#7ee787"
                Layout.alignment: Qt.AlignHCenter
            }

            // Alt butonlar
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Button {
                    width: 200
                    height: 40
                    background: Rectangle {
                        color: parent.pressed ? "#238636" : (parent.hovered ? "#2d333b" : "#21262d")
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
                    }
                    onClicked: {
                        autoUpdateTimer.stop()
                        updateTimer.stop()
                        page2.navigateBack()
                    }
                }

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
