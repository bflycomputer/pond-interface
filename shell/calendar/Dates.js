.pragma library

function monthStart(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1, 12);
}

function sameMonth(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth();
}

function sameDay(a, b) {
  return sameMonth(a, b) && a.getDate() === b.getDate();
}

function shiftMonth(date, delta) {
  return new Date(date.getFullYear(), date.getMonth() + delta, 1, 12);
}

// Local calendar arithmetic (not millisecond offsets) stays correct across DST.
function monthDays(month) {
  const year = month.getFullYear();
  const index = month.getMonth();
  const offset = (new Date(year, index, 1, 12).getDay() + 6) % 7;
  const count = new Date(year, index + 1, 0, 12).getDate();
  const rows = Math.ceil((offset + count) / 7);
  const days = [];
  for (let i = 0; i < rows * 7; i++)
    days.push(new Date(year, index, i - offset + 1, 12));
  return days;
}

function currentWeekRow(days, today) {
  const index = days.findIndex(day => sameDay(day, today));
  return index < 0 ? -1 : Math.floor(index / 7);
}
