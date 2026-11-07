// Google Analytics 4, loaded only after the visitor allows it.
// The choice is kept in localStorage; "Analytics settings" in the footer reopens the banner.
(function () {
    const GA_ID = 'G-RV98YPRNH7';
    const KEY = 'gta6-analytics';

    function readChoice() {
        try { return localStorage.getItem(KEY); } catch (e) { return null; }
    }
    function saveChoice(value) {
        try { localStorage.setItem(KEY, value); } catch (e) { /* storage may be blocked */ }
    }

    let loaded = false;
    function loadGA() {
        if (loaded) return;
        loaded = true;
        window.dataLayer = window.dataLayer || [];
        window.gtag = function () { window.dataLayer.push(arguments); };
        window.gtag('js', new Date());
        window.gtag('config', GA_ID, { anonymize_ip: true });
        const s = document.createElement('script');
        s.async = true;
        s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
        document.head.appendChild(s);
    }

    const css = `
.ga-banner { position: fixed; left: 16px; right: 16px; bottom: 16px; z-index: 1000; max-width: 560px;
  margin: 0 auto; padding: 16px 18px; background: #F5F5F0; color: #323232; border: 2px solid #323232;
  box-shadow: 6px 6px 0 #323232; font: 14px/1.5 'Fira Mono', ui-monospace, monospace; }
.ga-banner p { margin: 0 0 12px; }
.ga-banner .ga-buttons { display: flex; gap: 12px; flex-wrap: wrap; }
.ga-banner button { font: 500 14px 'Fira Mono', ui-monospace, monospace; padding: 8px 16px; cursor: pointer;
  border: 2px solid #323232; background: #F5F5F0; color: #323232; }
.ga-banner button.ga-allow { background: #323232; color: #F5F5F0; }
.ga-settings { background: none; border: 0; padding: 0; font: inherit; color: inherit; text-decoration: underline; cursor: pointer; }
`;

    function showBanner() {
        if (document.querySelector('.ga-banner')) return;
        const box = document.createElement('div');
        box.className = 'ga-banner';
        box.setAttribute('role', 'dialog');
        box.setAttribute('aria-label', 'Analytics consent');
        box.innerHTML = '<p>Can this site use Google Analytics to count visits and downloads? No ads, no personal profile.</p>' +
            '<div class="ga-buttons"><button type="button" class="ga-allow">Allow</button>' +
            '<button type="button" class="ga-decline">Decline</button></div>';
        box.querySelector('.ga-allow').addEventListener('click', function () {
            saveChoice('granted');
            box.remove();
            loadGA();
        });
        box.querySelector('.ga-decline').addEventListener('click', function () {
            saveChoice('denied');
            box.remove();
        });
        document.body.appendChild(box);
    }

    function addSettingsLink() {
        const footer = document.querySelector('footer .wrap') || document.querySelector('footer');
        if (!footer || footer.querySelector('.ga-settings')) return;
        const p = document.createElement('p');
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'ga-settings';
        b.textContent = 'Analytics settings';
        b.addEventListener('click', showBanner);
        p.appendChild(b);
        footer.appendChild(p);
    }

    function init() {
        const style = document.createElement('style');
        style.textContent = css;
        document.head.appendChild(style);
        addSettingsLink();
        const choice = readChoice();
        if (choice === 'granted') loadGA();
        else if (choice !== 'denied') showBanner();
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
})();
