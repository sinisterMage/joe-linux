// A disk drawn to scale: what is on it now, as grey blocks, or the joe
// system that replaces it, filling as the installation proceeds. Drawn from
// plain rounded rectangles, so it looks the same with or without a GPU.
import QtQuick

Rectangle {
    id: strip
    property var segments: []      // [{label, fraction}]
    property bool joe: false        // draw the new system instead
    property real fill: 1           // with joe: how much is written so far
    readonly property int inset: 4
    implicitHeight: 56
    radius: Theme.radius
    color: Theme.track

    // Existing file systems, side by side from the start of the disk.
    Row {
        visible: !strip.joe
        x: strip.inset
        y: strip.inset
        spacing: 2
        Repeater {
            model: strip.segments
            Rectangle {
                required property var modelData
                required property int index
                width: Math.max(4, (strip.width - 2 * strip.inset) * modelData.fraction - 2)
                height: strip.height - 2 * strip.inset
                radius: Math.min(Theme.radius - strip.inset, width / 2)
                color: Theme.segmentShades[index % Theme.segmentShades.length]
                Text {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                    text: modelData.label
                    visible: parent.width > 64
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    font.family: Theme.family
                    font.pixelSize: Theme.smallSize
                    font.weight: Font.Medium
                    color: "#ffffff"
                }
            }
        }
    }

    // The new system, written from the start of the disk.
    Rectangle {
        visible: strip.joe && strip.fill > 0
        x: strip.inset
        y: strip.inset
        height: strip.height - 2 * strip.inset
        width: Math.max(2 * radius, (strip.width - 2 * strip.inset) * Math.min(1, strip.fill))
        radius: Theme.radius - strip.inset
        color: Theme.accent
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }
    Text {
        visible: strip.joe
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 20 }
        text: "joe Linux"
        font.family: Theme.family
        font.pixelSize: Theme.bodySize
        font.weight: Font.Bold
        color: strip.fill > 0.25 ? Theme.onAccent : Theme.ink
    }
}
