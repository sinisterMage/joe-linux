import QtQuick
import QtQuick.Layouts

PageFrame {
    id: page
    signal proceed()
    signal leave()

    title: qsTr("Install %1").arg(Backend.systemName)
    body: qsTr("joe Linux takes a whole disk of this computer: everything on the disk you choose is erased. Nothing else on the computer is changed.\n\nThis is an alpha release, for trying out and testing. Keep copies of anything that matters to you.")

    actions: [
        ActionButton { text: qsTr("Try joe Linux"); onClicked: page.leave() },
        Item { Layout.fillWidth: true },
        ActionButton { text: qsTr("Install"); kind: "suggested"; focus: true; onClicked: page.proceed() }
    ]
}
