#!/usr/bin/env bash
# Builds dist/sudoku/ (the folder to copy to the tablet) and dist/sudoku.zip
set -euo pipefail
cd "$(dirname "$0")"

RCC="$(command -v rcc || command -v rcc6 || true)"
if [ -z "$RCC" ]; then
  for p in /opt/homebrew/share/qt/libexec/rcc /opt/homebrew/opt/qt/share/qt/libexec/rcc /opt/homebrew/opt/qt/libexec/rcc; do
    if [ -x "$p" ]; then RCC="$p"; break; fi
  done
fi
if [ -z "$RCC" ]; then echo "rcc not found. Install Qt with: brew install qt"; exit 1; fi

node tests/test.js
node tests/layout-check.js
rm -rf dist && mkdir -p dist/sudoku
"$RCC" --binary -o dist/sudoku/resources.rcc src/resources.qrc
cp package/manifest.json package/icon.png dist/sudoku/
cp src/qml/sudoku.js docs/sudoku.js     # keep the web demo in sync
(cd dist && zip -qr sudoku.zip sudoku)
echo "Built dist/sudoku and dist/sudoku.zip"
