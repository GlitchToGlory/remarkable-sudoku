import QtQuick 2.15
import "sudoku.js" as S

// Sudoku for reMarkable (AppLoad). Grayscale highlights, no animations.
Rectangle {
    id: root
    color: bg

    // Required by AppLoad on the root item
    signal close
    function unloading() { }

    property var st: S.blankState()
    property var cv: S.cells(st)
    property bool busy: false
    property string pendingLevel: "Easy"

    // Menu (new game, difficulty, hint, dark mode, close). Shown at start-up.
    property bool showMenu: true
    property string optLevel: "Easy"

    // Dark mode swaps the foreground and background (white on black).
    property bool dark: false
    readonly property color fg: dark ? "white" : "black"
    readonly property color bg: dark ? "black" : "white"

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
    readonly property real menuBtnH: Math.max(minTap, shortSide * 0.06)

    readonly property real boardSize: landscape
        ? Math.min(height - 2 * pad, width * 0.62)
        : Math.min(width - 2 * pad,
                   height - 2 * pad - 4 * gap - pHeaderH - pStatusH - pNumH - pToolH)
    readonly property real cell: boardSize / 9

    // landscape: the side panel is 6.6 "rows" tall and matches the board height
    readonly property real lRow: (boardSize - 6 * gap) / 6.6
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
        showMenu = false;
        pendingLevel = level;
        busy = true;
        genTimer.start();     // let the "Generating" text paint before the heavy work
    }
    Timer {
        id: genTimer
        interval: 80
        onTriggered: { root.st = S.newGame(root.pendingLevel); root.busy = false; }
    }

    // E-ink refresh: flash the whole screen briefly so the display does a
    // full update and clears ghosting. The game itself is untouched.
    property bool flashing: false
    function refreshScreen() {
        flashing = true;
        flashTimer.restart();
    }
    Timer {
        id: flashTimer
        interval: 200
        onTriggered: root.flashing = false
    }

    // Header: title on the left, refresh button on the right
    Text {
        x: root.ctlX; y: root.headerY
        height: root.headerH
        verticalAlignment: Text.AlignVCenter
        text: "Sudoku"
        font.pixelSize: height * 0.7
        font.bold: true
        color: root.fg
    }
    // The refresh button keeps its white disc in dark mode so the icon stays visible.
    Rectangle {
        x: root.ctlX + root.ctlW - width; y: root.headerY
        width: root.headerH; height: root.headerH
        radius: width / 2
        color: refreshMa.pressed ? "#b4b4b4" : "white"
        Image {
            anchors.fill: parent
            anchors.margins: parent.width * 0.06
            source: "icons/refresh.png"
            smooth: true
            fillMode: Image.PreserveAspectFit
        }
        MouseArea {
            id: refreshMa
            anchors.fill: parent
            anchors.margins: -root.gap      // a slightly bigger tap target
            onClicked: root.refreshScreen()
        }
    }

    Text {
        x: root.ctlX; y: root.statusY
        width: root.ctlW; height: root.statusH
        text: S.statusText(root.st, root.busy)
        font.pixelSize: height * 0.6
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        color: root.fg
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
                color: c.wrong ? root.fg
                     : c.sel ? (root.dark ? "#707070" : "#b0b0b0")
                     : c.peer ? (root.dark ? "#303030" : "#ebebeb") : root.bg
                Text {
                    anchors.centerIn: parent
                    visible: c.v > 0
                    text: c.v
                    font.pixelSize: root.cell * 0.6
                    font.bold: c.given
                    color: c.wrong ? root.bg : root.fg
                }
                Text {
                    anchors.fill: parent
                    visible: c.v === 0 && c.notes !== ""
                    text: c.notes
                    font.family: "monospace"
                    font.pixelSize: root.cell * 0.2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.dark ? "#ddd" : "#222"
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
                color: root.fg
                width: board.width + height
                height: Math.max(index % 3 === 0 ? 3 : 1, root.boardSize * (index % 3 === 0 ? 0.005 : 0.0017))
                x: -height / 2
                y: index * root.cell - height / 2
            }
        }
        Repeater {
            model: 10
            delegate: Rectangle {
                color: root.fg
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
                dark: root.dark
                width: root.landscape ? (root.ctlW - 2 * root.gap) / 3
                                      : (root.ctlW - 8 * root.gap) / 9
                height: root.numH
                label: String(index + 1)
                fontScale: 0.55
                onTapped: root.st = S.input(root.st, index + 1)
            }
        }
    }

    // Tools: one row in portrait, 2x2 in landscape
    Grid {
        x: root.ctlX; y: root.toolY
        columns: root.landscape ? 2 : 4
        spacing: root.gap
        readonly property real w: root.landscape ? (root.ctlW - root.gap) / 2
                                                 : (root.ctlW - 3 * root.gap) / 4
        Btn {
            dark: root.dark
            width: parent.w; height: root.toolH
            label: "Menu"
            onTapped: root.showMenu = true
        }
        Btn {
            dark: root.dark
            width: parent.w; height: root.toolH
            label: "Undo"
            enabled: S.canUndo(root.st)
            onTapped: root.st = S.undo(root.st)
        }
        Btn {
            dark: root.dark
            width: parent.w; height: root.toolH
            label: "Notes"; active: root.st.notesMode
            onTapped: root.st = S.toggleNotes(root.st)
        }
        Btn {
            dark: root.dark
            width: parent.w; height: root.toolH
            label: "Check"; active: root.st.showMistakes
            onTapped: root.st = S.toggleCheck(root.st)
        }
    }

    // ---- menu -------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        visible: root.showMenu
        color: root.bg
        MouseArea { anchors.fill: parent }    // swallow taps

        Column {
            id: menu
            anchors.centerIn: parent
            width: Math.min(root.width - 4 * root.pad, root.shortSide)
            spacing: root.gap * 1.5
            readonly property real labelH: root.menuBtnH * 0.8
            readonly property bool inGame: root.st.level !== "" && !root.busy

            Text {
                width: menu.width
                horizontalAlignment: Text.AlignHCenter
                text: "Menu"
                font.pixelSize: root.menuBtnH * 0.9
                font.bold: true
                color: root.fg
            }

            Text { height: menu.labelH; verticalAlignment: Text.AlignBottom; text: "Difficulty"; font.pixelSize: height * 0.6; color: root.fg }
            Row {
                spacing: root.gap
                Repeater {
                    model: ["Easy", "Medium", "Hard"]
                    delegate: Btn {
                        dark: root.dark
                        width: (menu.width - 2 * root.gap) / 3
                        height: root.menuBtnH
                        label: modelData
                        active: modelData === root.optLevel
                        onTapped: root.optLevel = modelData
                    }
                }
            }

            Item { width: 1; height: root.gap }

            Btn {
                dark: root.dark
                width: menu.width; height: root.menuBtnH * 1.3
                label: "Start new game"; active: true
                onTapped: root.startGame(root.optLevel)
            }
            Btn {
                dark: root.dark
                width: menu.width; height: root.menuBtnH
                label: "Back to current game"
                visible: menu.inGame
                onTapped: root.showMenu = false
            }

            Item { width: 1; height: root.gap }

            // Fills in the selected cell, then returns to the board.
            Btn {
                dark: root.dark
                width: menu.width; height: root.menuBtnH
                label: S.canHint(root.st) ? "Hint: reveal the selected cell"
                                          : "Hint: select an empty cell first"
                visible: menu.inGame && !root.st.won
                enabled: S.canHint(root.st)
                onTapped: { root.st = S.hint(root.st); root.showMenu = false }
            }
            Btn {
                dark: root.dark
                width: menu.width; height: root.menuBtnH
                label: root.dark ? "Dark mode: On" : "Dark mode: Off"
                onTapped: root.dark = !root.dark
            }

            Item { width: 1; height: root.gap }

            // Closing lives here, away from the board, so it can't be hit by accident.
            Btn {
                dark: root.dark
                width: menu.width; height: root.menuBtnH
                label: "Close Sudoku"
                onTapped: root.close()
            }
        }
    }

    // Full-screen flash used by the refresh button (kept last so it sits on top)
    Rectangle {
        anchors.fill: parent
        visible: root.flashing
        color: root.fg
        MouseArea { anchors.fill: parent }    // ignore taps during the flash
    }
}
