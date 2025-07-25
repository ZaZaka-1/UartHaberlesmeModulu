import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    width: 480
    height: 700
    title: "SPO2 Monitor"
    color: "#0a0e14"

    property bool isExportingPdf: false
    property string lastExportedImagePath: ""
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


    function exportWaveformToPdf() {
        isExportingPdf = true

        // Test modunda özel başlık ekle
        waveformCanvas.isTestMode = true
        waveformCanvas.requestPaint()

        exportTimer.start()
    }
    function generateCurrentWaveformImage() {
        console.log("Generating waveform image...");
        waveformCanvas.isExportingImage = true;
        waveformCanvas.requestPaint();
    }


    Timer {
        id: imageExportTimer
        interval: 500
        onTriggered: {
            console.log("🟢 imageExportTimer triggered")
            var imageData = waveformCanvas.toDataURL("image/png")
            if (pageLoader.item && pageLoader.item.setCurrentWaveformImage) {
                pageLoader.item.setCurrentWaveformImage(imageData)
            }
        }
    }

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
    Connections {
        target: waveformCanvas
        function onImageExported() {
            var imageData = waveformCanvas.toDataURL("image/png");
            if (pageLoader.item && pageLoader.item.setCurrentWaveformImage) {
                pageLoader.item.setCurrentWaveformImage(imageData);
            }
        }
    }

    Timer {
        id: exportTimer
        interval: 200
        onTriggered: {
            var imageData = waveformCanvas.toDataURL("image/png")
            var base64Data = imageData.split(',')[1]

            if (mainWindow && mainWindow.exportToPdfWithWaveform) {
                var patientData = {
                    spo2: root.spo2Value,
                    pulse: root.pulseValue,
                    ageGroup: root.currentAgeGroup,
                    timestamp: new Date().toISOString(),
                    normalRange: normalMinSpo2 + "-" + normalMaxSpo2 + "%",
                    status: isInNormalRange ? "NORMAL" : "CRITICAL",
                    isTestData: waveformCanvas.isTestMode // Test verisi olduğunu belirt
                }

                mainWindow.exportToPdfWithWaveform(base64Data, JSON.stringify(patientData))
            }

            waveformCanvas.isTestMode = false
            isExportingPdf = false
        }
    }

    Timer {
        id: autoWaveformImageTimer
        interval: 5000 // Her 5 saniyede bir
        repeat: true
        running: root.isActive && root.showMain2 // Sadece main2 açıkken çalışsın
        onTriggered: {
            console.log("🔄 Otomatik waveform image oluşturuluyor...");
            generateCurrentWaveformImage();
        }
    }

    Timer {
        id: autoSaveWaveformTimer
        interval: 5000 // 5 saniyede bir
        running: root.isActive
        repeat: true
        onTriggered: {
            // Canvas'dan görseli al (başlıksız Base64)
            var imageData = waveformCanvas.toDataURL("image/png").split(',')[1];

            // Ölçüm + Görseli tek seferde kaydet
            if (mainWindow && mainWindow.insertMeasurementWithImage) {
                mainWindow.insertMeasurementWithImage(spo2Value, pulseValue, imageData);
            }
        }
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

                // BURAYA EKLE - Waveform görüntüsünü gönder
                if (item.setCurrentWaveformImage) {
                    var imageData = waveformCanvas.toDataURL("image/png")
                    item.setCurrentWaveformImage(imageData)
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
                            property int maxPoints: 450
                            property bool isReceivingData: false
                            property double lastDataTime: 0
                            property bool isTestMode: false
                            property bool isExportingImage: false
                            signal imageExported()

                            // SPO2 dalga formu için ek özellikler
                            property double baselineOffset: 0.2  // Baseline seviyesi
                            property double amplitudeScale: 0.6  // Dalga genliği
                            property double noiseLevel: 0.01     // Gürültü seviyesi
                            property double wavePhase: 0         // Dalga fazı
                            property var smoothingBuffer: []     // Yumuşatma tamponu
                            property int smoothingWindow: 5      // Yumuşatma penceresi

                            renderTarget: Canvas.FramebufferObject
                            renderStrategy: Canvas.Threaded

                            // DEBUG için sayacı
                            property int dataCount: 0

                            function addWaveformData(value) {
                                if (!root.isActive) return; // Aktif değilse ekleme

                                var normalizedValue;

                                if (isTestMode) {
                                    // Test modunda gerçekçi SPO2 dalga formu oluştur
                                    normalizedValue = generateRealisticSPO2Wave();
                                } else {
                                    // Gerçek veriden gelen değeri işle
                                    var rawValue = Math.max(0, Math.min(255, value)) / 255.0;
                                    normalizedValue = processRealSPO2Data(rawValue);
                                }

                                // Veri geçmişini güncelle
                                waveformData.push(normalizedValue);
                                if (waveformData.length > maxPoints) waveformData.shift();

                                // Veri alındığını işaretle
                                isReceivingData = true;
                                lastDataTime = Date.now();
                                dataCount++;

                                // Çizim optimizasyonu
                                if (!repaintTimer.running) {
                                    requestPaint();
                                    repaintTimer.start();
                                }
                            }

                            function generateRealisticSPO2Wave() {
                                var heartRate = parseInt(root.pulseValue) || 72;
                                var beatsPerSecond = heartRate / 60.0;

                                wavePhase += (2 * Math.PI * beatsPerSecond) / 30;
                                if (wavePhase > 2 * Math.PI) wavePhase -= 2 * Math.PI;

                                // SPO2 karakteristik dalga formu
                                var systolic = Math.sin(wavePhase) * Math.exp(-Math.pow((wavePhase - Math.PI/2) / (Math.PI/3), 2));
                                var diastolic = Math.sin(wavePhase * 1.5 + Math.PI/3) * 0.2;
                                var dichrotic = wavePhase > Math.PI && wavePhase < 1.5 * Math.PI ?
                                               Math.sin((wavePhase - Math.PI) * 4) * 0.15 : 0;

                                var wave = systolic + diastolic + dichrotic;

                                // Fizyolojik varyasyon
                                var variation = Math.sin(wavePhase * 0.1) * 0.05;
                                var breathing = Math.sin(wavePhase * 0.05) * 0.03; // Solunum etkisi

                                return Math.max(0, Math.min(1, baselineOffset + (wave + variation + breathing) * amplitudeScale));
                            }

                            function processRealSPO2Data(rawValue) {
                                // Smoothing buffer'ı güncelle
                                smoothingBuffer.push(rawValue);
                                if (smoothingBuffer.length > smoothingWindow) {
                                    smoothingBuffer.shift();
                                }

                                // Hareketli ortalama ile yumuşatma
                                var smoothed = smoothingBuffer.reduce(function(sum, val) { return sum + val; }, 0) / smoothingBuffer.length;

                                // AC bileşenini vurgula (nabız sinyali)
                                var dcOffset = 0.5; // Ortalama seviye
                                var acComponent = (smoothed - dcOffset) * 2; // AC bileşenini güçlendir

                                // Gürültü filtrele ve normalize et
                                var processed = dcOffset + acComponent;
                                processed += (Math.random() - 0.5) * noiseLevel; // Minimal gürültü

                                return Math.max(0, Math.min(1, baselineOffset + processed * amplitudeScale));
                            }

                            Timer {
                                id: repaintTimer
                                interval: 16 // ~60 FPS (1000/60)
                                repeat: false
                            }

                            onPaint: {
                                console.log("onPaint called, data points:", waveformData.length)

                                var ctx = getContext("2d")

                                // Canvas'ı temizle
                                ctx.clearRect(0, 0, width, height)

                                // Arka plan
                                ctx.fillStyle = "#1a1a1a"
                                ctx.fillRect(0, 0, width, height)

                                // Test durumu yazısı
                                if (isTestMode) {
                                    ctx.fillStyle = "#f472b6"
                                    ctx.font = "bold 12px Consolas, monospace"
                                    ctx.textAlign = "right"
                                    ctx.fillText("TEST MODE", width - 10, 20)
                                }

                                // Veri sayısını göster
                                ctx.fillStyle = "#ffffff"
                                ctx.font = "10px Arial"
                                ctx.textAlign = "left"
                                ctx.fillText("Data points: " + waveformData.length, 10, 20)
                                ctx.fillText("Data count: " + dataCount, 10, 35)

                                // Waveform çiz
                                if (waveformData.length > 1) {
                                    console.log("Drawing waveform with", waveformData.length, "points")

                                    // Grid çizgileri
                                    ctx.strokeStyle = "#30363d"
                                    ctx.lineWidth = 0.5
                                    for (var y = 0; y <= height; y += height/4) {
                                        ctx.beginPath()
                                        ctx.moveTo(0, y)
                                        ctx.lineTo(width, y)
                                        ctx.stroke()
                                    }

                                    // Ana waveform çizgisi
                                    ctx.strokeStyle = "#00ff88"
                                    ctx.lineWidth = 2
                                    ctx.shadowColor = "#00ff88"
                                    ctx.shadowBlur = 3
                                    ctx.beginPath()

                                    var stepX = width / (maxPoints - 1)
                                    var startIndex = Math.max(0, waveformData.length - maxPoints)

                                    // Spline interpolasyon için kontrol noktalarını hesapla
                                    for (var i = 0; i < waveformData.length - 1; i++) {
                                        var x1 = i * stepX
                                        var y1 = height - (waveformData[startIndex + i] * height)
                                        var x2 = (i + 1) * stepX
                                        var y2 = height - (waveformData[startIndex + i + 1] * height)

                                        if (i === 0) {
                                            ctx.moveTo(x1, y1)
                                        }

                                        // Yumuşak geçiş için bezier curve kullan
                                        var cpx = x1 + (x2 - x1) * 0.5
                                        var cpy1 = y1
                                        var cpy2 = y2

                                        ctx.quadraticCurveTo(cpx, cpy1, x2, y2)
                                    }

                                    ctx.stroke()

                                    // Glow efekti için ikinci çizim
                                    ctx.strokeStyle = "#00ff4488"
                                    ctx.lineWidth = 4
                                    ctx.stroke()

                                    ctx.shadowBlur = 0 // Shadow'u sıfırla

                                    // Eğer export işlemi yapılıyorsa, daha kalın ve net bir çizgi
                                    if (isExportingImage) {
                                        ctx.strokeStyle = "#00ff88"
                                        ctx.lineWidth = 3
                                        ctx.stroke()
                                    }
                                } else {
                                    console.log("Not enough data to draw, points:", waveformData.length)
                                }

                                // Veri alma durumu
                                if (isExportingImage) {
                                    isExportingImage = false
                                    console.log("Emitting imageExported signal")
                                    imageExported() // Bu sinyali tetikleyin
                                }
                            }

                            Connections {
                                target: mainWindow

                                function onRealTimeWaveformPoint(value) {
                                    console.log("=== onRealTimeWaveformPoint triggered ===")
                                    console.log("Received value:", value)
                                    console.log("Test mode active:", mainWindow.isTestMode)

                                    if (mainWindow.isTestMode) {
                                        isTestMode = true
                                    }
                                    addWaveformData(value)
                                }

                                function onTestModeChanged() {
                                    console.log("=== onTestModeChanged triggered ===")
                                    console.log("New test mode:", mainWindow.isTestMode)
                                    waveformCanvas.isTestMode = mainWindow.isTestMode
                                    requestPaint()
                                }

                                // Bu bağlantıyı da test edelim
                                function onWaveformSampleChanged() {
                                    console.log("=== onWaveformSampleChanged triggered ===")
                                    console.log("Waveform sample:", mainWindow.waveformSample)
                                    addWaveformData(mainWindow.waveformSample)
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

                            // Component.onCompleted ile başlangıç kontrolü
                            Component.onCompleted: {
                                console.log("Waveform Canvas initialized")
                                console.log("MainWindow isTestMode:", mainWindow.isTestMode)
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
                            // Otomatik olarak belirli aralıklarla waveform görüntüsü oluşturulsun
                            imageExportTimer.running = true

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

                    Button {
                        width: 120
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#10b981" : "#21262d"
                            radius: 6
                            border.color: "#58a6ff"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: isExportingPdf ? "Kaydediliyor..." : "PDF Kaydet"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: exportWaveformToPdf()
                    }
                    Button {
                        width: 120
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#9d174d" : (mainWindow.isTestMode ? "#065f46" : "#21262d")
                            radius: 6
                            border.color: mainWindow.isTestMode ? "#10b981" : "#f472b6"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: mainWindow.isTestMode ? "Test Aktif" : "Test Verisi"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            color: mainWindow.isTestMode ? "#10b981" : "#f472b6"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: testMenu.open()

                        Menu {
                            id: testMenu
                            y: parent.height + 5
                            width: 250

                            MenuItem {
                                text: mainWindow.isTestMode ? "Test Modunu Durdur" : "Otomatik Test Başlat (100ms)"
                                onTriggered: {
                                    if (mainWindow.isTestMode) {
                                        mainWindow.stopTestData()
                                    } else {
                                        mainWindow.startTestData(100)
                                    }
                                }
                            }

                            MenuSeparator {}

                            MenuItem {
                                text: "Hızlı Test (50ms)"
                                enabled: !mainWindow.isTestMode
                                onTriggered: mainWindow.startTestData(50)
                            }

                            MenuItem {
                                text: "Normal Test (100ms)"
                                enabled: !mainWindow.isTestMode
                                onTriggered: mainWindow.startTestData(100)
                            }

                            MenuItem {
                                text: "Yavaş Test (200ms)"
                                enabled: !mainWindow.isTestMode
                                onTriggered: mainWindow.startTestData(200)
                            }

                            MenuSeparator {}

                            MenuItem {
                                text: "Rastgele Waveform Gönder"
                                onTriggered: mainWindow.sendTestValue(Math.floor(Math.random() * 255))
                            }

                            MenuItem {
                                text: "Yüksek Değer (200)"
                                onTriggered: mainWindow.sendTestValue(200)
                            }

                            MenuItem {
                                text: "Düşük Değer (50)"
                                onTriggered: mainWindow.sendTestValue(50)
                            }
                        }
                    }
                }
            }
        }
    }
}
