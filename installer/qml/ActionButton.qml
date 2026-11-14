// A footer action. "suggested" is the one way forward; "destructive" is the
// one that erases a disk; plain buttons go back or step aside.
import QtQuick
import QtQuick.Controls.Basic

Button {
    id: control
    property string kind: "plain"   // plain, suggested, destructive

    font.family: Theme.family
    font.pixelSize: Theme.bodySize
    font.weight: kind === "plain" ? Font.Medium : Font.Bold
    padding: 12
    leftPadding: 22
    rightPadding: 22

    readonly property color fill: kind === "suggested" ? Theme.accent
                                : kind === "destructive" ? Theme.destructive
                                : Theme.track
    readonly property color label: kind === "suggested" ? Theme.onAccent
                                 : kind === "destructive" ? Theme.onDestructive
                                 : Theme.ink

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.label
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        implicitHeight: 44
        radius: 10
        color: control.fill
        opacity: control.enabled ? (control.down ? 0.8 : 1) : 0.4
        border.width: control.visualFocus ? 3 : 0
        border.color: Qt.alpha(Theme.accent, 0.5)
    }
}
