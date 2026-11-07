// Sideload picker: fills the watch list from devices.json and points the two
// download buttons at the GitHub release files for the chosen watch.
(function () {
    'use strict';

    var RELEASE = 'https://github.com/Belidor/gta6-countdown/releases/download/sideload-v1/';
    var DEFAULT_ID = 'fr965';

    // devices.json sits next to this script, wherever the page includes it from.
    var script = document.currentScript || document.querySelector('script[src*="install.js"]');
    var DATA_URL = script && script.src
        ? new URL('devices.json', script.src).href
        : 'install/devices.json';

    // "fēnix 7X" -> "fenix 7x": no accents, lower case, so plain typing matches.
    function fold(s) {
        return String(s).normalize('NFKD').replace(/[̀-ͯ]/g, '').toLowerCase();
    }

    function init() {
        var root = document.getElementById('install');
        if (!root) return;

        var search = document.getElementById('ins-search');
        var list = document.getElementById('ins-device');
        var count = document.getElementById('ins-count');
        var nameEl = document.getElementById('ins-name');
        var filesEl = document.getElementById('ins-files');
        var glanceHint = document.getElementById('ins-glance');
        var errorHint = document.getElementById('ins-error');
        var buttons = {
            face: document.getElementById('ins-face'),
            app: document.getElementById('ins-app')
        };

        var devices = [];
        var byId = {};
        var current = null;

        function setButton(btn, file) {
            if (file) {
                btn.href = RELEASE + encodeURIComponent(file);
                btn.removeAttribute('aria-disabled');
                btn.removeAttribute('tabindex');
                btn.classList.remove('is-disabled');
            } else {
                btn.removeAttribute('href');
                btn.setAttribute('aria-disabled', 'true');
                btn.setAttribute('tabindex', '-1');
                btn.classList.add('is-disabled');
            }
        }

        function select(id) {
            var d = byId[id];
            if (!d) return;
            current = d;
            nameEl.textContent = d.name;
            setButton(buttons.face, d.face);
            setButton(buttons.app, d.app);
            filesEl.textContent = [d.face, d.app].filter(Boolean).join(' · ') || 'No files for this watch yet';
            glanceHint.hidden = !d.app || d.glance;
            if (list.value !== id) list.value = id;
        }

        function render() {
            if (!devices.length) return; // list not loaded yet: keep the static fallback
            var tokens = fold(search.value).split(/\s+/).filter(Boolean);
            var matches = devices.filter(function (d) {
                return tokens.every(function (t) { return d.hay.indexOf(t) !== -1; });
            });

            var frag = document.createDocumentFragment();
            matches.forEach(function (d) {
                var opt = document.createElement('option');
                opt.value = d.id;
                opt.textContent = d.name;
                frag.appendChild(opt);
            });
            list.replaceChildren(frag);

            count.textContent = matches.length === devices.length
                ? devices.length + ' watches'
                : matches.length + ' of ' + devices.length + ' watches';

            // Keep the choice while it is still in the list, else jump to the first match.
            if (current && matches.indexOf(current) !== -1) {
                list.value = current.id;
            } else if (matches.length) {
                select(matches[0].id);
            }
        }

        list.addEventListener('change', function () { select(list.value); });
        search.addEventListener('input', render);
        // Enter in the search field picks the first match instead of submitting anything.
        search.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                if (list.options.length) select(list.options[0].value);
            } else if (e.key === 'ArrowDown' && list.options.length) {
                e.preventDefault();
                list.focus();
            }
        });

        Object.keys(buttons).forEach(function (kind) {
            buttons[kind].addEventListener('click', function (e) {
                if (buttons[kind].getAttribute('aria-disabled') === 'true') {
                    e.preventDefault();
                    return;
                }
                if (window.gtag && current) {
                    window.gtag('event', 'sideload_download', { device: current.id, kind: kind });
                }
            });
        });

        fetch(DATA_URL)
            .then(function (r) {
                if (!r.ok) throw new Error('HTTP ' + r.status);
                return r.json();
            })
            .then(function (data) {
                devices = data.map(function (d) {
                    var n = fold(d.name);
                    // Match on the name, the name without spaces ("fenix7") and the device id ("fr965").
                    d.hay = n + ' ' + n.replace(/\s+/g, '') + ' ' + fold(d.id);
                    byId[d.id] = d;
                    return d;
                });
                current = byId[DEFAULT_ID] || devices[0] || null;
                render();
                if (current) select(current.id);
                // Show the preselected watch in the middle of the list, not on its bottom edge.
                if (list.selectedIndex > 0 && list.options.length) {
                    var row = list.scrollHeight / list.options.length;
                    list.scrollTop = Math.max(0, (list.selectedIndex + 0.5) * row - list.clientHeight / 2);
                }
            })
            .catch(function () {
                // Static fallback stays: Forerunner 965 links plus the release page.
                errorHint.hidden = false;
                search.disabled = true;
                current = { id: DEFAULT_ID };
            });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
