import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0

Item {
    id: settingsPage
    anchors.fill: parent

    signal navigateBack()

    // Settings - Ayarları kalıcı hale getirmek için
    Settings {
        id: settings
        property string frequency: "50Hz"
        property string mode: "Adult"
        property string averaging: "4sec"
    }

    // ButtonGroup'lar - Her kategori için ayrı grup
    ButtonGroup {
        id: frequencyGroup
        exclusive: true
    }

    ButtonGroup {
        id: modeGroup
        exclusive: true
    }

    ButtonGroup {
        id: averagingGroup
        exclusive: true
    }

    // Sayfa yüklendiğinde ayarları geri yükle
    Component.onCompleted: {
        restoreSettings()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 20
        color: "#1a1a1a"
        radius: 8
        border.color: "#333333"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Başlık Bölümü
            Row {
                width: parent.width
                spacing: 15

                Button {
                    width: 35
                    height: 35
                    background: Rectangle {
                        color: parent.pressed ? "#4a90e2" : "#2a2a2a"
                        radius: 4
                        border.color: "#4a90e2"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: "←"
                        font.pointSize: 16
                        font.bold: true
                        color: "#4a90e2"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: settingsPage.navigateBack()
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SPO2 AYARLARI"
                    font.pointSize: 18
                    font.bold: true
                    color: "#ffffff"
                }
            }

            // Ayarlar İçerik Bölümü
            Column {
                width: parent.width
                spacing: 25

                // Frequency Ayarı (Bits 1,0)
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "FREQUENCY "
                        font.pointSize: 12
                        font.bold: true
                        color: "#4a90e2"
                    }

                    Rectangle {
                        width: parent.width
                        height: 60
                        color: "#2a2a2a"
                        radius: 6
                        border.color: "#333333"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 30

                            RadioButton {
                                id: freq50Hz
                                text: "50 Hz (10)"
                                font.pointSize: 11
                                ButtonGroup.group: frequencyGroup
                                onCheckedChanged: {
                                    if (checked) {
                                        settings.frequency = "50Hz"
                                        calculateByteValue()
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    x: parent.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: 7
                                    color: "#1a1a1a"
                                    border.color: parent.checked ? "#4a90e2" : "#666666"
                                    border.width: 2

                                    Rectangle {
                                        width: 6
                                        height: 6
                                        x: 4
                                        y: 4
                                        radius: 3
                                        color: "#4a90e2"
                                        visible: parent.parent.checked
                                    }
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "#ffffff"
                                    leftPadding: parent.indicator.width + parent.spacing
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            RadioButton {
                                id: freq60Hz
                                text: "60 Hz (11)"
                                font.pointSize: 11
                                ButtonGroup.group: frequencyGroup
                                onCheckedChanged: {
                                    if (checked) {
                                        settings.frequency = "60Hz"
                                        calculateByteValue()
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    x: parent.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: 7
                                    color: "#1a1a1a"
                                    border.color: parent.checked ? "#4a90e2" : "#666666"
                                    border.width: 2

                                    Rectangle {
                                        width: 6
                                        height: 6
                                        x: 4
                                        y: 4
                                        radius: 3
                                        color: "#4a90e2"
                                        visible: parent.parent.checked
                                    }
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "#ffffff"
                                    leftPadding: parent.indicator.width + parent.spacing
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }

                // Mode Ayarı (Bits 4,3,2)
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "MOD "
                        font.pointSize: 12
                        font.bold: true
                        color: "#e74c3c"
                    }

                    Rectangle {
                        width: parent.width
                        height: 90
                        color: "#2a2a2a"
                        radius: 6
                        border.color: "#333333"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 25

                                RadioButton {
                                    id: modeAdult
                                    text: "Adult (100)"
                                    font.pointSize: 11
                                    ButtonGroup.group: modeGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.mode = "Adult"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 7
                                        color: "#1a1a1a"
                                        border.color: parent.checked ? "#e74c3c" : "#666666"
                                        border.width: 2

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            x: 4
                                            y: 4
                                            radius: 3
                                            color: "#e74c3c"
                                            visible: parent.parent.checked
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#ffffff"
                                        leftPadding: parent.indicator.width + parent.spacing
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                RadioButton {
                                    id: modeNewborn
                                    text: "Newborn (101)"
                                    font.pointSize: 11
                                    ButtonGroup.group: modeGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.mode = "Newborn"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 7
                                        color: "#1a1a1a"
                                        border.color: parent.checked ? "#e74c3c" : "#666666"
                                        border.width: 2

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            x: 4
                                            y: 4
                                            radius: 3
                                            color: "#e74c3c"
                                            visible: parent.parent.checked
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#ffffff"
                                        leftPadding: parent.indicator.width + parent.spacing
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 25

                                RadioButton {
                                    id: modePediatric
                                    text: "Pediatric (110)"
                                    font.pointSize: 11
                                    ButtonGroup.group: modeGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.mode = "Pediatric"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 7
                                        color: "#1a1a1a"
                                        border.color: parent.checked ? "#e74c3c" : "#666666"
                                        border.width: 2

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            x: 4
                                            y: 4
                                            radius: 3
                                            color: "#e74c3c"
                                            visible: parent.parent.checked
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#ffffff"
                                        leftPadding: parent.indicator.width + parent.spacing
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Averaging Ayarı (Bits 7,6,5)
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "AVERAGING "
                        font.pointSize: 12
                        font.bold: true
                        color: "#27ae60"
                    }

                    Rectangle {
                        width: parent.width
                        height: 90
                        color: "#2a2a2a"
                        radius: 6
                        border.color: "#333333"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 25

                                RadioButton {
                                    id: avg4sec
                                    text: "4 sec (100)"
                                    font.pointSize: 11
                                    ButtonGroup.group: averagingGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.averaging = "4sec"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 7
                                        color: "#1a1a1a"
                                        border.color: parent.checked ? "#27ae60" : "#666666"
                                        border.width: 2

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            x: 4
                                            y: 4
                                            radius: 3
                                            color: "#27ae60"
                                            visible: parent.parent.checked
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#ffffff"
                                        leftPadding: parent.indicator.width + parent.spacing
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                RadioButton {
                                    id: avg8sec
                                    text: "8 sec (101)"
                                    font.pointSize: 11
                                    ButtonGroup.group: averagingGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.averaging = "8sec"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 7
                                        color: "#1a1a1a"
                                        border.color: parent.checked ? "#27ae60" : "#666666"
                                        border.width: 2

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            x: 4
                                            y: 4
                                            radius: 3
                                            color: "#27ae60"
                                            visible: parent.parent.checked
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#ffffff"
                                        leftPadding: parent.indicator.width + parent.spacing
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 25

                                RadioButton {
                                    id: avg16sec
                                    text: "16 sec (110)"
                                    font.pointSize: 11
                                    ButtonGroup.group: averagingGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.averaging = "16sec"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 14
                                        implicitHeight: 14
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 7
                                        color: "#1a1a1a"
                                        border.color: parent.checked ? "#27ae60" : "#666666"
                                        border.width: 2

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            x: 4
                                            y: 4
                                            radius: 3
                                            color: "#27ae60"
                                            visible: parent.parent.checked
                                        }
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font: parent.font
                                        color: "#ffffff"
                                        leftPadding: parent.indicator.width + parent.spacing
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Hesaplanan Değer Gösterimi
                Rectangle {
                    width: parent.width
                    height: 60
                    color: "#2a2a2a"
                    radius: 6
                    border.color: "#f39c12"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "HESAPLANAN DEĞER"
                            font.pointSize: 10
                            font.bold: true
                            color: "#f39c12"
                        }

                        Text {
                            id: calculatedValue
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Dec: 146 | Hex: 0x92 | Bin: 10010010"
                            font.pointSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                }

                // Butonlar
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Button {
                        width: 120
                        height: 40
                        background: Rectangle {
                            color: parent.pressed ? "#229954" : "#27ae60"
                            radius: 6
                        }
                        contentItem: Text {
                            text: "Gönder"
                            font.pointSize: 12
                            font.bold: true
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            var settings = getSettingsComponents()

                            if (typeof mainWindow !== "undefined" && mainWindow.sendSpo2SettingsFromQml) {
                                mainWindow.sendSpo2SettingsFromQml(settings.frequency, settings.mode, settings.averaging)
                            } else {
                                console.log("mainWindow.sendSpo2SettingsFromQml tanımlı değil!")
                            }

                            settingsPage.navigateBack()
                        }
                    }



                    Button {
                        width: 100
                        height: 40
                        background: Rectangle {
                            color: parent.pressed ? "#c0392b" : "#e74c3c"
                            radius: 6
                        }
                        contentItem: Text {
                            text: "İptal"
                            font.pointSize: 12
                            font.bold: true
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            settingsPage.navigateBack()
                        }
                    }
                }
            }
        }
    }

    // Ayarları geri yükle
    function restoreSettings() {
        // Frequency ayarlarını geri yükle
        if (settings.frequency === "50Hz") {
            freq50Hz.checked = true
        } else {
            freq60Hz.checked = true
        }

        // Mode ayarlarını geri yükle
        if (settings.mode === "Adult") {
            modeAdult.checked = true
        } else if (settings.mode === "Newborn") {
            modeNewborn.checked = true
        } else {
            modePediatric.checked = true
        }

        // Averaging ayarlarını geri yükle
        if (settings.averaging === "4sec") {
            avg4sec.checked = true
        } else if (settings.averaging === "8sec") {
            avg8sec.checked = true
        } else {
            avg16sec.checked = true
        }

        // Hesaplanan değeri güncelle
        calculateByteValue()
    }

    // Byte değerini hesaplayan fonksiyon
    function calculateByteValue() {
        var byteValue = 0

        // Bits 1,0 - Frequency
        if (freq50Hz.checked) {
            byteValue |= 0b10  // 50Hz = 10
        } else {
            byteValue |= 0b11  // 60Hz = 11
        }

        // Bits 4,3,2 - Mode
        if (modeAdult.checked) {
            byteValue |= (0b100 << 2)  // Adult = 100
        } else if (modeNewborn.checked) {
            byteValue |= (0b101 << 2)  // Newborn = 101
        } else {
            byteValue |= (0b110 << 2)  // Pediatric = 110
        }

        // Bits 7,6,5 - Averaging
        if (avg4sec.checked) {
            byteValue |= (0b100 << 5)  // 4 sec = 100
        } else if (avg8sec.checked) {
            byteValue |= (0b101 << 5)  // 8 sec = 101
        } else {
            byteValue |= (0b110 << 5)  // 16 sec = 110
        }

        calculatedValue.text = "Dec: " + byteValue + " | Hex: 0x" + byteValue.toString(16).toUpperCase() + " | Bin: " + (byteValue >>> 0).toString(2).padStart(8, '0')

        return byteValue
    }

    function getSettingsComponents() {
        var frequency = freq50Hz.checked ? 50 : 60
        var mode = modeAdult.checked ? 0 : (modeNewborn.checked ? 1 : 2)
        var averaging = avg4sec.checked ? 4 : (avg8sec.checked ? 8 : 16)
        return { frequency: frequency, mode: mode, averaging: averaging }
    }
}
