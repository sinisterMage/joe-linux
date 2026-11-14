// Colours and type, light and dark. The palette is libadwaita's own for
// surfaces and text, so the installer sits quietly in a GNOME session; the
// accent is joe's.
pragma Singleton
import QtQuick

QtObject {
    readonly property bool dark: Qt.styleHints.colorScheme === Qt.ColorScheme.Dark

    readonly property color window: dark ? "#222226" : "#fafafb"
    readonly property color surface: dark ? "#2e2e32" : "#ffffff"
    readonly property color ink: dark ? "#f2f2f4" : "#1f1f24"
    readonly property color muted: dark ? "#a8a6af" : "#5e5c64"
    readonly property color hairline: dark ? "#3d3d42" : "#deddda"
    readonly property color accent: dark ? "#5fc0b0" : "#2a7a6f"
    readonly property color onAccent: dark ? "#10211e" : "#ffffff"
    readonly property color destructive: dark ? "#ff7b63" : "#c01c28"
    readonly property color onDestructive: dark ? "#2a0c08" : "#ffffff"
    readonly property color track: dark ? "#3a3a3f" : "#ebeaee"
    // File systems already on a disk, in the disk strip: quiet greys, so the
    // new system's accent is the only colour on the confirmation page.
    readonly property var segmentShades: dark ? ["#6f6e76", "#58575e", "#828189", "#4a4950"]
                                              : ["#9a9996", "#c0bfbc", "#77767b", "#b5b4b1"]

    readonly property string family: "Adwaita Sans"
    readonly property string monoFamily: "Adwaita Mono"

    readonly property int titleSize: 30
    readonly property int bodySize: 15
    readonly property int smallSize: 13
    readonly property int radius: 12
    readonly property int column: 560
}
