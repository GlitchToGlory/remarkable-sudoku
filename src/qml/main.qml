import QtQuick 2.15
import "sudoku.js" as S

// Sudoku for reMarkable (AppLoad). Grayscale highlights, no animations.
Rectangle {
    id: root
    color: "white"

    // Required by AppLoad on the root item
    signal close
    function unloading() { }

    property var st: S.blankState()
    property var cv: S.cells(st)
    property bool busy: false
    property string pendingLevel: "Easy"

    // ---- adaptive layout: works from the window size, portrait or landscape ----
    readonly property bool landscape: width > height * 1.1
    readonly property real shortSide: Math.min(width, height)
    readonly property real pad: shortSide * 0.03
    readonly property real gap: shortSide * 0.012
    readonly property real minTap: 48

    // portrait control heights (never smaller than a comfortable tap target)
    readonly property real pHeaderH: Math.max(minTap, shortSide * 0.058)
    readonly property real pStatusH: Math.max(32, shortSide * 0.045)
    readonly property real pNumH: Math.max(minTap, shortSide * 0.085)
    readonly property real pToolH: Math.max(minTap, shortSide * 0.075)

    readonly property real boardSize: landscape
        ? Math.min(height - 2 * pad, width * 0.62)
        : Math.min(width - 2 * pad,
                   height - 2 * pad - 4 * gap - pHeaderH - pStatusH - pNumH - pToolH)
    readonly property real cell: boardSize / 9

    // landscape: the side panel is 7.6 "rows" tall and matches the board height
    readonly property real lRow: (boardSize - 7 * gap) / 7.6
    readonly property real headerH: landscape ? lRow : pHeaderH
    readonly property real statusH: landscape ? lRow * 0.6 : pStatusH
    readonly property real numH: landscape ? lRow : pNumH
    readonly property real toolH: landscape ? lRow : pToolH
    readonly property real numTotal: landscape ? 3 * numH + 2 * gap : numH
    readonly property real panelW: Math.min(width - 2 * pad - gap - boardSize, shortSide * 0.55)

    // positions (the whole layout is centred in the window)
    readonly property real portraitH: headerH + statusH + boardSize + numH + toolH + 4 * gap
    readonly property real top0: landscape ? (height - boardSize) / 2
                                           : Math.max(pad, (height - portraitH) / 2)
    readonly property real boardX: landscape ? (width - boardSize - gap - panelW) / 2
                                             : (width - boardSize) / 2
    readonly property real ctlX: landscape ? boardX + boardSize + gap : boardX
    readonly property real ctlW: landscape ? panelW : boardSize
    readonly property real headerY: top0
    readonly property real statusY: headerY + headerH + gap
    readonly property real boardY: landscape ? top0 : statusY + statusH + gap
    readonly property real numY: landscape ? statusY + statusH + gap : boardY + boardSize + gap
    readonly property real toolY: numY + numTotal + gap

    function startGame(level) {
        pendingLevel = level;
        busy = true;
        genTimer.start();     // let the "Generating" text paint before the heavy work
    }
    Timer {
        id: genTimer
        interval: 80
        onTriggered: { root.st = S.newGame(root.pendingLevel); root.busy = false; }
    }
    Component.onCompleted: startGame("Easy")

    // Difficulty (+ Close in portrait)
    Row {
        x: root.ctlX; y: root.headerY
        spacing: root.gap
        Repeater {
            model: ["Easy", "Medium", "Hard"]
            delegate: Btn {
                width: root.landscape ? (root.ctlW - 2 * root.gap) / 3
                                      : (root.ctlW - 3 * root.gap) / 4
                height: root.headerH
                label: modelData
                active: modelData === root.st.level
                onTapped: root.startGame(modelData)
            }
        }
        Btn {
            visible: !root.landscape
            width: (root.ctlW - 3 * root.gap) / 4
            height: root.headerH
            label: "Close"
            onTapped: root.close()
        }
    }

    Text {
        x: root.ctlX; y: root.statusY
        width: root.ctlW; height: root.statusH
        text: S.statusText(root.st, root.busy)
        font.pixelSize: height * 0.6
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        color: "black"
    }

    // Board
    Item {
        id: board
        x: root.boardX; y: root.boardY
        width: root.boardSize; height: root.boardSize

        Repeater {
            model: 81
            delegate: Rectangle {
                property var c: root.cv[index]
                x: (index % 9) * root.cell
                y: Math.floor(index / 9) * root.cell
                width: root.cell; height: root.cell
                color: c.wrong ? "black"
                     : c.sel ? "#b0b0b0"
                     : c.peer ? "#ebebeb" : "white"
                Text {
                    anchors.centerIn: parent
                    visible: c.v > 0
                    text: c.v
                    font.pixelSize: root.cell * 0.6
                    font.bold: c.given
                    color: c.wrong ? "white" : "black"
                }
                Text {
                    anchors.fill: parent
                    visible: c.v === 0 && c.notes !== ""
                    text: c.notes
                    font.family: "monospace"
                    font.pixelSize: root.cell * 0.2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#222"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.st = S.select(root.st, index)
                }
            }
        }
        // grid lines (thick on 3x3 box edges)
        Repeater {
            model: 10
            delegate: Rectangle {
                color: "black"
                width: board.width + height
                height: Math.max(index % 3 === 0 ? 3 : 1, root.boardSize * (index % 3 === 0 ? 0.005 : 0.0017))
                x: -height / 2
                y: index * root.cell - height / 2
            }
        }
        Repeater {
            model: 10
            delegate: Rectangle {
                color: "black"
                height: board.height + width
                width: Math.max(index % 3 === 0 ? 3 : 1, root.boardSize * (index % 3 === 0 ? 0.005 : 0.0017))
                y: -width / 2
                x: index * root.cell - width / 2
            }
        }
    }

    // Number pad: one row in portrait, 3x3 in landscape
    Grid {
        x: root.ctlX; y: root.numY
        columns: root.landscape ? 3 : 9
        spacing: root.gap
        Repeater {
            model: 9
            delegate: Btn {
                width: root.landscape ? (root.ctlW - 2 * root.gap) / 3
                                      : (root.ctlW - 8 * root.gap) / 9
                height: root.numH
                label: String(index + 1)
                fontScale: 0.55
                onTapped: root.st = S.input(root.st, index + 1)
            }
        }
    }

    // Tools: one row in portrait, two columns in landscape (Close joins here)
    Grid {
        x: root.ctlX; y: root.toolY
        columns: root.landscape ? 2 : 5
        spacing: root.gap
        Btn {
            width: root.landscape ? (root.ctlW - root.gap) / 2 : (root.ctlW - 4 * root.gap) / 5
            height: root.toolH
            label: "Notes"; active: root.st.notesMode
            onTapped: root.st = S.toggleNotes(root.st)
        }
        Btn {
            width: root.landscape ? (root.ctlW - root.gap) / 2 : (root.ctlW - 4 * root.gap) / 5
            height: root.toolH
            label: "Erase"
            onTapped: root.st = S.erase(root.st)
        }
        Btn {
            width: root.landscape ? (root.ctlW - root.gap) / 2 : (root.ctlW - 4 * root.gap) / 5
            height: root.toolH
            label: "Hint"
            onTapped: root.st = S.hint(root.st)
        }
        Btn {
            width: root.landscape ? (root.ctlW - root.gap) / 2 : (root.ctlW - 4 * root.gap) / 5
            height: root.toolH
            label: "Check"; active: root.st.showMistakes
            onTapped: root.st = S.toggleCheck(root.st)
        }
        Btn {
            width: root.landscape ? (root.ctlW - root.gap) / 2 : (root.ctlW - 4 * root.gap) / 5
            height: root.toolH
            label: "New"
            onTapped: root.startGame(root.st.level ? root.st.level : "Easy")
        }
        Btn {
            visible: root.landscape
            width: (root.ctlW - root.gap) / 2
            height: root.toolH
            label: "Close"
            onTapped: root.close()
        }
    }
}
