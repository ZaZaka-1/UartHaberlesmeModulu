import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    visible: true
    width: 480
    height: 700
    title: qsTr("Advanced SPO2 Monitor")
    color: "#0a0e14"

    property bool isActive: true
        signal navigateToMain2()

     property bool showMain2: false


    // C++ backend'den gelen veriler - mainWindow objesi üzerinden erişim
    // Bu kısım, uygulamanın C++ backend'i ile nasıl entegre olduğunu gösterir.
    // Gerçek bir uygulamada 'mainWindow' objesi C++ tarafından QML'e expose edilmelidir.
    property string spo2Value: mainWindow ? mainWindow.spo2 : "98"
    property string pulseValue: mainWindow ? mainWindow.pulse : "72"

    // Backend sinyallerini dinle
    // C++'tan gelen spo2Changed ve pulseChanged sinyallerini yakalar
    Connections {
        target: mainWindow
        function onNavigateBack() {
            root.showMain2 = false
            root.isActive = true   // ✅ Ana sayfa animasyonları tekrar BAŞLAR
        }
        function onSpo2Changed() {
            root.spo2Value = mainWindow.spo2
        }
        function onPulseChanged() {
            root.pulseValue = mainWindow.pulse
        }
    }

    // Numerik değerler için helper propertyler
    // String değerleri sayısal formata dönüştürür ve geçersiz durumları yönetir.
    property int spo2Numeric: {
        if (spo2Value === "Geçersiz" || spo2Value === "") return 0
        var val = parseInt(spo2Value)
        return isNaN(val) ? 0 : val
    }

    property int pulseNumeric: {
        if (pulseValue === "Geçersiz" || pulseValue === "") return 0
        var val = parseInt(pulseValue)
        return isNaN(val) ? 0 : val
    }

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: root.showMain2 ? "main2.qml" : ""
        active: root.showMain2

        onLoaded: {
            if (item) {
                console.log("main2.qml yüklendi, sinyal dinleniyor...")
                item.navigateBack.connect(function() {
                    console.log("navigateBack sinyali geldi, ana sayfaya dönülüyor...")
                    root.showMain2 = false
                    root.isActive = true
                })
            }
        }
    }

  Item {

      anchors.fill: parent
      visible: !root.showMain2  // Bu satır görünürlüğü kontrol eder


    // Ana içerik kutusu
    Rectangle {
        anchors.fill: parent
        anchors.margins: 15
        radius: 10
        color: "#161b22" // Koyu gri arka plan
        border.color: "#30363d" // Koyu gri kenarlık
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            // Gelişmiş başlık
            Rectangle {
                width: parent.width
                height: 55
                color: "#21262d" // Koyu mavi-gri başlık arka planı
                radius: 8
                border.color: "#30363d"
                border.width: 1

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    spacing: 12

                    Rectangle {
                        width: 6
                        height: 30
                        color: "#238636" // Yeşil vurgu çubuğu
                        radius: 3
                    }

                    Text {
                        text: qsTr("PULSE OXIMETRY MONITOR")
                        font.family: "Consolas, monospace" // Monospace font
                        font.pointSize: 12
                        font.bold: true
                        color: "#58a6ff" // Açık mavi metin
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Sinyal durumu göstergesi (yanıp sönen nokta)
                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: root.spo2Value !== "Geçersiz" && root.spo2Value !== "" ? "#238636" : "#656d76" // Yeşil veya gri
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: root.spo2Value !== "Geçersiz" && root.spo2Value !== "" && root.isActive // Sinyal varsa yanıp söner
                            PropertyAnimation { from: 1.0; to: 0.2; duration: 1000 }
                            PropertyAnimation { from: 0.2; to: 1.0; duration: 1000 }
                        }
                    }
                }

                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        id: timeText
                        text: Qt.formatDateTime(new Date(), "hh:mm:ss") // Saat
                        font.family: "Consolas, monospace"
                        font.pointSize: 11
                        color: "#7d8590" // Açık gri metin
                        anchors.right: parent.right

                        Timer {
                            interval: 1000 // Her saniye güncellenir
                            running: root.isActive
                            repeat: true
                            onTriggered: timeText.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(new Date(), "dd.MM.yyyy") // Tarih
                        font.family: "Consolas, monospace"
                        font.pointSize: 8
                        color: "#656d76" // Koyu gri metin
                        anchors.right: parent.right
                    }
                }
            }

            // Vital Signs Paneli (SpO2 ve Nabız)
            Row {
                width: parent.width
                height: 140
                spacing: 12

                // SpO2 Ana Panel
                Rectangle {
                    width: (parent.width - 12) / 2 // Genişliğin yarısı
                    height: parent.height
                    color: "#21262d"
                    radius: 8
                    border.color: { // SpO2 değerine göre kenarlık rengi
                        if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return "#656d76" // Gri
                        return root.spo2Numeric >= 95 ? "#238636" : (root.spo2Numeric >= 90 ? "#fb8500" : "#f85149") // Yeşil, turuncu, kırmızı
                    }
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: qsTr("SpO₂")
                            font.family: "Consolas, monospace"
                            font.pointSize: 14
                            font.bold: true
                            color: "#58a6ff"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle {
                            width: 100
                            height: 60
                            color: "#0d1117" // Koyu arka plan
                            radius: 6
                            border.color: "#30363d"
                            border.width: 1
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.spo2Value === "Geçersiz" || root.spo2Value === "" ? "--" : root.spo2Value + "%"
                                font.family: "Consolas, monospace"
                                font.pointSize: 28
                                font.bold: true
                                color: { // SpO2 değerine göre metin rengi
                                    if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return "#656d76"
                                    return root.spo2Numeric >= 95 ? "#7ee787" : (root.spo2Numeric >= 90 ? "#ffa657" : "#ff7b72")
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: { // SpO2 değerine göre nokta rengi
                                    if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return "#656d76"
                                    return root.spo2Numeric >= 95 ? "#7ee787" : (root.spo2Numeric >= 90 ? "#ffa657" : "#ff7b72")
                                }
                            }

                            Text {
                                text: qsTr("Oxygen Saturation")
                                font.family: "Consolas, monospace"
                                font.pointSize: 9
                                color: "#7d8590"
                            }
                        }
                    }
                }

                // Pulse Rate Panel
                Rectangle {
                    width: (parent.width - 12) / 2
                    height: parent.height
                    color: "#21262d"
                    radius: 8
                    border.color: root.pulseValue !== "Geçersiz" && root.pulseValue !== "" ? "#da3633" : "#656d76" // Kırmızı veya gri
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: qsTr("PULSE")
                            font.family: "Consolas, monospace"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ff7b72" // Kırmızı metin
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
                                    text: root.pulseValue === "Geçersiz" || root.pulseValue === "" ? "--" : root.pulseValue
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 24
                                    font.bold: true
                                    color: root.pulseValue !== "Geçersiz" && root.pulseValue !== "" ? "#ff7b72" : "#656d76"
                                }

                                // Kalp atışı ikonu ve animasyonu
                                Text {
                                    id: pulseIcon
                                    text: "♥" // Kalp ikonu
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 16
                                    color: root.pulseValue !== "Geçersiz" && root.pulseValue !== "" ? "#ff7b72" : "#656d76"
                                    anchors.verticalCenter: parent.verticalCenter

                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: root.pulseValue !== "Geçersiz" && root.pulseValue !== "" && root.pulseNumeric > 0
                                        // Nabız hızına göre animasyon süresi ayarlanır
                                        PropertyAnimation {
                                            from: 1.0; to: 1.5;
                                            duration: root.pulseNumeric > 0 ? (60000 / Math.max(root.pulseNumeric, 60) * 0.15) : 500
                                        }
                                        PropertyAnimation {
                                            from: 1.5; to: 1.0;
                                            duration: root.pulseNumeric > 0 ? (60000 / Math.max(root.pulseNumeric, 60) * 0.15) : 500
                                        }
                                        PropertyAnimation {
                                            from: 1.0; to: 1.3;
                                            duration: root.pulseNumeric > 0 ? (60000 / Math.max(root.pulseNumeric, 60) * 0.1) : 300
                                        }
                                        PropertyAnimation {
                                            from: 1.3; to: 1.0;
                                            duration: root.pulseNumeric > 0 ? (60000 / Math.max(root.pulseNumeric, 60) * 0.1) : 300
                                        }
                                        PauseAnimation {
                                            duration: root.pulseNumeric > 0 ? (60000 / Math.max(root.pulseNumeric, 60) * 0.5) : 1000
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: qsTr("BPM")
                            font.family: "Consolas, monospace"
                            font.pointSize: 9
                            color: "#7d8590"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // SpO2 Waveform Monitor with Axes
            Rectangle {
                width: parent.width
                height: 240  // Eksenler için yükseklik artırıldı
                color: "#0d1117" // Çok koyu arka plan
                radius: 8
                border.color: "#30363d"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 8

                    // SpO2 Waveform Başlığı
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: "#21262d"
                        radius: 4

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 8

                            Rectangle {
                                width: 3
                                height: 20
                                color: "#58a6ff"
                                radius: 1
                            }

                            Text {
                                text: qsTr("SpO₂ PLETHYSMOGRAPH")
                                font.family: "Consolas, monospace"
                                font.pointSize: 10
                                font.bold: true
                                color: "#58a6ff"
                            }

                            Text {
                                text: root.spo2Value === "Geçersiz" || root.spo2Value === "" ? "--" : root.spo2Value + "%"
                                font.family: "Consolas, monospace"
                                font.pointSize: 9
                                color: "#7d8590"
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PI: " + (root.spo2Numeric > 0 ? (root.spo2Numeric * 0.12 / 10).toFixed(2) : "--") + "%"
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#58a6ff"
                        }
                    }

                    // Grafik alanı (Y ekseni + Canvas + X ekseni)
                    Row {
                        width: parent.width
                        height: parent.height - 40
                        spacing: 0

                        // Y Ekseni (Sol taraf)
                        Rectangle {
                            id: yAxisArea
                            width: 40
                            height: parent.height - 25  // X ekseni için yer bırak
                            color: "#010409"

                            Column {
                                anchors.fill: parent
                                spacing: 0

                                // Y ekseni etiketleri (100% -> 0%)
                                Repeater {
                                    model: 6  // 100, 80, 60, 40, 20, 0
                                    Rectangle {
                                        width: yAxisArea.width
                                        height: yAxisArea.height / 6
                                        color: "transparent"

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 5
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: (100 - index * 20) + "%"
                                            font.family: "Consolas, monospace"
                                            font.pointSize: 7
                                            color: "#656d76"
                                        }

                                        // Y ekseni çizgisi
                                        Rectangle {
                                            width: 3
                                            height: 1
                                            color: "#30363d"
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // Y ekseni ana çizgisi
                                Rectangle {
                                    width: 1
                                    height: parent.height
                                    color: "#30363d"
                                    anchors.right: parent.right
                                }
                            }
                        }

                        // Ana grafik alanı
                        Column {
                            width: parent.width - yAxisArea.width
                            height: parent.height

                            // SpO2 Waveform Canvas
                            Rectangle {
                                width: parent.width
                                height: parent.height - 25  // X ekseni için yer bırak
                                color: "#010409"

                                Canvas {
                                    id: spo2WaveformCanvas
                                    anchors.fill: parent
                                    anchors.margins: 3

                                    property real phase: 0
                                    property int spo2Value: root.spo2Numeric
                                    property int pulseRate: root.pulseNumeric > 0 ? root.pulseNumeric : 75
                                    property bool hasValidData: root.spo2Value !== "Geçersiz" && root.spo2Value !== ""
                                    property real currentTime: 0  // Zaman takibi için

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        // Medikal grid sistemi
                                        drawMedicalGrid(ctx)

                                        if (hasValidData) {
                                            // SpO2 Plethysmography waveform
                                            drawSpO2Waveform(ctx)
                                        } else {
                                            // Sinyal yoksa gösterge
                                            drawNoSignal(ctx)
                                        }

                                        // Ölçüm imleçleri
                                        drawMeasurementCursors(ctx)
                                    }

                                    // Medikal grid çizimi fonksiyonu
                                    function drawMedicalGrid(ctx) {
                                        // İnce grid çizgileri (1mm, 5 piksel)
                                        ctx.strokeStyle = "#1c2128" // Koyu gri
                                        ctx.lineWidth = 0.3

                                        for (var i = 0; i < width; i += 5) {
                                            ctx.beginPath()
                                            ctx.moveTo(i, 0)
                                            ctx.lineTo(i, height)
                                            ctx.stroke()
                                        }

                                        for (var j = 0; j < height; j += 5) {
                                            ctx.beginPath()
                                            ctx.moveTo(0, j)
                                            ctx.lineTo(width, j)
                                            ctx.stroke()
                                        }

                                        // Kalın grid çizgileri (5mm, 25 piksel)
                                        ctx.strokeStyle = "#30363d" // Daha açık koyu gri
                                        ctx.lineWidth = 0.5

                                        for (var k = 0; k < width; k += 25) {
                                            ctx.beginPath()
                                            ctx.moveTo(k, 0)
                                            ctx.lineTo(k, height)
                                            ctx.stroke()
                                        }

                                        for (var l = 0; l < height; l += 25) {
                                            ctx.beginPath()
                                            ctx.moveTo(0, l)
                                            ctx.lineTo(width, l)
                                            ctx.stroke()
                                        }
                                    }

                                    function drawSpO2Waveform(ctx) {
                                        var amplitudeFactor = Math.max(0.3, spo2Value / 100.0);
                                        var amplitude = height * 0.4 * amplitudeFactor;
                                        var baseline = height * 0.6;

                                        var waveColor = spo2Value >= 95 ? "#58a6ff" :
                                                        spo2Value >= 90 ? "#ffa657" : "#ff7b72";

                                        ctx.strokeStyle = waveColor;
                                        ctx.lineWidth = 2.5;
                                        ctx.beginPath();

                                        // Daha fazla dalga için kısa periyot
                                        var period = width / (pulseRate / 60.0 * 12.0);

                                        var xOffset = spo2WaveformCanvas.phase % period;

                                        for (var x = 0; x < width; x++) {
                                            var currentX = x + xOffset;
                                            var t = (currentX % period) / period;

                                            var y;

                                            // Temiz bifid plethysmography dalga formu - düz çizgiler
                                            if (t < 0.1) {
                                                // Düz baseline
                                                y = baseline;
                                            }
                                            else if (t < 0.15) {
                                                // Hızlı düz çıkış
                                                var rise = (t - 0.1) / 0.05;
                                                y = baseline - rise * amplitude;
                                            }
                                            else if (t < 0.2) {
                                                // İlk tepe (düz)
                                                y = baseline - amplitude;
                                            }
                                            else if (t < 0.28) {
                                                // Düz iniş - dikrotik çentiğe
                                                var fall1 = (t - 0.2) / 0.08;
                                                y = baseline - amplitude + fall1 * amplitude * 0.4;
                                            }
                                            else if (t < 0.32) {
                                                // Dikrotik çentik (düz düşük seviye)
                                                y = baseline - amplitude * 0.6;
                                            }
                                            else if (t < 0.37) {
                                                // İkinci tepe çıkış (düz)
                                                var rise2 = (t - 0.32) / 0.05;
                                                y = baseline - amplitude * 0.6 - rise2 * amplitude * 0.15;
                                            }
                                            else if (t < 0.42) {
                                                // İkinci tepe (düz)
                                                y = baseline - amplitude * 0.75;
                                            }
                                            else if (t < 0.55) {
                                                // Düz iniş baseline'a
                                                var fall2 = (t - 0.42) / 0.13;
                                                y = baseline - amplitude * 0.75 + fall2 * amplitude * 0.75;
                                            }
                                            else {
                                                // Düz baseline
                                                y = baseline;
                                            }

                                            // Düşük SpO2'de minimal bozulma
                                            if (spo2Value < 90 && spo2Value > 0) {
                                                var distortionFactor = (90 - spo2Value) / 30.0;
                                                y += (Math.random() - 0.5) * 1.0 * distortionFactor;
                                            } else if (spo2Value === 0) {
                                                y = baseline + (Math.random() - 0.5) * 2;
                                            }

                                            if (x === 0) {
                                                ctx.moveTo(x, y);
                                            } else {
                                                ctx.lineTo(x, y);
                                            }
                                        }

                                        ctx.stroke();

                                        // Baseline çizgisi
                                        ctx.strokeStyle = "#6e7681";
                                        ctx.lineWidth = 1;
                                        ctx.setLineDash([2, 2]);
                                        ctx.beginPath();
                                        ctx.moveTo(0, baseline);
                                        ctx.lineTo(width, baseline);
                                        ctx.stroke();
                                        ctx.setLineDash([]);

                                        // Değer etiketi
                                        ctx.fillStyle = waveColor;
                                        ctx.font = "bold 14px Consolas, monospace";
                                        ctx.fillText("SpO₂: " + spo2Value + "%", 10, 25);
                                    }

                                    // Sinyal yoksa gösterge çizimi
                                    function drawNoSignal(ctx) {
                                        var baseline = height * 0.6

                                        // Düz çizgi (kesikli)
                                        ctx.strokeStyle = "#656d76"
                                        ctx.lineWidth = 1
                                        ctx.setLineDash([5, 5])
                                        ctx.beginPath()
                                        ctx.moveTo(0, baseline)
                                        ctx.lineTo(width, baseline)
                                        ctx.stroke()
                                        ctx.setLineDash([])

                                        // "NO SIGNAL" metni
                                        ctx.fillStyle = "#656d76"
                                        ctx.font = "bold 14px Consolas, monospace"
                                        ctx.fillText("NO SIGNAL", 10, 25)
                                    }

                                    // Ölçüm imleçleri çizimi
                                    function drawMeasurementCursors(ctx) {
                                        if (!hasValidData) return

                                        // Zaman cursoru (kayan dikey çizgi)
                                        var cursorX = (phase * 2) % width

                                        ctx.strokeStyle = "#f85149"
                                        ctx.lineWidth = 1
                                        ctx.setLineDash([])
                                        ctx.beginPath()
                                        ctx.moveTo(cursorX, 0)
                                        ctx.lineTo(cursorX, height)
                                        ctx.stroke()

                                        // Kritik durum overlay
                                        if (spo2Value < 88 && spo2Value > 0) {
                                            ctx.fillStyle = "#f8514920"
                                            ctx.fillRect(0, 0, width, height)

                                            ctx.strokeStyle = "#f85149"
                                            ctx.lineWidth = 3
                                            ctx.setLineDash([15, 15])
                                            ctx.strokeRect(3, 3, width-6, height-6)
                                        }
                                    }

                                    // Dalga formu animasyon zamanlayıcısı
                                    Timer {
                                        interval: 25
                                        running: root.isActive
                                        repeat: true
                                        onTriggered: {
                                            if (spo2WaveformCanvas.hasValidData) {
                                                var speedMultiplier = Math.max(0.4, spo2WaveformCanvas.pulseRate / 75.0)
                                                spo2WaveformCanvas.phase += 6 * speedMultiplier
                                                spo2WaveformCanvas.currentTime += 0.025  // Zaman artırımı
                                            }
                                            spo2WaveformCanvas.spo2Value = root.spo2Numeric
                                            spo2WaveformCanvas.pulseRate = root.pulseNumeric > 0 ? root.pulseNumeric : 75
                                            spo2WaveformCanvas.hasValidData = root.spo2Value !== "Geçersiz" && root.spo2Value !== ""
                                            spo2WaveformCanvas.requestPaint()
                                        }
                                    }
                                }
                            }

                            // X Ekseni (Alt taraf)
                            Rectangle {
                                width: parent.width
                                height: 25
                                color: "#010409"

                                Row {
                                    anchors.fill: parent
                                    spacing: 0

                                    // X ekseni etiketleri (zaman)
                                    Repeater {
                                        model: 6  // 0s, 2s, 4s, 6s, 8s, 10s
                                        Rectangle {
                                            width: parent.width / 6
                                            height: parent.height
                                            color: "transparent"

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: parent.top
                                                anchors.topMargin: 5
                                                text: (index * 2) + "s"
                                                font.family: "Consolas, monospace"
                                                font.pointSize: 7
                                                color: "#656d76"
                                            }

                                            // X ekseni çizgisi
                                            Rectangle {
                                                width: 1
                                                height: 3
                                                color: "#30363d"
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: parent.top
                                            }
                                        }
                                    }
                                }

                                // X ekseni ana çizgisi
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#30363d"
                                    anchors.top: parent.top
                                }
                            }
                        }
                    }
                }
            }

            // Gelişmiş Status ve Alarm Panel
            Rectangle {
                width: parent.width
                height: 80
                color: "#21262d"
                radius: 8
                border.color: "#30363d"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Status Row
                    Row {
                        width: parent.width
                        height: 25
                        spacing: 15

                        Text {
                            text: qsTr("PATIENT STATUS:")
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#7d8590"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Hasta durumu göstergesi (NORMAL, HYPOXIC, CRITICAL)
                        Rectangle {
                            width: 80
                            height: 22
                            radius: 11
                            color: { // Duruma göre arka plan rengi
                                if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return "#21262d"
                                return root.spo2Numeric >= 95 ? "#0f5132" :
                                       (root.spo2Numeric >= 90 ? "#664d03" : "#58151c")
                            }
                            border.color: { // Duruma göre kenarlık rengi
                                if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return "#656d76"
                                return root.spo2Numeric >= 95 ? "#7ee787" :
                                       (root.spo2Numeric >= 90 ? "#ffa657" : "#ff7b72")
                            }
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return qsTr("NO DATA")
                                    return root.spo2Numeric >= 95 ? qsTr("NORMAL") :
                                           (root.spo2Numeric >= 90 ? qsTr("HYPOXIC") : qsTr("CRITICAL"))
                                }
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                font.bold: true
                                color: {
                                    if (root.spo2Value === "Geçersiz" || root.spo2Value === "") return "#656d76"
                                    return root.spo2Numeric >= 95 ? "#7ee787" :
                                           (root.spo2Numeric >= 90 ? "#ffa657" : "#ff7b72")
                                }
                            }
                        }

                        // Alarm göstergesi (yanıp sönen)
                        Rectangle {
                            width: 70
                            height: 22
                            radius: 11
                            color: (root.spo2Numeric < 88 && root.spo2Numeric > 0) ? "#58151c" : "#0d1117"
                            border.color: (root.spo2Numeric < 88 && root.spo2Numeric > 0) ? "#ff7b72" : "#30363d"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: (root.spo2Numeric < 88 && root.spo2Numeric > 0) ? qsTr("ALARM") : qsTr("MONITOR")
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                font.bold: true
                                color: (root.spo2Numeric < 88 && root.spo2Numeric > 0) ? "#ff7b72" : "#7d8590"
                            }

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: root.spo2Numeric < 88 && root.spo2Numeric > 0 && root.isActive
                                PropertyAnimation { from: 1.0; to: 0.3; duration: 400 }
                                PropertyAnimation { from: 0.3; to: 1.0; duration: 400 }
                            }
                        }
                    }

                    // Bilgi satırı
                    Row {
                        width: parent.width
                        spacing: 20

                        Text {
                            text: qsTr("Normal Range: 95-100%")
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#656d76"
                        }

                        Text {
                            text: "PI: " + (root.spo2Numeric > 0 ? (root.spo2Numeric * 0.12 / 10).toFixed(2) : "--") + "%"
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#656d76"
                        }

                        Text {
                            text: qsTr("Sensor: Finger")
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#656d76"
                        }

                        Rectangle {
                            width: 60
                            height: 16
                            radius: 8
                            color: "#0d1117"
                            border.color: "#30363d"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("RECORDING")
                                font.family: "Consolas, monospace"
                                font.pointSize: 7
                                color: "#58a6ff"
                            }

                            // Kayıt göstergesi (yanıp sönen nokta)
                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: root.spo2Value !== "Geçersiz" && root.spo2Value !== "" ? "#f85149" : "#656d76"
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: root.spo2Value !== "Geçersiz" && root.spo2Value !== "" && root.isActive
                                    PropertyAnimation { from: 1.0; to: 0.2; duration: 1000 }
                                    PropertyAnimation { from: 0.2; to: 1.0; duration: 1000 }
                                }
                            }
                        }
                    }
                }
            }
            // Status ve Alarm Panel'in altına eklenecek buton düzeni
            Rectangle {
                width: parent.width
                height: 60
                color: "#21262d"
                radius: 8
                border.color: "#30363d"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 20

                    // Veri Akışını Başlat Butonu


                    // Veri Tablosu Butonu
                    Button {
                        width: 180
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#2563eb" : (parent.hovered ? "#2d333b" : "#21262d")
                            radius: 6
                            border.color: "#58a6ff"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: qsTr("Veri Tablosu")
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            console.log("Butona tıklandı - veri akışı durduruluyor!")

                            // C++ backend'den veri akışını durdur
                            if (typeof mainWindow !== 'undefined' && mainWindow) {
                                mainWindow.stopDataStream()
                            }

                            // QML animasyonlarını durdur
                            root.isActive = false

                            // Sayfa geçişi
                            root.showMain2 = true

                            console.log("Veri akışı durduruldu ve main2.qml'e geçiliyor")
                        }
                    }
                }
            }




            Button {
                width: 200
                height: 35
                anchors.horizontalCenter: parent.horizontalCenter
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
                        root.isActive = true
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

