import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

PageFrame {
    id: page
    property var disk: ({})
    // Into the free space, keeping what is on the disk.
    property bool beside: false
    property alias understood: understood.checked
    signal back()
    signal proceed()

    title: beside ? qsTr("Install beside %1?").arg(disk.besideWhat) : qsTr("Erase %1?").arg(disk.name)
    body: beside
        ? qsTr("joe Linux goes into the %1 of free space on %2. %3 and everything else on the disk are kept. When the computer starts, a menu lets you choose which system to use; it starts joe Linux unless you choose otherwise.")
            .arg(disk.besideSizeText).arg(disk.name).arg(disk.besideWhat)
        : qsTr("Everything on %1 (%2) is deleted and joe Linux is installed in its place. This can't be undone.").arg(disk.name).arg(disk.sizeText)

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
        layout: page.disk.layout || []
        Text {
            visible: (!page.disk.segments || page.disk.segments.length === 0) && (!page.disk.layout || page.disk.layout.length === 0)
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
    DiskStrip {
        Layout.fillWidth: true
        joe: true
        layout: page.beside ? (page.disk.layout || []) : []
        region: page.beside ? { start: page.disk.besideStart, size: page.disk.besideFraction } : null
    }

    CheckBox {
        id: understood
        visible: !page.beside
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
            text: page.beside ? qsTr("Install") : qsTr("Erase and Install")
            kind: page.beside ? "suggested" : "destructive"
            enabled: page.beside || understood.checked
            onClicked: page.proceed()
        }
    ]
}
