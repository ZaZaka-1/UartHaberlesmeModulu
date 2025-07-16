import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0

Item {
    id: settingsPage
    anchors.fill: parent

    signal navigateBack()
    signal ageGroupChanged(string ageGroup)

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
        anchors.margins: 15
        radius: 10
        color: "#161b22"
        border.color: "#30363d"
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 20

            // Başlık Bölümü
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
                        width: 35
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : "#21262d"
                            radius: 6
                            border.color: "#58a6ff"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: "←"
                            font.pointSize: 16
                            font.bold: true
                            color: "#58a6ff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: settingsPage.navigateBack()
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SPO2 AYARLARI"
                        font.family: "Consolas, monospace"
                        font.pointSize: 12
                        font.bold: true
                        color: "#58a6ff"
                    }
                }
            }

            // Ayarlar İçerik Bölümü
            Column {
                width: parent.width
                spacing: 20

                // Frequency Ayarı (Bits 1,0)
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "FREQUENCY"
                        font.family: "Consolas, monospace"
                        font.pointSize: 12
                        font.bold: true
                        color: "#58a6ff"
                    }

                    Rectangle {
                        width: parent.width
                        height: 60
                        color: "#21262d"
                        radius: 8
                        border.color: "#30363d"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 40

                            RadioButton {
                                id: freq50Hz
                                text: "50 Hz (10)"
                                font.family: "Consolas, monospace"
                                font.pointSize: 10
                                ButtonGroup.group: frequencyGroup
                                onCheckedChanged: {
                                    if (checked) {
                                        settings.frequency = "50Hz"
                                        calculateByteValue()
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    x: parent.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: 8
                                    color: "#0d1117"
                                    border.color: parent.checked ? "#58a6ff" : "#7d8590"
                                    border.width: 2

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        x: 4
                                        y: 4
                                        radius: 4
                                        color: "#58a6ff"
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
                                font.family: "Consolas, monospace"
                                font.pointSize: 10
                                ButtonGroup.group: frequencyGroup
                                onCheckedChanged: {
                                    if (checked) {
                                        settings.frequency = "60Hz"
                                        calculateByteValue()
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    x: parent.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: 8
                                    color: "#0d1117"
                                    border.color: parent.checked ? "#58a6ff" : "#7d8590"
                                    border.width: 2

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        x: 4
                                        y: 4
                                        radius: 4
                                        color: "#58a6ff"
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

                // Mode Ayarı (Bits 4,3,2) - Yaş Grupları
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "YAŞ GRUBU (MOD)"
                        font.family: "Consolas, monospace"
                        font.pointSize: 12
                        font.bold: true
                        color: "#ff7b72"
                    }

                    Rectangle {
                        width: parent.width
                        height: 120
                        color: "#21262d"
                        radius: 8
                        border.color: "#30363d"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 15

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 30

                                RadioButton {
                                    id: modeAdult
                                    text: "Adult (100)"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    ButtonGroup.group: modeGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.mode = "Adult"
                                            calculateByteValue()
                                            updateAgeGroupInfo()
                                            settingsPage.ageGroupChanged("Adult")
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 8
                                        color: "#0d1117"
                                        border.color: parent.checked ? "#ff7b72" : "#7d8590"
                                        border.width: 2

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            x: 4
                                            y: 4
                                            radius: 4
                                            color: "#ff7b72"
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
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    ButtonGroup.group: modeGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.mode = "Newborn"
                                            calculateByteValue()
                                            updateAgeGroupInfo()
                                            settingsPage.ageGroupChanged("Newborn")
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 8
                                        color: "#0d1117"
                                        border.color: parent.checked ? "#ff7b72" : "#7d8590"
                                        border.width: 2

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            x: 4
                                            y: 4
                                            radius: 4
                                            color: "#ff7b72"
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
                                spacing: 30

                                RadioButton {
                                    id: modePediatric
                                    text: "Pediatric (110)"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    ButtonGroup.group: modeGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.mode = "Pediatric"
                                            calculateByteValue()
                                            updateAgeGroupInfo()
                                            settingsPage.ageGroupChanged("Pediatric")
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 8
                                        color: "#0d1117"
                                        border.color: parent.checked ? "#ff7b72" : "#7d8590"
                                        border.width: 2

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            x: 4
                                            y: 4
                                            radius: 4
                                            color: "#ff7b72"
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

                    // Yaş grubu bilgi metni - Güncellenmiş
                    Rectangle {
                        width: parent.width
                        height: 80
                        color: "#0d1117"
                        radius: 6
                        border.color: "#30363d"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                id: ageGroupInfo
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Yaş grubu seçin"
                                font.family: "Consolas, monospace"
                                font.pointSize: 10
                                font.bold: true
                                color: "#7d8590"
                            }

                            Text {
                                id: ageGroupRanges
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: ""
                                font.family: "Consolas, monospace"
                                font.pointSize: 9
                                color: "#58a6ff"
                            }

                            Text {
                                id: ageGroupPulseRange
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: ""
                                font.family: "Consolas, monospace"
                                font.pointSize: 9
                                color: "#7ee787"
                            }
                        }
                    }
                }

                // Averaging Ayarı (Bits 7,6,5)
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "AVERAGING"
                        font.family: "Consolas, monospace"
                        font.pointSize: 12
                        font.bold: true
                        color: "#7ee787"
                    }

                    Rectangle {
                        width: parent.width
                        height: 120
                        color: "#21262d"
                        radius: 8
                        border.color: "#30363d"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 15

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 30

                                RadioButton {
                                    id: avg4sec
                                    text: "4 sec (100)"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    ButtonGroup.group: averagingGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.averaging = "4sec"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 8
                                        color: "#0d1117"
                                        border.color: parent.checked ? "#7ee787" : "#7d8590"
                                        border.width: 2

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            x: 4
                                            y: 4
                                            radius: 4
                                            color: "#7ee787"
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
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    ButtonGroup.group: averagingGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.averaging = "8sec"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 8
                                        color: "#0d1117"
                                        border.color: parent.checked ? "#7ee787" : "#7d8590"
                                        border.width: 2

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            x: 4
                                            y: 4
                                            radius: 4
                                            color: "#7ee787"
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
                                spacing: 30

                                RadioButton {
                                    id: avg16sec
                                    text: "16 sec (110)"
                                    font.family: "Consolas, monospace"
                                    font.pointSize: 10
                                    ButtonGroup.group: averagingGroup
                                    onCheckedChanged: {
                                        if (checked) {
                                            settings.averaging = "16sec"
                                            calculateByteValue()
                                        }
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: parent.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 8
                                        color: "#0d1117"
                                        border.color: parent.checked ? "#7ee787" : "#7d8590"
                                        border.width: 2

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            x: 4
                                            y: 4
                                            radius: 4
                                            color: "#7ee787"
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
                    height: 70
                    color: "#21262d"
                    radius: 8
                    border.color: "#ffa500"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "HESAPLANAN DEĞER"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#ffa500"
                        }

                        Text {
                            id: calculatedValue
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Dec: 146 | Hex: 0x92 | Bin: 10010010"
                            font.family: "Consolas, monospace"
                            font.pointSize: 11
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
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#238636" : "#21262d"
                            radius: 6
                            border.color: "#7ee787"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: "Gönder"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#7ee787"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            var settingsData = getSettingsComponents()

                            if (typeof mainWindow !== "undefined" && mainWindow.sendSpo2SettingsFromQml) {
                                mainWindow.sendSpo2SettingsFromQml(settingsData.frequency, settingsData.mode, settingsData.averaging)
                                console.log("Ayarlar gönderildi:", settingsData)
                            } else {
                                console.log("mainWindow.sendSpo2SettingsFromQml tanımlı değil!")
                            }

                            settingsPage.navigateBack()
                        }
                    }

                    Button {
                        width: 120
                        height: 35
                        background: Rectangle {
                            color: parent.pressed ? "#da3633" : "#21262d"
                            radius: 6
                            border.color: "#ff7b72"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: "İptal"
                            font.family: "Consolas, monospace"
                            font.pointSize: 10
                            font.bold: true
                            color: "#ff7b72"
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

    // Yaş grubu bilgilerini güncelleyen fonksiyon
    function updateAgeGroupInfo() {
        if (modeAdult.checked) {
            ageGroupInfo.text = "Adult Mode - Yetişkin"
            ageGroupRanges.text = "SpO2: 70-100% (Geçersiz: <70 veya >100)"
            ageGroupPulseRange.text = "Pulse: 30-240 bpm (Geçersiz: <30 veya >240)"
        } else if (modeNewborn.checked) {
            ageGroupInfo.text = "Newborn Mode - Yenidoğan"
            ageGroupRanges.text = "SpO2: 85-100% (Geçersiz: <85 veya >100)"
            ageGroupPulseRange.text = "Pulse: 80-180 bpm (Geçersiz: <80 veya >180)"
        } else if (modePediatric.checked) {
            ageGroupInfo.text = "Pediatric Mode - Pediatrik"
            ageGroupRanges.text = "SpO2: 75-100% (Geçersiz: <75 veya >100)"
            ageGroupPulseRange.text = "Pulse: 60-200 bpm (Geçersiz: <60 veya >200)"
        } else {
            ageGroupInfo.text = "Yaş grubu seçin"
            ageGroupRanges.text = ""
            ageGroupPulseRange.text = ""
        }
    }

    // Ayarları geri yükle
    function restoreSettings() {
        console.log("Ayarlar geri yükleniyor...")

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

        // Yaş grubu bilgilerini güncelle
        updateAgeGroupInfo()

        // Ana sayfaya mevcut yaş grubunu bildir
        settingsPage.ageGroupChanged(settings.mode)
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
