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
  const days = [];
  for (let i = 0; i < 42; i++)
    days.push(new Date(year, index, i - offset + 1, 12));
  return days;
}

function currentWeekRow(days, today) {
  const index = days.findIndex(day => sameDay(day, today));
  return index < 0 ? -1 : Math.floor(index / 7);
}

function decadeStart(year) {
  return Math.floor(year / 10) * 10;
}

// Sixteen years, with the decade centered the way the Windows calendar does.
function yearPage(year) {
  const start = decadeStart(year) - 2;
  const years = [];
  for (let i = 0; i < 16; i++)
    years.push(start + i);
  return years;
}

function inDecade(year, anchorYear) {
  const start = decadeStart(anchorYear);
  return year >= start && year < start + 10;
}
