.pragma library
// Sudoku engine shared by the reMarkable QML app and the web demo.
// Generates puzzles with a unique solution; no external dependencies.

// Target number of given digits left on the board (fewer = harder).
var LEVELS = { Easy: 40, Medium: 32, Hard: 26 };

var PEERS = [];     // PEERS[i]   = the 20 cells sharing a row/column/box with cell i
var PEERSET = [];   // PEERSET[i] = array of 81 booleans for quick lookup
(function () {
    for (var i = 0; i < 81; i++) {
        var r = Math.floor(i / 9), c = i % 9, br = r - r % 3, bc = c - c % 3;
        var list = [], set = [];
        for (var k = 0; k < 81; k++) set.push(false);
        for (var j = 0; j < 81; j++) {
            if (j === i) continue;
            var r2 = Math.floor(j / 9), c2 = j % 9;
            if (r2 === r || c2 === c || (r2 - r2 % 3 === br && c2 - c2 % 3 === bc)) {
                list.push(j);
                set[j] = true;
            }
        }
        PEERS.push(list);
        PEERSET.push(set);
    }
})();

function zeros(n) { var a = []; for (var i = 0; i < n; i++) a.push(0); return a; }

function shuffle(arr, rng) {
    for (var i = arr.length - 1; i > 0; i--) {
        var j = Math.floor(rng() * (i + 1));
        var t = arr[i]; arr[i] = arr[j]; arr[j] = t;
    }
    return arr;
}

function digitsOf(mask) {
    var out = [];
    for (var d = 1; d <= 9; d++) if (mask & (1 << d)) out.push(d);
    return out;
}

function candidates(grid, i) {
    var used = 0, p = PEERS[i];
    for (var k = 0; k < 20; k++) { var v = grid[p[k]]; if (v) used |= (1 << v); }
    return (~used) & 0x3FE;
}

// Empty cell with the fewest candidates (best branching choice).
function pickCell(grid) {
    var best = -1, bestMask = 0, bestN = 10;
    for (var i = 0; i < 81; i++) {
        if (grid[i]) continue;
        var m = candidates(grid, i), n = digitsOf(m).length;
        if (n < bestN) { best = i; bestMask = m; bestN = n; if (n <= 1) break; }
    }
    return { i: best, mask: bestMask, n: bestN };
}

function fillRandom(grid, rng) {
    var c = pickCell(grid);
    if (c.i < 0) return true;
    if (c.n === 0) return false;
    var ds = shuffle(digitsOf(c.mask), rng);
    for (var k = 0; k < ds.length; k++) {
        grid[c.i] = ds[k];
        if (fillRandom(grid, rng)) return true;
    }
    grid[c.i] = 0;
    return false;
}

// Counts solutions (stops at `limit`). Leaves the grid unchanged.
function countSolutions(grid, limit) {
    var c = pickCell(grid);
    if (c.i < 0) return 1;
    if (c.n === 0) return 0;
    var total = 0, ds = digitsOf(c.mask);
    for (var k = 0; k < ds.length; k++) {
        grid[c.i] = ds[k];
        total += countSolutions(grid, limit - total);
        if (total >= limit) break;
    }
    grid[c.i] = 0;
    return total;
}

function makePuzzle(level, rng) {
    rng = rng || Math.random;
    var target = LEVELS[level] || LEVELS.Easy;
    var solution = zeros(81);
    fillRandom(solution, rng);
    var puzzle = solution.slice();
    var order = [];
    for (var i = 0; i < 81; i++) order.push(i);
    shuffle(order, rng);
    var clues = 81;
    for (var k = 0; k < 81 && clues > target; k++) {
        var idx = order[k], v = puzzle[idx];
        puzzle[idx] = 0;
        if (countSolutions(puzzle.slice(), 2) !== 1) puzzle[idx] = v;   // keep unique
        else clues--;
    }
    return { puzzle: puzzle, solution: solution };
}

// ---- game state (every function returns a new object) ---------------------

function blankState() {
    return { level: "", puzzle: zeros(81), solution: zeros(81), values: zeros(81),
             notes: zeros(81), sel: -1, notesMode: false, showMistakes: false,
             hints: 0, won: false };
}

function newGame(level, rng) {
    var g = makePuzzle(level, rng);
    var st = blankState();
    st.level = level;
    st.puzzle = g.puzzle;
    st.solution = g.solution;
    st.values = g.puzzle.slice();
    return st;
}

function copy(st) {
    return { level: st.level, puzzle: st.puzzle, solution: st.solution,
             values: st.values.slice(), notes: st.notes.slice(), sel: st.sel,
             notesMode: st.notesMode, showMistakes: st.showMistakes,
             hints: st.hints, won: st.won };
}

function checkWon(st) {
    for (var i = 0; i < 81; i++) if (st.values[i] !== st.solution[i]) return false;
    return true;
}

function place(c, i, n) {
    c.values[i] = n;
    c.notes[i] = 0;
    var p = PEERS[i];
    for (var k = 0; k < 20; k++) c.notes[p[k]] &= ~(1 << n);   // tidy pencil marks
}

function select(st, i) {
    var c = copy(st);
    c.sel = i;
    return c;
}

function input(st, n) {
    if (!st.level || st.won || st.sel < 0 || st.puzzle[st.sel]) return st;
    var c = copy(st), i = c.sel;
    if (c.notesMode) {
        if (c.values[i]) return st;
        c.notes[i] ^= (1 << n);
        return c;
    }
    if (c.values[i] === n) c.values[i] = 0;
    else place(c, i, n);
    c.won = checkWon(c);
    return c;
}

function erase(st) {
    if (!st.level || st.won || st.sel < 0 || st.puzzle[st.sel]) return st;
    var c = copy(st);
    c.values[c.sel] = 0;
    c.notes[c.sel] = 0;
    return c;
}

function hint(st) {
    if (!st.level || st.won || st.sel < 0 || st.puzzle[st.sel]) return st;
    if (st.values[st.sel] === st.solution[st.sel]) return st;
    var c = copy(st);
    place(c, c.sel, c.solution[c.sel]);
    c.hints++;
    c.won = checkWon(c);
    return c;
}

function toggleNotes(st) { var c = copy(st); c.notesMode = !c.notesMode; return c; }
function toggleCheck(st) { var c = copy(st); c.showMistakes = !c.showMistakes; return c; }

// ---- view helpers ---------------------------------------------------------

function notesText(mask) {
    if (!mask) return "";
    var rows = [];
    for (var r = 0; r < 3; r++) {
        var row = [];
        for (var c = 0; c < 3; c++) {
            var d = r * 3 + c + 1;
            row.push((mask & (1 << d)) ? String(d) : " ");
        }
        rows.push(row.join(" "));
    }
    return rows.join("\n");
}

function cells(st) {
    var out = [];
    for (var i = 0; i < 81; i++) {
        var v = st.values[i];
        out.push({
            v: v,
            given: st.puzzle[i] !== 0,
            sel: i === st.sel,
            peer: st.sel >= 0 && PEERSET[st.sel][i],
            wrong: st.showMistakes && v !== 0 && v !== st.solution[i],
            notes: v ? "" : notesText(st.notes[i])
        });
    }
    return out;
}

function statusText(st, busy) {
    if (busy) return "Generating puzzle...";
    if (!st.level) return "";
    var h = st.hints ? st.hints + (st.hints > 1 ? " hints" : " hint") : "";
    if (st.won) return "Solved! " + st.level + (h ? " (" + h + ")" : "");
    var parts = [st.level];
    if (h) parts.push(h);
    if (st.notesMode) parts.push("Notes on");
    return parts.join(" | ");
}
