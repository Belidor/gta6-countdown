// Fills #screen with the countdown at render time, same layout as on the watch.
(function () {
    const el = document.getElementById('screen');
    if (!el) return;
    let s = Math.max(0, Math.floor((new Date(2026, 10, 19) - new Date()) / 1000));
    const v = window.FIXED || [Math.floor(s / 86400), Math.floor(s % 86400 / 3600), Math.floor(s % 3600 / 60), s % 60];
    const l = ['DAYS', 'HRS', 'MIN', 'SEC'];
    el.innerHTML = v.map((n, i) => '<div class="u"><span class="n">' + String(n).padStart(2, '0') + '</span><span class="l">' + l[i] + '</span></div>').join('<span class="s">:</span>');
})();
