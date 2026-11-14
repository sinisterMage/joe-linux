// The frame every page shares: a title and its explanation in one column,
// the page's own content under them, and the actions in a footer.
import QtQuick
import QtQuick.Layouts

Item {
    id: frame
    property string title
    property string body
    default property alias content: slot.data
    property alias actions: footer.data

    Rectangle { anchors.fill: parent; color: Theme.window }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: bar.top }
        contentHeight: column.implicitHeight + 120
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: Math.min(Theme.column, frame.width - 64)
            x: (frame.width - width) / 2
            y: Math.max(48, frame.height * 0.12)
            spacing: 14

            Text {
                text: frame.title
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.family: Theme.family
                font.pixelSize: Theme.titleSize
                font.weight: Font.Black
                font.letterSpacing: -0.6
                lineHeight: 1.1
                color: Theme.ink
            }
            Text {
                text: frame.body
                visible: text.length > 0
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.family: Theme.family
                font.pixelSize: Theme.bodySize
                lineHeight: 1.35
                color: Theme.muted
                textFormat: Text.PlainText
            }
            Item { Layout.preferredHeight: 10 }
            ColumnLayout {
                id: slot
                Layout.fillWidth: true
                spacing: 12
            }
        }
    }

    Rectangle {
        id: bar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 76
        color: Theme.window
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.hairline }
        RowLayout {
            id: footer
            anchors { fill: parent; leftMargin: 24; rightMargin: 24 }
            spacing: 12
        }
    }
}
