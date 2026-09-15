.pragma library

var DEFAULTS = Object.freeze({
    brightness: 0.65,
    saturation: 0.70,
    warmth: 0.012,
    horizon: 0.84,
    twilight: 1.95,
    sunrise: 6.5,
    sunset: 18.5
});
var LIMITS = {
    brightness: [0.42, 0.78], saturation: [0, 1.15], warmth: [-0.025, 0.025],
    horizon: [0.68, 0.96], twilight: [0.5, 2], sunrise: [4, 9], sunset: [15, 22]
};

function wrap(hour) {
    return ((hour % 24) + 24) % 24;
}

function sanitize(settings) {
    const options = {};
    for (const key of Object.keys(DEFAULTS)) {
        options[key] = Number.isFinite(settings[key])
            ? Math.max(LIMITS[key][0], Math.min(LIMITS[key][1], settings[key])) : DEFAULTS[key];
    }
    return options;
}

// Oklab conversion: Björn Ottosson, https://bottosson.github.io/posts/oklab/ (public domain).
function hexToLab(hex) {
    const channels = hex.match(/[a-f\d]{2}/gi).map(value => parseInt(value, 16) / 255);
    const [r, g, b] = channels.map(value => value <= 0.04045
        ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
    const l = Math.cbrt(.4122214708 * r + .5363325363 * g + .0514459929 * b);
    const m = Math.cbrt(.2119034982 * r + .6806995451 * g + .1073969566 * b);
    const s = Math.cbrt(.0883024619 * r + .2817188376 * g + .6299787005 * b);
    return [
        .2104542553 * l + .793617785 * m - .0040720468 * s,
        1.9779984951 * l - 2.428592205 * m + .4505937099 * s,
        .0259040371 * l + .7827717662 * m - .808675766 * s
    ];
}

// Each time anchor defines six bands: zenith, upper sky, middle sky, haze, horizon, lower edge.
var ANCHORS = [
    [0, [0,.33,.59,.78,.90,1], ['080b16','0d1220','141d2d','1c2939','26313e','1b2331']],
    [3, [0,.40,.64,.80,.92,1], ['090d1b','111a2b','21324a','334958','514c50','262c3b']],
    [4.8, [0,.36,.62,.79,.91,1], ['131e32','293d53','4a5b68','756f73','a58372','555566']],
    [6.5, [0,.26,.49,.71,.90,1], ['2c4156','475e70','6f7b82','9b9187','bca080','8c817a']],
    [8.5, [0,.23,.48,.73,.91,1], ['3f596b','536c7b','728791','939e9e','acafa4','a0a298']],
    [12, [0,.25,.52,.75,.93,1], ['4d697b','617d8b','7a929c','94a4a7','aeb5b0','a6aca6']],
    [15, [0,.27,.52,.76,.93,1], ['4e6575','687d88','879698','a6a79c','b8af97','a89b89']],
    [17.3, [0,.27,.50,.73,.90,1], ['414e65','626c7c','89888a','ad9b8b','c2a183','a88877']],
    [18.5, [0,.30,.54,.77,.91,1], ['30364e','50536b','7c6e7d','a78380','b98f7a','7e6670']],
    [19.6, [0,.35,.60,.79,.91,1], ['1a223b','313e59','575d73','7d6a79','997773','4b485e']],
    [21, [0,.38,.63,.81,.93,1], ['0f1529','1c2942','2e4059','475369','62586b','2d334b']],
    [23, [0,.35,.60,.80,.92,1], ['090d1b','10192a','1b2b3f','293b4e','3d4655','232d3e']]
].map(([hour, positions, colors]) => ({
    hour,
    values: colors.reduce((values, color) => values.concat(hexToLab(color)), positions)
}));

// Shape-preserving cubic interpolation avoids overshooting colors and band positions.
function slope(d0, d1, h0, h1) {
    if (d0 * d1 <= 0)
        return 0;
    const w1 = 2 * h1 + h0, w2 = h1 + 2 * h0;
    return (w1 + w2) / (w1 / d0 + w2 / d1);
}

function cubic(y0, y1, m0, m1, h, u) {
    return (2 * u ** 3 - 3 * u * u + 1) * y0 + (u ** 3 - 2 * u * u + u) * h * m0
        + (-2 * u ** 3 + 3 * u * u) * y1 + (u ** 3 - u * u) * h * m1;
}

function periodicSample(hour) {
    const next = ANCHORS.findIndex(anchor => anchor.hour > hour);
    const i = next < 0 ? ANCHORS.length - 1 : next - 1;
    const count = ANCHORS.length;
    const at = index => {
        const anchor = ANCHORS[(index + count) % count];
        return { hour: anchor.hour + (index < 0 ? -24 : index >= count ? 24 : 0), values: anchor.values };
    };
    const [a, b, c, d] = [at(i - 1), at(i), at(i + 1), at(i + 2)];
    const h0 = b.hour - a.hour, h = c.hour - b.hour, h2 = d.hour - c.hour;
    const u = (hour - b.hour) / h;
    return b.values.map((value, k) => {
        const d0 = (value - a.values[k]) / h0;
        const d1 = (c.values[k] - value) / h, d2 = (d.values[k] - c.values[k]) / h2;
        return cubic(value, c.values[k], slope(d0, d1, h0, h), slope(d1, d2, h, h2), h, u);
    });
}

// Map local time onto the palette cycle, keeping the value and rate of change continuous at midnight.
function solarTime(hour, options) {
    const dawn = options.sunrise, dusk = options.sunset;
    const twilight = Math.min(options.twilight, (24 - dusk + dawn) / 3);
    const times = [dawn - twilight, dawn, dawn + twilight, dusk - twilight, dusk, dusk + twilight];
    const paletteTimes = [4.8, 6.5, 8.5, 17.3, 18.5, 19.6];
    let time = wrap(hour);
    if (time < times[0])
        time += 24;
    const next = times.findIndex(value => value > time);
    const i = next < 0 ? times.length - 1 : next - 1;
    const count = times.length;
    const at = index => {
        const offset = index < 0 ? -24 : index >= count ? 24 : 0;
        return { x: times[(index + count) % count] + offset, y: paletteTimes[(index + count) % count] + offset };
    };
    const [a, b, c, d] = [at(i - 1), at(i), at(i + 1), at(i + 2)];
    const h0 = b.x - a.x, h = c.x - b.x, h2 = d.x - c.x;
    const d0 = (b.y - a.y) / h0, d1 = (c.y - b.y) / h, d2 = (d.y - c.y) / h2;
    return wrap(cubic(b.y, c.y, slope(d0, d1, h0, h), slope(d1, d2, h, h2), h, (time - b.x) / h));
}

function skyState(hour, settings = DEFAULTS) {
    const options = sanitize(settings);
    const solarHour = solarTime(hour, options), values = periodicSample(solarHour);
    const positions = values.slice(0, 6).map(position => position ** (Math.log(options.horizon) / Math.log(.9)));
    return {
        hour: wrap(hour), solarHour, options,
        stops: positions.map((position, i) => ({ position, color: values.slice(6 + i * 3, 9 + i * 3) }))
    };
}
