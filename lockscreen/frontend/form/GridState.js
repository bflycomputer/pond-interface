// Radial grid state shared by the greeter and session lock.
// Receives input lengths and result events from its caller to animate the
// expanding 13/17/21-cell grid without retaining credential characters.

var CELL_COUNT = 21;
var SHAPE_COUNT = 4;
var CELL_POSITIONS = Object.freeze([
    [160, 160], [80, 80], [240, 80], [240, 240], [80, 240],
    [0, 160], [160, 0], [320, 160], [160, 320], [80, 160],
    [160, 80], [240, 160], [160, 240],
    [-80, 160], [160, -80], [400, 160], [160, 400],
    [-160, 160], [160, -160], [480, 160], [160, 480]
].map(position => Object.freeze(position)));
var IDLE_SEQUENCES = [
    [1, 2, 3, 4],
    [6, 7, 8, 5]
];
var ANIMATION_INTERVALS_MS = {
    deleting: 150,
    errorFill: 45,
    errorHold: 130,
    errorOutline: 22.5,
    errorClear: 37.5,
    errorCenter: 210,
    successFill: 42.5,
    successOutline: 27.5
};

function normalizeSeed(seed) {
    return (Number(seed) >>> 0) || 0x6d2b79f5;
}

function createState(seed) {
    return {
        animationPhase: "idle",
        seed: normalizeSeed(seed),
        inputLength: 0,
        cellShapes: Array(CELL_COUNT).fill(-1),
        pendingInputLength: -1,
        blinkOn: true,
        blinkStep: 0,
        idleProgram: 0,
        idleStage: "add",
        idleIndex: 0,
        idleDots: [],
        idleRemovalOrder: [],
        errorFillQueue: [],
        errorFillCells: [],
        errorOutlineQueue: [],
        errorOutlineCells: [],
        errorClearQueue: [],
        successFillQueue: [],
        successOutlineQueue: [],
        successFillCells: [],
        successOutlineCells: []
    };
}

function createSucceededState(inputLength, seed) {
    const state = createState(seed);
    state.inputLength = normalizeLength(inputLength);
    state.animationPhase = "succeeded";
    return state;
}

function copyState(state) {
    const copy = Object.assign({}, state);
    for (const key of Object.keys(copy)) {
        if (Array.isArray(copy[key]))
            copy[key] = copy[key].slice();
    }
    return copy;
}

function nextRandom(state) {
    let value = state.seed >>> 0;
    value ^= value << 13;
    value ^= value >>> 17;
    value ^= value << 5;
    state.seed = normalizeSeed(value);
    return state.seed / 4294967296;
}

function randomInt(state, upperExclusive) {
    return Math.floor(nextRandom(state) * upperExclusive);
}

function shuffled(state, values) {
    const result = values.slice();
    for (let i = result.length - 1; i > 0; i--) {
        const j = randomInt(state, i + 1);
        const temporary = result[i];
        result[i] = result[j];
        result[j] = temporary;
    }
    return result;
}

function range(count) {
    return Array.from({length: count}, (_, index) => index);
}

function moveNextCell(queue, cells) {
    // Keep the last cell visible for a full tick before the caller advances animationPhase.
    if (!queue.length)
        return false;
    cells.push(queue.shift());
    return true;
}

function resetIdle(state) {
    state.idleProgram = 0;
    state.idleStage = "add";
    state.idleIndex = 0;
    state.idleDots = [];
    state.idleRemovalOrder = [];
}

function normalizeLength(length) {
    const value = Math.floor(Number(length));
    return isFinite(value) && value >= 0 ? value : 0;
}

function applyInputLength(state, inputLength) {
    const normalizedLength = normalizeLength(inputLength);
    const oldVisibleCount = Math.min(CELL_COUNT, state.inputLength);
    const newVisibleCount = Math.min(CELL_COUNT, normalizedLength);
    for (let i = 0; i < newVisibleCount; i++) {
        if (i >= oldVisibleCount || state.cellShapes[i] < 0)
            state.cellShapes[i] = randomInt(state, SHAPE_COUNT);
    }
    for (let clear = newVisibleCount; clear < CELL_COUNT; clear++)
        state.cellShapes[clear] = -1;

    state.inputLength = normalizedLength;
    state.pendingInputLength = -1;
    state.blinkOn = true;
    state.blinkStep = 0;
    state.animationPhase = state.inputLength === 0 ? "idle" : "typing";
    resetIdle(state);
    return state;
}

function visibleCellCount(length) {
    return length >= 16 ? 21 : length >= 12 ? 17 : 13;
}

function activeCellCount(state) {
    if (state.inputLength >= CELL_COUNT)
        return CELL_COUNT;
    return Math.max(1, state.inputLength + 1);
}

