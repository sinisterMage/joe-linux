import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

PageFrame {
    id: page
    property bool details: false

    title: qsTr("Installing joe Linux")
    body: Backend.step

    // The disk being installed onto, as the confirmation page drew it.
    property var disk: ({})
    property bool beside: false

    DiskStrip {
        Layout.fillWidth: true
        joe: true
        fill: Backend.progress
        layout: page.beside ? (page.disk.layout || []) : []
        region: page.beside ? { start: page.disk.besideStart, size: page.disk.besideFraction } : null
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: qsTr("This takes a few minutes. The computer stays awake until it is done.")
        font.family: Theme.family
        font.pixelSize: Theme.smallSize
        color: Theme.muted
    }
    Log { visible: page.details }

    actions: [
        ActionButton {
            text: page.details ? qsTr("Hide Details") : qsTr("Show Details")
            onClicked: page.details = !page.details
        },
        Item { Layout.fillWidth: true }
    ]

    component Log: ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 240
        clip: true
        background: Rectangle { radius: Theme.radius; color: Theme.surface; border.width: 1; border.color: Theme.hairline }
        TextArea {
            id: logText
            readOnly: true
            text: Backend.log
            wrapMode: TextEdit.Wrap
            font.family: Theme.monoFamily
            font.pixelSize: Theme.smallSize - 1
            color: Theme.ink
            padding: 14
            background: null
            onTextChanged: cursorPosition = length
        }
    }
}
