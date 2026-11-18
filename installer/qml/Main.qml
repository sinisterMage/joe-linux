// The installer's window: the pages in order, and an automated run of the
// same pages for the tests (joe-installer --autotest DISK).
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window

ApplicationWindow {
    id: window
    width: 960
    height: 700
    minimumWidth: 600
    minimumHeight: 540
    visible: true
    visibility: Window.Maximized
    title: qsTr("Install joe Linux")
    color: Theme.window
    font.family: Theme.family

    // The disk chosen on the disk page, as the model describes it, and
    // whether joe goes beside what is on it.
    property var disk: ({})
    property bool beside: false

    function showDisks() {
        Backend.refreshDisks()
        stack.push(diskPage)
    }
    function confirm(row, beside) {
        window.disk = Backend.disks.get(row)
        window.beside = beside
        stack.push(confirmPage)
    }
    function install() {
        Backend.install(window.disk.path, window.beside)
        stack.replace(null, progressPage)
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: welcomePage
    }

    Component { id: welcomePage; WelcomePage { onProceed: window.showDisks(); onLeave: Qt.quit() } }
    Component { id: diskPage; DiskPage { onBack: stack.pop(); onProceed: window.confirm(chosen, beside) } }
    Component { id: confirmPage; ConfirmPage { disk: window.disk; beside: window.beside; onBack: stack.pop(); onProceed: window.install() } }
    Component { id: progressPage; ProgressPage { disk: window.disk; beside: window.beside } }
    Component { id: donePage; DonePage { onLeave: Qt.quit() } }
    Component { id: failedPage; FailedPage { onLeave: Qt.quit(); onAgain: { stack.replace(null, welcomePage); window.showDisks() } } }

    Connections {
        target: Backend
        function onStateChanged() {
            if (Backend.state === Backend.Done)
                stack.replace(null, donePage)
            else if (Backend.state === Backend.Failed)
                stack.replace(null, failedPage)
        }
    }

    // --autotest: each page is shown for a moment (so that it can be looked
    // at, and captured), then the action a person would take is taken.
    QtObject {
        id: autotest
        readonly property bool active: Backend.autotestDisk.length > 0
        property int stage: 0

        function report(what) {
            console.log("autotest: " + what)
            if (Backend.screenshotDir.length > 0 && what.startsWith("page ")) {
                const name = what.slice(5).split(":")[0]
                stack.grabToImage(function (shot) {
                    shot.saveToFile(Backend.screenshotDir + "/" + name + ".png")
                })
            }
        }
    }
    Timer {
        running: autotest.active
        interval: 3000
        repeat: true
        onTriggered: {
            const page = stack.currentItem
            switch (autotest.stage) {
            case 0:
                autotest.report("page welcome")
                window.showDisks()
                autotest.stage = 1
                break
            case 1:
                if (Backend.state === Backend.Listing)
                    return
                autotest.report("page disk")
                const row = Backend.disks.indexOfPath(Backend.autotestDisk)
                const found = row >= 0 ? Backend.disks.get(row) : null
                if (!found || !(Backend.autotestBeside ? found.canBeside : found.usable)) {
                    autotest.report("disk " + Backend.autotestDisk + " cannot be used")
                    Qt.exit(2)
                    return
                }
                page.chosen = row
                page.beside = Backend.autotestBeside
                autotest.stage = 2
                break
            case 2:
                window.confirm(page.chosen, page.beside)
                autotest.stage = 3
                break
            case 3:
                autotest.report("page confirm")
                if (!window.beside)
                    page.understood = true
                autotest.stage = 4
                break
            case 4:
                window.install()
                autotest.report("page progress")
                autotest.stage = 5
                break
            case 5:
                if (Backend.state === Backend.Done) {
                    autotest.report("page done")
                    autotest.stage = 6
                } else if (Backend.state === Backend.Failed) {
                    autotest.report("page failed: " + Backend.error)
                    autotest.stage = 7
                }
                break
            case 6:
                Qt.exit(0)
                break
            case 7:
                Qt.exit(1)
                break
            }
        }
    }
}
