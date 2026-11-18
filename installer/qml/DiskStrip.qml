// A disk drawn to scale: what is on it now, as grey blocks, or the joe
// system that will be on it, filling as the installation proceeds. Drawn
// from plain rounded rectangles, so it looks the same with or without a GPU.
//
// With a layout, partitions are drawn where they lie on the disk and free
// space shows as the bare track; joe is drawn in `region` when it goes
// beside them, or across the whole disk when it replaces them. Without one,
// file systems are drawn side by side from the start.
import QtQuick

Rectangle {
    id: strip
    property var segments: []      // [{label, fraction}]
    property var layout: []        // [{label, start, size}], fractions of the disk
    property bool joe: false        // draw the new system
    property real fill: 1           // with joe: how much is written so far
    // With joe beside other systems: where it goes ({start, size}); null for
    // the whole disk.
    property var region: null
    readonly property int inset: 4
    readonly property real track: width - 2 * inset
    implicitHeight: 56
    radius: Theme.radius
    color: Theme.track

    // Existing file systems, side by side from the start of the disk.
    Row {
        visible: (!strip.joe || strip.region) && strip.layout.length === 0
        x: strip.inset
        y: strip.inset
        spacing: 2
        Repeater {
            model: strip.segments
            Block {
                required property var modelData
                required property int index
                width: Math.max(4, strip.track * modelData.fraction - 2)
                label: modelData.label
                shade: Theme.segmentShades[index % Theme.segmentShades.length]
            }
        }
    }

    // Partitions where they lie.
    Repeater {
        model: (!strip.joe || strip.region) ? strip.layout : []
        Block {
            required property var modelData
            required property int index
            x: strip.inset + strip.track * modelData.start
            y: strip.inset
            width: Math.max(4, strip.track * modelData.size - 2)
            label: modelData.label
            shade: Theme.segmentShades[index % Theme.segmentShades.length]
        }
    }

    // The new system: over the whole disk, or in the free space it takes.
    Rectangle {
        id: joeBlock
        readonly property real from: strip.region ? strip.region.start : 0
        readonly property real span: strip.region ? strip.region.size : 1
        visible: strip.joe && strip.fill > 0
        x: strip.inset + strip.track * from
        y: strip.inset
        height: strip.height - 2 * strip.inset
        width: Math.max(2 * radius, strip.track * span * Math.min(1, strip.fill))
        radius: Theme.radius - strip.inset
        color: Theme.accent
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }
    // With a region, a frame shows where joe goes before it is written.
    Rectangle {
        visible: strip.joe && strip.region !== null
        x: joeBlock.x
        y: joeBlock.y
        height: joeBlock.height
        width: Math.max(2 * radius, strip.track * joeBlock.span - 2)
        radius: joeBlock.radius
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
    }
    Text {
        visible: strip.joe
        anchors.verticalCenter: parent.verticalCenter
        x: joeBlock.x + 16
        width: Math.max(0, strip.track * joeBlock.span - 24)
        elide: Text.ElideRight
        text: "joe Linux"
        font.family: Theme.family
        font.pixelSize: Theme.bodySize
        font.weight: Font.Bold
        color: strip.fill > 0.25 ? Theme.onAccent : Theme.ink
    }

    component Block: Rectangle {
        property string label
        property color shade
        height: strip.height - 2 * strip.inset
        radius: Math.min(Theme.radius - strip.inset, width / 2)
        color: shade
        Text {
            anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
            text: parent.label
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
