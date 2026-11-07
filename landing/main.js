// GTA VI release: 19 November 2026, 00:00 in the visitor's time zone, same rule as on the watch.
const RELEASE = new Date(2026, 10, 19, 0, 0, 0);

// Live countdown
const pad = (n) => String(n).padStart(2, '0');
const parts = {};
document.querySelectorAll('[data-part]').forEach((el) => { parts[el.dataset.part] = el; });
const digits = document.getElementById('digits');
const out = document.getElementById('out');
const statDays = document.getElementById('stat-days');

function tick() {
    let s = Math.floor((RELEASE - new Date()) / 1000);
    if (s <= 0) {
        digits.hidden = true;
        out.hidden = false;
        out.textContent = 'OUT NOW · DAY ' + (Math.floor(-s / 86400) + 1);
        statDays.textContent = '0';
        return;
    }
    const d = Math.floor(s / 86400); s %= 86400;
    const h = Math.floor(s / 3600); s %= 3600;
    const m = Math.floor(s / 60); s %= 60;
    parts.d.textContent = pad(d);
    parts.h.textContent = pad(h);
    parts.m.textContent = pad(m);
    parts.s.textContent = pad(s);
    statDays.textContent = String(d);
}
tick();
setInterval(tick, 1000);