function inactiveCells(state) {
    return range(visibleCellCount(state.inputLength)).slice(activeCellCount(state));
}

function startError(state) {
    state.animationPhase = "errorFill";
    state.blinkOn = false;
    state.idleDots = [];
    state.pendingInputLength = -1;
    state.errorFillQueue = shuffled(state, range(activeCellCount(state)));
    state.errorFillCells = [];
    state.errorOutlineQueue = [];
    state.errorOutlineCells = [];
    state.errorClearQueue = [];
    return state;
}

function startSuccess(state) {
    const active = range(activeCellCount(state));
    state.animationPhase = "successFill";
    state.blinkOn = false;
    state.idleDots = [];
    state.pendingInputLength = -1;
    state.successFillQueue = shuffled(state, active);
    state.successOutlineQueue = shuffled(state, inactiveCells(state));
    state.successFillCells = [];
    state.successOutlineCells = [];
    return state;
}

function syncLength(state, inputLength) {
    const normalizedLength = normalizeLength(inputLength);
    if (state.animationPhase !== "idle" && state.animationPhase !== "typing"
            && state.animationPhase !== "deleting")
        return state;
    if (state.animationPhase === "deleting"
            && state.pendingInputLength === normalizedLength)
        return state;
    if (state.animationPhase !== "deleting" && state.inputLength === normalizedLength)
        return state;

    const next = copyState(state);
    if (normalizedLength < next.inputLength || next.animationPhase === "deleting") {
        if (next.animationPhase !== "deleting") {
            next.animationPhase = "deleting";
            next.blinkOn = false;
            next.idleDots = [];
        }
        next.pendingInputLength = normalizedLength;
        return next;
    }

    return applyInputLength(next, normalizedLength);
}

function beginAuthentication(state, inputLength) {
    const next = copyState(state);
    applyInputLength(next, inputLength);
    next.animationPhase = "authenticating";
    next.blinkOn = false;
    next.idleDots = [];
    return next;
}

function reduce(state, event) {
    if (!state || !event || typeof event.type !== "string")
        return state;

    if (event.type === "RESET") {
        return createState(event.seed === undefined
            ? (state.seed + 0x9e3779b9) >>> 0 : event.seed);
    }

    if (event.type === "SYNC_LENGTH")
        return syncLength(state, event.length);
    if (event.type === "AUTH_START")
        return beginAuthentication(state, event.length);
    if (event.type === "AUTH_FAILED")
        return startError(copyState(state));
    if (event.type === "AUTH_SUCCEEDED")
        return startSuccess(copyState(state));

    const next = copyState(state);

    if (event.type === "BLINK") {
        if (next.animationPhase === "idle" || next.animationPhase === "typing") {
            // Cycle through dot, off, Enter, off at 520ms per step.
            next.blinkStep = (next.blinkStep + 1) % 4;
            next.blinkOn = next.blinkStep % 2 === 0;
        }
        return next;
    }

    if (event.type === "IDLE_TICK") {
        if (next.animationPhase !== "idle" || next.inputLength !== 0)
            return state;
        const sequence = IDLE_SEQUENCES[next.idleProgram];
        if (next.idleStage === "add") {
            next.idleDots.push(sequence[next.idleIndex]);
            next.idleIndex += 1;
            if (next.idleIndex >= sequence.length) {
                next.idleStage = "remove";
                next.idleIndex = 0;
                next.idleRemovalOrder = shuffled(next, sequence);
            }
        } else if (next.idleStage === "remove") {
            next.idleDots = next.idleDots.filter(value => value !== next.idleRemovalOrder[next.idleIndex]);
            next.idleIndex += 1;
            if (next.idleIndex >= next.idleRemovalOrder.length) {
                next.idleStage = "pause";
                next.idleIndex = 0;
            }
        } else {
            next.idleProgram = (next.idleProgram + 1) % IDLE_SEQUENCES.length;
            next.idleStage = "add";
            next.idleIndex = 0;
            next.idleDots = [];
            next.idleRemovalOrder = [];
        }
        return next;
    }

    if (event.type !== "ANIMATION_TICK")
        return state;

    if (next.animationPhase === "deleting") {
        const targetLength = Math.max(0, next.pendingInputLength);
        const steppedLength = Math.max(targetLength, next.inputLength - 1);
        if (next.inputLength > 0 && next.inputLength <= CELL_COUNT)
            next.cellShapes[next.inputLength - 1] = -1;
        next.inputLength = steppedLength;
        if (steppedLength > targetLength)
            return next;
        return applyInputLength(next, targetLength);
    }

    if (next.animationPhase === "errorFill") {
        if (!moveNextCell(next.errorFillQueue, next.errorFillCells))
            next.animationPhase = "errorHold";
        return next;
    }

    if (next.animationPhase === "errorHold") {
        next.errorOutlineQueue = shuffled(next, inactiveCells(next));
        next.animationPhase = "errorOutline";
        return next;
    }

    if (next.animationPhase === "errorOutline") {
        if (moveNextCell(next.errorOutlineQueue, next.errorOutlineCells))
            return next;
        const clearable = range(activeCellCount(next)).slice(1);
        next.errorClearQueue = shuffled(next, clearable);
        next.animationPhase = "errorClear";
        return next;
    }

    if (next.animationPhase === "errorClear") {
        if (next.errorClearQueue.length) {
            const cleared = next.errorClearQueue.shift();
            next.errorFillCells = next.errorFillCells.filter(value => value !== cleared);
            next.errorOutlineCells.push(cleared);
        } else {
            next.errorFillCells = [0];
            next.animationPhase = "errorCenter";
        }
        return next;
    }

    if (next.animationPhase === "errorCenter")
        return createState(next.seed);

    if (next.animationPhase === "successFill") {
        if (!moveNextCell(next.successFillQueue, next.successFillCells))
            next.animationPhase = "successOutline";
        return next;
    }

    if (next.animationPhase === "successOutline") {
        if (!moveNextCell(next.successOutlineQueue, next.successOutlineCells))
            next.animationPhase = "succeeded";
        return next;
    }

    return state;
}

