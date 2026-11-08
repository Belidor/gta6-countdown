// GTA VI release: 19 November 2026, 00:00 in the visitor's time zone, same rule as on the watch.
const RELEASE = new Date(2026, 10, 19, 0, 0, 0);

// Live countdown
const pad = (n) => String(n).padStart(2, '0');
const parts = {};
document.querySelectorAll('[data-part]').forEach((el) => { parts[el.dataset.part] = el; });
const digits = document.getElementById('digits');
const out = document.getElementById('out');
const statDays = document.getElementById('stat-days');

// The watch photo in the hero gets a live screen: the visitor's time and the same countdown.
// Everything for it stays in this function. If a part of its markup is missing, the photo keeps
// its own screen and the countdown on the page still runs.
const updateWatchFace = (() => {
    const face = document.getElementById('face-live');
    const img = face && face.parentElement.querySelector('img');
    const el = {};
    if (face) face.querySelectorAll('[data-face]').forEach((n) => { el[n.dataset.face] = n; });
    if (!img || !['time', 'd', 'h', 'm', 's', 'day'].every((k) => el[k])) return () => {};

    // Like the watch: 12-hour digits ("8:40") where the locale uses a 12-hour clock, else "20:40". No AM/PM.
    const clock = new Intl.DateTimeFormat(undefined, { hour: 'numeric' }).resolvedOptions();
    const hourCycle = clock.hourCycle || (clock.hour12 ? 'h12' : 'h23');
    const time = (now) => {
        let h = now.getHours();
        if (hourCycle === 'h11' || hourCycle === 'h12') h %= 12;
        if (h === 0 && hourCycle === 'h12') h = 12;
        return h + ':' + pad(now.getMinutes());
    };

    // Show the overlay only over the loaded photo, never over a missing or half-loaded one.
    // The black patches come first and hide the frozen numbers of the photo. The text follows when
    // Roboto is ready, so the digits do not jump from a fallback font. If Roboto is late, the text
    // shows in the fallback font after 3 s. Without JavaScript the photo keeps its own screen.
    const photo = new Promise((resolve, reject) => {
        const check = () => (img.naturalWidth ? resolve() : reject());
        if (img.complete) check();
        else {
            img.addEventListener('load', check, { once: true });
            img.addEventListener('error', reject, { once: true });
        }
    }).then(() => (img.decode ? img.decode().catch(() => {}) : undefined));
    const font = new Promise((resolve) => {
        setTimeout(resolve, 3000);
        if (document.fonts) document.fonts.load('1em Roboto', '0123456789:').then(resolve, resolve);
        else resolve();
    });
    // A minimum font size in the browser would make the small labels too wide. If the browser has one,
    // home.css lays the screen out 4 times larger (.is-big). Two probes in the same font tell.
    const probe = (px) => {
        const span = document.createElement('span');
        span.textContent = 'DAY HR MIN SEC';
        span.style.cssText = 'position:absolute;visibility:hidden;white-space:nowrap;font-size:' + px + 'px';
        face.append(span);
        const width = span.getBoundingClientRect().width;
        span.remove();
        return width;
    };
    photo.then(() => {
        face.hidden = false;
        if (probe(8) * 10 > probe(80) * 1.05) face.classList.add('is-big');
        return font;
    }).then(() => { face.classList.add('is-ready'); }, () => {});

    // values: the two-digit d, h, m, s of the countdown, or null from the release on (then day is "DAY N").
    return (now, values, day) => {
        el.time.textContent = time(now);
        face.classList.toggle('is-out', !values);
        if (values) for (const key in values) el[key].textContent = values[key];
        else el.day.textContent = day;
    };
})();

function tick() {
    const now = new Date();
    // Whole seconds left, rounded up like the watch: 00:00:00:01 until midnight, OUT NOW from 00:00:00.
    let s = Math.ceil((RELEASE - now) / 1000);
    const isOut = s <= 0;
    digits.hidden = isOut;
    out.hidden = !isOut;
    if (isOut) {
        const day = 'DAY ' + (Math.floor(-s / 86400) + 1);
        out.textContent = 'OUT NOW · ' + day;
        statDays.textContent = '0';
        updateWatchFace(now, null, day);
        return;
    }
    const d = Math.floor(s / 86400); s %= 86400;
    const h = Math.floor(s / 3600); s %= 3600;
    const m = Math.floor(s / 60); s %= 60;
    const values = { d: pad(d), h: pad(h), m: pad(m), s: pad(s) };
    for (const key in values) parts[key].textContent = values[key];
    statDays.textContent = String(d);
    updateWatchFace(now, values);
}

// Update at the start of each second of the system clock, like the watch.
(function loop() {
    setTimeout(loop, 1000 - (Date.now() % 1000));
    tick();
})();
