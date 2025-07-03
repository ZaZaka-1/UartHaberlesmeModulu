import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page2
    signal navigateBack()  // Geri dönüş sinyali

    property var measurements: []

    Component.onCompleted: {
        loadMeasurements()
    }

    // Yeni ölçüm eklendiğinde tabloyu güncelle
    Connections {
        target: mainWindow
        function onMeasurementAdded() {
            loadMeasurements()
        }
    }

    function loadMeasurements() {
        measurements = mainWindow.getRecentMeasurements(100) // Son 100 ölçüm
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
                text: "Ölçüm Verileri"
                font.pixelSize: 24
                font.family: "Consolas, monospace"
                color: "#58a6ff"
                Layout.alignment: Qt.AlignHCenter
            }

            // Üst kısım - Bilgiler ve butonlar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Toplam Ölçüm: " + mainWindow.getMeasurementCount()
                    font.family: "Consolas, monospace"
                    font.pointSize: 10
                    font.bold: true
                    color: "#58a6ff"
                }

                Item { Layout.fillWidth: true } // Spacer

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
                    onClicked: loadMeasurements()
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
                        mainWindow.clearMeasurements()
                        loadMeasurements()
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
                                text: modelData.id
                                font.family: "Consolas, monospace"
                                color: "#f0f6fc"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.preferredWidth: 150
                                text: modelData.timestamp
                                font.family: "Consolas, monospace"
                                color: "#f0f6fc"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.preferredWidth: 100
                                text: modelData.spo2
                                font.family: "Consolas, monospace"
                                horizontalAlignment: Text.AlignHCenter
                                color: modelData.spo2 === "Geçersiz" ? "#ff6b6b" : "#7ee787"
                            }

                            Text {
                                Layout.preferredWidth: 100
                                text: modelData.pulse
                                font.family: "Consolas, monospace"
                                horizontalAlignment: Text.AlignHCenter
                                color: modelData.pulse === "Geçersiz" ? "#ff6b6b" : "#7ee787"
                            }
                        }
                    }
                }
            }

            // Geri dönüş butonu
            Button {
                id: backButton
                width: 200
                height: 40
                Layout.alignment: Qt.AlignHCenter
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
                    console.log("navigateBack sinyali gönderildi.")
                    page2.navigateBack()
                }
            }
        }
    }
}
