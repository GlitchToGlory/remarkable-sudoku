# reMarkable Sudoku

A standalone Sudoku game for the **reMarkable Paper Pure**, built as an [AppLoad](https://github.com/asivery/rm-appload) (xovi) QML app. Grayscale highlights and no animations, designed for e-ink. This should work on other reMarkable tablets, but has not been tested on all models.

**[Live web demo](https://GlitchToGlory.github.io/remarkable-sudoku/)** (same puzzle engine as the tablet app)

**[Sudoku running on a reMarkable Paper Pure](docs/photo.jpg)**

## Features
- Fresh puzzles every time, in three difficulty levels (Easy, Medium, Hard)
- Every puzzle is guaranteed to have exactly one solution
- Pencil notes, erase, hints, and a "Check" mode that flags wrong digits
- Adapts to the screen: scales to any reMarkable resolution and switches between portrait and landscape layouts
- Highlights the selected cell and its row, column and box
- Pencil marks are tidied automatically when you place a digit
- Engine lives in one file (`src/qml/sudoku.js`), shared by the tablet app and the web demo, with unit tests

## Install on the tablet
Requires developer mode with xovi + AppLoad already installed.

1. Download `sudoku.zip` from the Releases page and unzip it (or build it, see below).
2. With the tablet connected by USB (password: Settings > Help > About):
   ```sh
   scp -O -r sudoku root@10.11.99.1:/home/root/xovi/exthome/appload/
   ```
3. In AppLoad, tap **Reload**. "Sudoku" appears in the launcher.

## Build from source (macOS)
```sh
brew install qt node
./build.sh
```
This runs the tests, compiles the QML into `resources.rcc`, and produces `dist/sudoku/` and `dist/sudoku.zip`.

## How it works
1. A complete valid grid is filled using randomised backtracking.
2. Digits are removed one at a time in random order. After each removal a solver counts solutions (stopping at 2), and the digit is put back if the puzzle would stop being unique.
3. Difficulty is set by how many givens remain (Easy 40, Medium 32, Hard 26 targets).

## Layout
```
src/qml/main.qml     UI
src/qml/Btn.qml      button component
src/qml/sudoku.js    generator, solver and game state (shared with the web demo)
src/resources.qrc    Qt resource manifest
package/             manifest.json + icon.png for AppLoad
docs/                GitHub Pages demo
tests/test.js        engine tests (node tests/test.js)
tests/layout-check.js  checks the layout fits many screen sizes
```

## Notes
- Difficulty is based on the number of givens only, not on which solving techniques a puzzle needs.
- Games are not saved when you close the app.
- Not affiliated with reMarkable AS.

## License
MIT
