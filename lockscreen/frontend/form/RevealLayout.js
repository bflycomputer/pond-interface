// Each entry is [column offset, row offset, movement wave],
// relative to the cell's final position.
var MOVES = [
    [0, 0, 1], [0, -1, 0], [0, -1, 1], [-1, 0, 0], [0, 0, 1],
    [0, -1, 1], [-1, 0, 0], [0, -1, 0], [0, 1, 1], [-1, 0, 0],
    [0, -1, 0], [-1, 0, 0], [0, 1, 1], [-1, 0, 0], [0, 1, 1],
    [-1, 0, 0], [0, 1, 0], [0, 0, 1], [0, 1, 1], [-1, 0, 0], [0, 0, 1]
];
function count(length) { return Math.max(0, Math.min(21, Math.floor(length))); }
function layout(length) {
    const n = count(length);
    // Include Enter when centering the second row beneath the first.
    const top = Math.min(n, 11);
    const bottom = Math.max(0, n - top);
    const columns = top + 1;
    const result = [];
    for (let i = 0; i < n; ++i) {
        const x = i < top ? i : (columns - bottom) / 2 + i - top;
        result.push({ x: x * 80, y: i < top ? 0 : 80,
                      dx: MOVES[i][0] * 80, dy: MOVES[i][1] * 80,
                      wave: MOVES[i][2] });
    }
    return { cells: result, width: columns * 80, height: bottom ? 160 : 80,
             submitX: top * 80, submitY: 0 };
}
function progress(elapsedMs, delayMs, durationMs) {
    return Math.max(0, Math.min(1, (elapsedMs - delayMs) / durationMs));
}
function ease(value) { return 1 - Math.pow(1 - value, 3); }
// All blocks appear at their starting positions before either movement wave.
var SLIDE_DURATION_MS = 134;
var REVEAL_DURATION_MS = 180 + 2 * SLIDE_DURATION_MS;
function revealFade(elapsedMs, rank) { return ease(progress(elapsedMs, rank * 4, 90)); }
function revealMovement(elapsedMs, wave) { return ease(progress(elapsedMs, 180 + wave * SLIDE_DURATION_MS, SLIDE_DURATION_MS)); }
function ranks(size) {
    const values = [];
    for (let i = 0; i < size; ++i) values.push(i);
    for (let j = size - 1; j > 0; --j) {
        const k = Math.floor(Math.random() * (j + 1));
        const swap = values[j];
        values[j] = values[k];
        values[k] = swap;
    }
    return values;
}
// One owner for every shared border, including expanding arms.
function edges(positions) {
    const map = {};
    positions.forEach(function(p, i) {
        [[p[0], p[1], 1, 80], [p[0] + 80, p[1], 1, 80],
         [p[0], p[1], 80, 1], [p[0], p[1] + 80, 80, 1]].forEach(function(e) {
            const key = e.join(":");
            if (!map[key]) map[key] = { x:e[0], y:e[1], w:e[2], h:e[3], owners:[] };
            map[key].owners.push(i);
        });
    });
    return Object.keys(map).map(function(key) { return map[key]; });
}

// Union collinear edges at their current positions, in physical-pixel space.
// Splitting at every endpoint also handles partially overlapping sliding edges.
function strokeSegments(boxes, scale, originX, originY) {
    scale = Math.max(0.1, scale);
    const groups = {};
    function edge(axis, coordinate, start, end, alpha) {
        if (alpha <= 0 || end <= start) return;
        const key = axis + ":" + coordinate;
        if (!groups[key]) groups[key] = {axis:axis, coordinate:coordinate, spans:[]};
        groups[key].spans.push({start:start, end:end, alpha:alpha});
    }
    boxes.forEach(function(box) {
        const x0 = Math.round(box.x * scale + originX);
        const x1 = Math.round((box.x + 80) * scale + originX);
        const y0 = Math.round(box.y * scale + originY);
        const y1 = Math.round((box.y + 80) * scale + originY);
        edge("v", x0, y0, y1, box.alpha);
        edge("v", x1, y0, y1, box.alpha);
        edge("h", y0, x0, x1, box.alpha);
        edge("h", y1, x0, x1, box.alpha);
    });
    const result = [];
    Object.keys(groups).forEach(function(key) {
        const group = groups[key];
        const points = [];
        group.spans.forEach(function(s) { points.push(s.start, s.end); });
        points.sort(function(a, b) { return a - b; });
        let previous = null;
        for (let i = 0; i + 1 < points.length; ++i) {
            const start = points[i], end = points[i + 1];
            let alpha = 0;
            if (end === start) continue;
            group.spans.forEach(function(s) {
                if (s.start <= start && s.end >= end) alpha = Math.max(alpha, s.alpha);
            });
            if (alpha <= 0) continue;
            if (previous && previous.end === start && previous.alpha === alpha) {
                previous.end = end;
            } else {
                previous = {start:start, end:end, alpha:alpha};
                result.push({group:group, span:previous});
            }
        }
    });
    return result.map(function(entry) {
        const group = entry.group, span = entry.span;
        const vertical = group.axis === "v";
        return { x: ((vertical ? group.coordinate : span.start) - originX) / scale,
                 y: ((vertical ? span.start : group.coordinate) - originY) / scale,
                 w: (vertical ? 1 : span.end - span.start) / scale,
                 h: (vertical ? span.end - span.start : 1) / scale, alpha: span.alpha };
    });
}
