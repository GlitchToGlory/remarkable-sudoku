// Replicates the layout maths in main.qml and checks everything fits on-screen.
// Run with: node tests/layout-check.js
function layout(W, H) {
  const landscape = W > H * 1.1, ss = Math.min(W, H), pad = ss * 0.03, gap = ss * 0.012, minTap = 48;
  const pH = Math.max(minTap, ss * 0.058), pS = Math.max(32, ss * 0.045), pN = Math.max(minTap, ss * 0.085), pT = Math.max(minTap, ss * 0.075);
  const board = landscape ? Math.min(H - 2 * pad, W * 0.62) : Math.min(W - 2 * pad, H - 2 * pad - 4 * gap - pH - pS - pN - pT);
  const lRow = (board - 6 * gap) / 6.6;
  const hH = landscape ? lRow : pH, sH = landscape ? lRow * 0.6 : pS, nH = landscape ? lRow : pN, tH = landscape ? lRow : pT;
  const nTot = landscape ? 3 * nH + 2 * gap : nH, tTot = landscape ? 2 * tH + gap : tH;
  const panelW = Math.min(W - 2 * pad - gap - board, ss * 0.55);
  const portraitH = hH + sH + board + nH + tH + 4 * gap;
  const top0 = landscape ? (H - board) / 2 : Math.max(pad, (H - portraitH) / 2);
  const boardX = landscape ? (W - board - gap - panelW) / 2 : (W - board) / 2;
  const ctlX = landscape ? boardX + board + gap : boardX, ctlW = landscape ? panelW : board;
  const headerY = top0, statusY = headerY + hH + gap, boardY = landscape ? top0 : statusY + sH + gap;
  const numY = landscape ? statusY + sH + gap : boardY + board + gap, toolY = numY + nTot + gap;
  return { landscape, board, boardX, boardY, bottom: Math.max(toolY + tTot, boardY + board), right: ctlX + ctlW, left: Math.min(boardX, ctlX), minBtn: Math.min(hH, nH, tH), cell: board / 9 };
}
let bad = 0;
const sizes = [[1404,1872,"Paper Pure / rM2 portrait"],[1620,2160,"Paper Pro portrait"],[954,1696,"Paper Pro Move portrait"],
  [1872,1404,"rM2 landscape"],[2160,1620,"Paper Pro landscape"],[1696,954,"Move landscape"],[800,1000,"small window"],[600,900,"tiny window"],[2000,900,"very wide"],[900,2000,"very tall"]];
for (const [W,H,name] of sizes) {
  const r = layout(W, H);
  const fits = r.bottom <= H + 0.5 && r.right <= W + 0.5 && r.left >= -0.5 && r.boardY >= -0.5;
  if (!fits) bad++;
  console.log((fits ? "ok  " : "FAIL") + " " + name.padEnd(26) + (r.landscape ? "landscape" : "portrait ") + " board " + Math.round(r.board) + "px, cell " + Math.round(r.cell) + "px, smallest button " + Math.round(r.minBtn) + "px");
}
process.exit(bad ? 1 : 0);
