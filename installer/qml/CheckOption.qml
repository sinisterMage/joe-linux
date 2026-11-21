// A check box drawn in the installer's own look: a rounded square filled
// with `tint` when checked, and its text wrapped beside it.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

CheckBox {
    id: box
    property color tint: Theme.accent
    property color onTint: Theme.onAccent

    Layout.fillWidth: true
    font.family: Theme.family
    font.pixelSize: Theme.bodySize
    indicator: Rectangle {
        x: box.leftPadding
        y: (box.height - height) / 2
        width: 22; height: 22; radius: 6
        color: box.checked ? box.tint : "transparent"
        border.width: box.checked ? 0 : 2
        border.color: box.visualFocus ? Theme.accent : Theme.muted
        Text {
            anchors.centerIn: parent
            visible: box.checked
            text: "✓"
            font.pixelSize: 15
            font.weight: Font.Black
            color: box.onTint
        }
    }
    contentItem: Text {
        leftPadding: box.indicator.width + 12
        text: box.text
        font: box.font
        wrapMode: Text.Wrap
        color: Theme.ink
        verticalAlignment: Text.AlignVCenter
    }
}
