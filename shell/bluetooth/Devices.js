.pragma library

function classifier(icon) {
  const value = String(icon || '').toLowerCase();
  if (/headset|headphone/.test(value)) return 'headphone';
  if (/keyboard/.test(value)) return 'keyboard';
  if (/mouse|touchpad|tablet/.test(value)) return 'mouse';
  if (/speaker|audio-card|audio-output/.test(value)) return 'speaker';
  if (/phone/.test(value)) return 'phone';
  return 'bluetooth';
}

function typeLabel(icon) {
  if (/touchpad/i.test(String(icon || ""))) return "Trackpad";
  return ({headphone: 'Headphones', keyboard: 'Keyboard', mouse: 'Mouse',
           speaker: 'Speaker', phone: 'Phone', bluetooth: 'Bluetooth device'})[classifier(icon)];
}

function powerDeviceFor(address, devices) {
  const mac = String(address || '').toLowerCase();
  if (!/^(?:[a-f0-9]{2}:){5}[a-f0-9]{2}$/.test(mac)) return null;
  return (devices || []).find(power => !power.powerSupply && power.ready
      && String(power.nativePath || '').toLowerCase().replace(/_/g, ':').indexOf(mac) >= 0) || null;
}

function batteryPercent(device, power) {
  if (device && device.batteryAvailable && isFinite(device.battery))
    return Math.round(Math.max(0, Math.min(1, device.battery)) * 100);
  if (power && isFinite(power.percentage))
    return Math.round(Math.max(0, Math.min(1, power.percentage)) * 100);
  return -1;
}
