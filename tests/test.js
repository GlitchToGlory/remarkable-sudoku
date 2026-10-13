// Run with: node tests/test.js
const fs = require("fs");
const src = fs.readFileSync(__dirname + "/../src/qml/sudoku.js", "utf8").replace(/^\.pragma library.*$/m, "");
const S = new Function(src + "; return { newGame, makePuzzle, countSolutions, select, input, erase, hint, canHint, undo, canUndo, toggleNotes, toggleCheck, cells, statusText, blankState, PEERS, LEVELS };")();

function mulberry32(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
let failed = 0;
function ok(c, name) { if (!c) { failed++; console.log("FAIL", name); } }
function validSolution(g) {
    for (let u = 0; u < 9; u++) {
        const row = new Set(), col = new Set(), box = new Set();
        for (let k = 0; k < 9; k++) {
            row.add(g[u * 9 + k]); col.add(g[k * 9 + u]);
            const br = Math.floor(u / 3) * 3 + Math.floor(k / 3), bc = (u % 3) * 3 + k % 3;
            box.add(g[br * 9 + bc]);
        }
        if (row.size !== 9 || col.size !== 9 || box.size !== 9) return false;
    }
    return g.indexOf(0) < 0;
}

ok(S.PEERS.every(p => p.length === 20), "20 peers per cell");

for (const level of ["Easy", "Medium", "Hard"]) {
    let worst = 0;
    for (let seed = 1; seed <= 4; seed++) {
        const t0 = Date.now();
        const st = S.newGame(level, mulberry32(seed * 101));
        worst = Math.max(worst, Date.now() - t0);
        ok(validSolution(st.solution), level + " solution valid");
        ok(st.puzzle.every((v, i) => v === 0 || v === st.solution[i]), level + " givens match solution");
        ok(S.countSolutions(st.puzzle.slice(), 2) === 1, level + " has a unique solution");
        const clues = st.puzzle.filter(Boolean).length;
        ok(clues >= 22 && clues <= 45, level + " clue count sane (" + clues + ")");
    }
    console.log(level + ": slowest generation " + worst + " ms");
}

// Gameplay
let g = S.newGame("Easy", mulberry32(7));
const blanks = []; for (let i = 0; i < 81; i++) if (!g.puzzle[i]) blanks.push(i);
const b = blanks[0], sol = g.solution[b], wrong = sol % 9 + 1;

let t = S.input(S.select(g, b), wrong);
ok(t.values[b] === wrong, "digit placed");
t = S.toggleCheck(t);
ok(S.cells(t)[b].wrong === true, "mistake flagged when Check is on");
t = S.erase(t);
ok(t.values[b] === 0, "erase");

const given = g.puzzle.findIndex(v => v !== 0);
ok(S.input(S.select(g, given), 1).values[given] === g.puzzle[given], "givens are locked");

// Notes, then placing a digit clears matching notes in peers
const p = S.PEERS[b].find(i => !g.puzzle[i]);
let n = S.toggleNotes(S.select(g, p));
n = S.input(n, sol);
ok((n.notes[p] & (1 << sol)) !== 0 && n.values[p] === 0, "pencil note stored");
ok(S.cells(n)[p].notes.length > 0, "notes rendered");
n = S.input(S.toggleNotes(S.select(n, b)), sol);
ok((n.notes[p] & (1 << sol)) === 0, "placing a digit clears peer notes");

// Hint
let h = S.hint(S.select(g, b));
ok(h.values[b] === sol && h.hints === 1, "hint reveals digit");

// Undo
ok(!S.canUndo(g), "nothing to undo in a new game");
let u = S.input(S.select(g, b), wrong);
u = S.input(u, sol);
ok(S.canUndo(u) && u.values[b] === sol, "two moves made");
u = S.undo(u);
ok(u.values[b] === wrong, "undo returns to the previous digit");
u = S.undo(u);
ok(u.values[b] === 0 && !S.canUndo(u), "undo back to the start");
ok(S.undo(u) === u, "undo with no history does nothing");
u = S.undo(S.hint(S.select(g, b)));
ok(u.values[b] === 0 && u.hints === 0, "undo takes back a hint");
u = S.undo(S.input(n, wrong));
ok(u.notes[p] === n.notes[p] && u.notes[b] === n.notes[b], "undo restores notes");
ok(S.canHint(S.select(g, b)) && !S.canHint(g) && !S.canHint(S.select(g, given)), "canHint needs an unsolved, selected cell");

// Full solve
let w = g;
for (const i of blanks) w = S.input(S.select(w, i), g.solution[i]);
ok(w.won, "solving every cell wins");
ok(S.statusText(w, false).indexOf("Solved") === 0, "status shows solved");

console.log(failed ? failed + " test(s) failed" : "All tests passed");
process.exit(failed ? 1 : 0);