function normalVisual(state, cellIndex) {
    const visibleCount = Math.min(CELL_COUNT, state.inputLength);
    if (cellIndex < visibleCount) {
        return {
            mode: "shape",
            shape: state.cellShapes[cellIndex]
        };
    }
    if (cellIndex === state.inputLength && cellIndex < CELL_COUNT) {
        return {
            mode: !state.blinkOn ? "caretOff"
                : state.inputLength > 0 && state.blinkStep === 2 ? "caretEnter" : "caretOn",
            shape: -1
        };
    }
    if (state.idleDots.includes(cellIndex))
        return { mode: "idleDot", shape: -1 };
    return { mode: "empty", shape: -1 };
}

function exitCellVisible(state, cellIndex, exitStep = 0) {
    if (cellIndex < 0 || cellIndex >= visibleCellCount(state.inputLength))
        return false;
    if (exitStep <= 1)
        return true;
    if (exitStep === 2)
        return cellIndex < 1 || cellIndex > 4;
    if (exitStep === 3)
        return cellIndex === 0 || cellIndex >= 9;
    return false;
}

function cellVisual(state, cellIndex, exitStep = 0) {
    if (!state || cellIndex < 0 || cellIndex >= CELL_COUNT)
        return { mode: "hidden", shape: -1 };
    if (!exitCellVisible(state, cellIndex, exitStep))
        return { mode: "hidden", shape: -1 };

    if (state.animationPhase === "succeeded")
        return { mode: cellIndex < activeCellCount(state) ? "successFill" : "successOutline", shape: -1 };

    if (state.animationPhase === "deleting") {
        if (cellIndex === Math.min(CELL_COUNT, state.inputLength) - 1) {
            return {
                mode: "delete",
                shape: state.cellShapes[cellIndex]
            };
        }
        return normalVisual(state, cellIndex);
    }

    if (state.animationPhase === "errorFill") {
        if (state.errorFillCells.includes(cellIndex))
            return { mode: "errorFill", shape: -1 };
        return normalVisual(state, cellIndex);
    }

    if (state.animationPhase === "errorHold" || state.animationPhase === "errorOutline"
            || state.animationPhase === "errorClear" || state.animationPhase === "errorCenter") {
        if (state.errorFillCells.includes(cellIndex))
            return { mode: "errorFill", shape: -1 };
        if (state.errorOutlineCells.includes(cellIndex))
            return { mode: "errorOutline", shape: -1 };
        return { mode: "empty", shape: -1 };
    }

    if (state.animationPhase === "successFill" || state.animationPhase === "successOutline") {
        if (state.successFillCells.includes(cellIndex))
            return { mode: "successFill", shape: -1 };
        if (state.successOutlineCells.includes(cellIndex))
            return { mode: "successOutline", shape: -1 };
        if (state.animationPhase === "successFill")
            return normalVisual(state, cellIndex);
        return { mode: "empty", shape: -1 };
    }

    return normalVisual(state, cellIndex);
}

function acceptsInput(state) {
    return state.animationPhase === "idle" || state.animationPhase === "typing"
        || state.animationPhase === "deleting";
}

function isAnimating(state) {
    return typeof ANIMATION_INTERVALS_MS[state.animationPhase] === "number";
}

function animationIntervalMs(state) {
    return isAnimating(state) ? ANIMATION_INTERVALS_MS[state.animationPhase] : 100;
}
