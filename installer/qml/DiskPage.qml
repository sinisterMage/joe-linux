import QtQuick
import QtQuick.Layouts

PageFrame {
    id: page
    property int chosen: -1
    signal back()
    signal proceed()

    title: qsTr("Choose a disk")
    body: qsTr("joe Linux is installed on the whole disk you choose. You confirm before anything is erased.")

    Text {
        visible: Backend.state === Backend.Listing
        text: qsTr("Looking for disks…")
        font.family: Theme.family
        font.pixelSize: Theme.bodySize
        color: Theme.muted
    }
    Text {
        visible: Backend.state !== Backend.Listing && Backend.disks.usableCount === 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: qsTr("None of this computer's disks can be used. joe Linux needs a disk of at least 20 GB, not counting the installation medium, with nothing on it in use.")
        font.family: Theme.family
        font.pixelSize: Theme.bodySize
        color: Theme.ink
    }

    // The disks as one group, in the manner of GNOME's boxed lists.
    Rectangle {
        visible: Backend.disks.count > 0 && Backend.state !== Backend.Listing
        Layout.fillWidth: true
        implicitHeight: rows.implicitHeight
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.hairline
        clip: true

        Column {
            id: rows
            width: parent.width
            Repeater {
                model: Backend.disks
                delegate: Rectangle {
                    id: row
                    required property int index
                    required property string name
                    required property string sizeText
                    required property string transportText
                    required property bool usable
                    required property string reason
                    required property var contents
                    readonly property bool selected: page.chosen === index
                    width: rows.width
                    implicitHeight: text.implicitHeight + 32
                    color: "transparent"
                    Rectangle { visible: row.index > 0; anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.hairline }
                    // The selection, inset so that it never meets the
                    // group's rounded corners.
                    Rectangle {
                        anchors { fill: parent; margins: 4 }
                        radius: Theme.radius - 4
                        color: row.selected ? Qt.alpha(Theme.accent, 0.12)
                             : (hover.hovered && row.usable ? Qt.alpha(Theme.ink, 0.04) : "transparent")
                    }

                    HoverHandler { id: hover }
                    TapHandler { enabled: row.usable; onTapped: page.chosen = row.index }
                    activeFocusOnTab: usable
                    Keys.onSpacePressed: if (usable) page.chosen = index
                    Rectangle {
                        anchors.fill: parent
                        visible: row.activeFocus
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.accent
                        radius: 4
                    }

                    // The choice marker.
                    Rectangle {
                        id: mark
                        anchors { left: parent.left; leftMargin: 18; top: parent.top; topMargin: 18 }
                        width: 20; height: 20; radius: 10
                        color: "transparent"
                        border.width: row.selected ? 6 : 2
                        border.color: row.selected ? Theme.accent : Theme.muted
                        opacity: row.usable ? 1 : 0.35
                    }
                    Column {
                        id: text
                        anchors { left: mark.right; leftMargin: 14; right: parent.right; rightMargin: 18; top: parent.top; topMargin: 16 }
                        spacing: 3
                        opacity: row.usable ? 1 : 0.55
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.name
                            font.family: Theme.family
                            font.pixelSize: Theme.bodySize + 1
                            font.weight: Font.Bold
                            color: Theme.ink
                        }
                        Text {
                            width: parent.width
                            text: [row.sizeText, row.transportText, qsTr("disk")].filter(s => s.length > 0).join(" ")
                            font.family: Theme.family
                            font.pixelSize: Theme.smallSize
                            color: Theme.muted
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: row.contents.length > 0 ? qsTr("Holds %1").arg(row.contents.join(", ")) : qsTr("Holds nothing the installer recognizes")
                            font.family: Theme.family
                            font.pixelSize: Theme.smallSize
                            color: Theme.muted
                        }
                        Text {
                            visible: !row.usable
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: qsTr("Can't be used: %1").arg(row.reason)
                            font.family: Theme.family
                            font.pixelSize: Theme.smallSize
                            font.weight: Font.Medium
                            color: Theme.ink
                        }
                    }
                }
            }
        }
    }

    actions: [
        ActionButton { text: qsTr("Back"); onClicked: page.back() },
        Item { Layout.fillWidth: true },
        ActionButton {
            text: qsTr("Continue")
            kind: "suggested"
            enabled: page.chosen >= 0
            onClicked: page.proceed()
        }
    ]
}
