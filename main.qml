import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    visible: true
    width: 480
    height: 600
    title: qsTr("SPO2 Vital Takip")
    color: "#0f1419"  // Koyu medikal tema

    // Ana içerik kutusu
    Rectangle {
        anchors.fill: parent
        anchors.margins: 20
        radius: 8
        color: "#1a1f29"
        border.color: "#2d3748"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Başlık ve durum çubuğu
            Rectangle {
                width: parent.width
                height: 50
                color: "#2d3748"
                radius: 6
                border.color: "#4a5568"
                border.width: 1

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    spacing: 10

                    Text {
                        text: qsTr("PATIENT MONITOR")
                        font.family: "Consolas, monospace"
                        font.pointSize: 11
                        font.bold: true
                        color: "#00ff88"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: "#00ff88"
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            PropertyAnimation { from: 1.0; to: 0.3; duration: 800 }
                            PropertyAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(new Date(), "hh:mm:ss")
                    font.family: "Consolas, monospace"
                    font.pointSize: 10
                    color: "#a0aec0"

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                    }
                }
            }

            // Vital Signs Row
            Row {
                width: parent.width
                height: 120
                spacing: 10

                // SPO2 Panel
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    color: "#2d3748"
                    radius: 6
                    border.color: "#0ea5e9"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: qsTr("SpO2")
                            font.family: "Consolas, monospace"
                            font.pointSize: 11
                            font.bold: true
                            color: "#0ea5e9"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: backend.spo2Value + "%"
                            font.family: "Consolas, monospace"
                            font.pointSize: 32
                            font.bold: true
                            color: "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: qsTr("Oxygen Saturation")
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#a0aec0"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Heart Rate Panel
                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    color: "#2d3748"
                    radius: 6
                    border.color: "#ef4444"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: qsTr("Heart Rate")
                            font.family: "Consolas, monospace"
                            font.pointSize: 11
                            font.bold: true
                            color: "#ef4444"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Text {
                                text: backend.pulseValue
                                font.family: "Consolas, monospace"
                                font.pointSize: 32
                                font.bold: true
                                color: "#ffffff"
                            }

                            Text {
                                id: heartBeat
                                text: "♥"
                                font.family: "Consolas, monospace"
                                font.pointSize: 20
                                color: "#ef4444"
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on scale {
                                    loops: Animation.Infinite
                                    running: true
                                    PropertyAnimation { from: 1.0; to: 1.4; duration: 100 }
                                    PropertyAnimation { from: 1.4; to: 1.0; duration: 100 }
                                    PropertyAnimation { from: 1.0; to: 1.2; duration: 80 }
                                    PropertyAnimation { from: 1.2; to: 1.0; duration: 80 }
                                    PauseAnimation { duration: 600 }
                                }
                            }
                        }

                        Text {
                            text: qsTr("BPM")
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#a0aec0"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // Waveform Monitor
            Rectangle {
                width: parent.width
                height: 200
                color: "#1a1f29"
                radius: 6
                border.color: "#2d3748"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 10

                    // Waveform Header
                    Rectangle {
                        width: parent.width
                        height: 25
                        color: "#2d3748"
                        radius: 4

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            spacing: 15

                            Text {
                                text: qsTr("ECG WAVEFORM")
                                font.family: "Consolas, monospace"
                                font.pointSize: 9
                                font.bold: true
                                color: "#00ff88"
                            }

                            Text {
                                text: "25mm/s"
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                color: "#a0aec0"
                            }

                            Text {
                                text: "10mm/mV"
                                font.family: "Consolas, monospace"
                                font.pointSize: 8
                                color: "#a0aec0"
                            }
                        }
                    }

                    // Waveform Display
                    Rectangle {
                        width: parent.width
                        height: parent.height - 35
                        color: "#0f1419"
                        radius: 4

                        Canvas {
                            id: waveformCanvas
                            anchors.fill: parent
                            anchors.margins: 5

                            property real phase: 0

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                // Grid çizgileri (medikal monitör tarzı)
                                ctx.strokeStyle = "#1a4d3a"
                                ctx.lineWidth = 0.5

                                // Dikey gridler
                                for (var i = 0; i < width; i += 10) {
                                    ctx.beginPath()
                                    ctx.moveTo(i, 0)
                                    ctx.lineTo(i, height)
                                    ctx.stroke()
                                }

                                // Yatay gridler
                                for (var j = 0; j < height; j += 10) {
                                    ctx.beginPath()
                                    ctx.moveTo(0, j)
                                    ctx.lineTo(width, j)
                                    ctx.stroke()
                                }

                                // Kalın grid çizgileri (5'er aralıkla)
                                ctx.strokeStyle = "#2d5a3d"
                                ctx.lineWidth = 1

                                for (var k = 0; k < width; k += 50) {
                                    ctx.beginPath()
                                    ctx.moveTo(k, 0)
                                    ctx.lineTo(k, height)
                                    ctx.stroke()
                                }

                                for (var l = 0; l < height; l += 50) {
                                    ctx.beginPath()
                                    ctx.moveTo(0, l)
                                    ctx.lineTo(width, l)
                                    ctx.stroke()
                                }

                                // ECG Waveform
                                ctx.strokeStyle = "#00ff88"
                                ctx.lineWidth = 2
                                ctx.beginPath()

                                for (var x = 0; x < width; x++) {
                                    var normalizedX = (x + phase) / width * 4 * Math.PI
                                    var ecgWave = 0

                                    // QRS kompleksi simülasyonu
                                    var beatPosition = normalizedX % (2 * Math.PI)
                                    if (beatPosition < 0.3) {
                                        ecgWave = Math.sin(beatPosition * 10) * 0.3
                                    } else if (beatPosition < 0.5) {
                                        ecgWave = Math.sin((beatPosition - 0.3) * 20) * 1.5
                                    } else if (beatPosition < 0.8) {
                                        ecgWave = Math.sin((beatPosition - 0.5) * 15) * -0.8
                                    } else {
                                        ecgWave = Math.sin((beatPosition - 0.8) * 8) * 0.2
                                    }

                                    var y = height/2 - ecgWave * 30

                                    if (x === 0) {
                                        ctx.moveTo(x, y)
                                    } else {
                                        ctx.lineTo(x, y)
                                    }
                                }
                                ctx.stroke()
                            }

                            Timer {
                                interval: 50
                                running: true
                                repeat: true
                                onTriggered: {
                                    waveformCanvas.phase += 8
                                    waveformCanvas.requestPaint()
                                }
                            }
                        }
                    }
                }
            }

            // Alarm ve Status Panel
            Rectangle {
                width: parent.width
                height: 60
                color: "#2d3748"
                radius: 6
                border.color: "#4a5568"
                border.width: 1

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    spacing: 20

                    Text {
                        text: qsTr("STATUS:")
                        font.family: "Consolas, monospace"
                        font.pointSize: 10
                        font.bold: true
                        color: "#a0aec0"
                    }

                    Rectangle {
                        width: 60
                        height: 25
                        radius: 12
                        color: "#065f46"
                        border.color: "#00ff88"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("NORMAL")
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            font.bold: true
                            color: "#00ff88"
                        }
                    }

                    Text {
                        text: qsTr("ALARMS:")
                        font.family: "Consolas, monospace"
                        font.pointSize: 10
                        font.bold: true
                        color: "#a0aec0"
                    }

                    Rectangle {
                        width: 50
                        height: 25
                        radius: 12
                        color: "#1f2937"
                        border.color: "#6b7280"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("OFF")
                            font.family: "Consolas, monospace"
                            font.pointSize: 8
                            color: "#6b7280"
                        }
                    }
                }
            }
        }
    }
}
