import QtQuick 2.15

// Simple high-contrast button; inverts while pressed or when "active".
// The label shrinks automatically if it is too wide for the button.
Rectangle {
    id: b
    property string label: ""
    property bool active: false
    property real fontScale: 0.42
    signal tapped
    readonly property bool inv: active !== ma.pressed
    color: inv ? "black" : "white"
    border { color: "black"; width: 3 }
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
        color: b.inv ? "white" : "black"
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: b.tapped() }
}
