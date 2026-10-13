import QtQuick 2.15

// Simple high-contrast button; inverts while pressed or when "active".
// Set enabled: false to grey it out and ignore taps.
// The label shrinks automatically if it is too wide for the button.
Rectangle {
    id: b
    property string label: ""
    property bool active: false
    property bool dark: false
    readonly property color fg: dark ? "white" : "black"
    readonly property color bg: dark ? "black" : "white"
    property real fontScale: 0.42
    signal tapped
    readonly property bool inv: active !== ma.pressed
    color: inv ? fg : bg
    border { color: enabled ? fg : "#888"; width: 3 }
    radius: 10
    Text {
        anchors.centerIn: parent
        width: b.width - 16
        height: b.height
        text: b.label
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: b.height * b.fontScale
        fontSizeMode: Text.Fit
        minimumPixelSize: 10
        color: b.inv ? b.bg : (b.enabled ? b.fg : "#888")
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: b.tapped() }
}
