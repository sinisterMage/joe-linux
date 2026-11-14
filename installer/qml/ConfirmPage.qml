import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

PageFrame {
    id: page
    property var disk: ({})
    property alias understood: understood.checked
    signal back()
    signal proceed()

    title: qsTr("Erase %1?").arg(disk.name)
    body: qsTr("Everything on %1 (%2) is deleted and joe Linux is installed in its place. This can't be undone.").arg(disk.name).arg(disk.sizeText)

    Text {
        text: qsTr("The disk now")
        font.family: Theme.family
        font.pixelSize: Theme.smallSize
        font.weight: Font.Medium
        color: Theme.muted
    }
    DiskStrip {
        Layout.fillWidth: true
        segments: page.disk.segments || []
        Text {
            visible: !page.disk.segments || page.disk.segments.length === 0
            anchors.centerIn: parent
            text: qsTr("Nothing the installer recognizes")
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
            color: Theme.muted
        }
    }
    Text {
        text: qsTr("After installing")
        topPadding: 6
        font.family: Theme.family
        font.pixelSize: Theme.smallSize
        font.weight: Font.Medium
        color: Theme.muted
    }
    DiskStrip { Layout.fillWidth: true; joe: true }

    CheckBox {
        id: understood
        Layout.topMargin: 14
        Layout.fillWidth: true
        text: qsTr("I understand that everything on %1 will be erased").arg(page.disk.name)
        font.family: Theme.family
        font.pixelSize: Theme.bodySize
        indicator: Rectangle {
            x: understood.leftPadding
            y: (understood.height - height) / 2
            width: 22; height: 22; radius: 6
            color: understood.checked ? Theme.destructive : "transparent"
            border.width: understood.checked ? 0 : 2
            border.color: understood.visualFocus ? Theme.accent : Theme.muted
            Text {
                anchors.centerIn: parent
                visible: understood.checked
                text: "✓"
                font.pixelSize: 15
                font.weight: Font.Black
                color: Theme.onDestructive
            }
        }
        contentItem: Text {
            leftPadding: understood.indicator.width + 12
            text: understood.text
            font: understood.font
            wrapMode: Text.Wrap
            color: Theme.ink
            verticalAlignment: Text.AlignVCenter
        }
    }

    actions: [
        ActionButton { text: qsTr("Back"); onClicked: page.back() },
        Item { Layout.fillWidth: true },
        ActionButton {
            text: qsTr("Erase and Install")
            kind: "destructive"
            enabled: understood.checked
            onClicked: page.proceed()
        }
    ]
}
