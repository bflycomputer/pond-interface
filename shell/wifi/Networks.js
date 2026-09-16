.pragma library

function splitNmcli(line) {
  const result = [];
  let field = "";
  let escaped = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (escaped) {
      field += ch;
      escaped = false;
    } else if (ch === "\\") {
      escaped = true;
    } else if (ch === ":") {
      result.push(field);
      field = "";
    } else {
      field += ch;
    }
  }
  result.push(field);
  return result;
}

function parseNetworks(raw) {
  const strongest = Object.create(null);
  for (const line of String(raw).split("\n")) {
    const fields = splitNmcli(line);
    if (fields.length < 7 || fields[1] === "")
      continue;
    const strength = Math.max(0, Math.min(100, Number(fields[2]) || 0));
    const security = fields[3].trim();
    const entry = {
      ssid: fields[1],
      signal: strength,
      bars: strength >= 60 ? 3 : strength >= 35 ? 2 : 1,
      security: security,
      locked: security !== "" && security !== "--",
      connected: fields[0] === "*",
      channel: fields[4].trim(),
      frequency: fields[5].trim(),
      rate: fields[6].trim()
    };
    const previous = strongest[entry.ssid];
    if (!previous || (entry.connected && !previous.connected)
        || (entry.connected === previous.connected && entry.signal > previous.signal))
      strongest[entry.ssid] = entry;
  }
  return Object.keys(strongest).map(key => strongest[key]).sort((a, b) => {
    if (a.connected !== b.connected)
      return a.connected ? -1 : 1;
    return b.signal - a.signal || a.ssid.localeCompare(b.ssid);
  });
}

function bandForFrequency(frequency) {
  return frequency >= 5925 ? "6 GHz" : frequency >= 4900 ? "5 GHz"
      : frequency >= 2400 ? "2.4 GHz" : "—";
}
