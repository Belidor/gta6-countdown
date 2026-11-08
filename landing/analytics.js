// Google Analytics 4, loaded only after the visitor allows it.
// The choice is kept in localStorage; "Analytics settings" in the footer reopens the banner.
// "Decline" also withdraws an earlier "Allow": GA stops at once and its cookies are deleted.
(function () {
    const GA_ID = 'G-RV98YPRNH7';
    const KEY = 'gta6-analytics';

    function readChoice() {
        try { return localStorage.getItem(KEY); } catch (e) { return null; }
    }
    function saveChoice(value) {
        try { localStorage.setItem(KEY, value); } catch (e) { /* storage may be blocked */ }
    }

    // A GA cookie can sit on the host only, on the host as a domain, or on a parent domain.
    // On the live site: host-only, gta6-garmin.belidor.cc and belidor.cc (the old script let GA pick
    // .belidor.cc). The browser ignores a domain that it would not accept, so the list is safe anywhere.
    function cookieDomains() {
        const labels = location.hostname.split('.');
        const list = [''];
        for (let i = 0; i < labels.length - 1; i++) list.push('; domain=' + labels.slice(i).join('.'));
        return list;
    }
    function deleteGACookies(domains) {
        document.cookie.split(';')
            .map(function (c) { return c.split('=')[0].trim(); })
            .filter(function (n) { return n === '_ga' || n.indexOf('_ga_') === 0; })
            .forEach(function (n) {
                domains.forEach(function (d) { document.cookie = n + '=; Max-Age=0; path=/' + d; });
            });
    }

    let loaded = false;
    function loadGA() {
        window['ga-disable-' + GA_ID] = false;
        if (loaded) return;
        loaded = true;
        // Remove GA cookies left on a parent domain (.belidor.cc) by the old script, so the
        // client ID is not sent to other belidor.cc sites. GA sets new ones on this host only.
        deleteGACookies(cookieDomains().slice(2));
        window.dataLayer = window.dataLayer || [];
        window.gtag = function () { window.dataLayer.push(arguments); };
        window.gtag('consent', 'default', {
            analytics_storage: 'granted',
            ad_storage: 'denied',
            ad_user_data: 'denied',
            ad_personalization: 'denied'
        });
        // These settings must be a 'set' before 'js'. The current gtag.js ignores cookie settings
        // in 'config' and then puts _ga on .belidor.cc for 2 years (tested on 8 November 2026).
        window.gtag('set', {
            cookie_domain: 'gta6-garmin.belidor.cc',
            cookie_expires: 34128000, // 395 days, about 13 months
            allow_google_signals: false,
            allow_ad_personalization_signals: false
        });
        window.gtag('js', new Date());
        window.gtag('config', GA_ID);
        const s = document.createElement('script');
        s.async = true;
        s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
        document.head.appendChild(s);
    }

    // Withdrawal: stop GA in this page, tell it that consent is gone, delete its cookies.
    function revokeGA() {
        window['ga-disable-' + GA_ID] = true;
        if (typeof window.gtag === 'function') window.gtag('consent', 'update', { analytics_storage: 'denied' });
        deleteGACookies(cookieDomains());
    }

    const css = `
.ga-banner { position: fixed; left: 16px; right: 16px; bottom: 16px; z-index: 1000; max-width: 560px;
  margin: 0 auto; padding: 16px 18px; background: #F5F5F0; color: #323232; border: 2px solid #323232;
  box-shadow: 6px 6px 0 #323232; font: 14px/1.5 'Fira Mono', ui-monospace, monospace; }
.ga-banner p { margin: 0 0 12px; }
.ga-banner a { color: inherit; text-decoration: underline; }
.ga-banner .ga-buttons { display: flex; gap: 12px; flex-wrap: wrap; }
.ga-banner button { font: 500 14px 'Fira Mono', ui-monospace, monospace; padding: 8px 16px; cursor: pointer;
  border: 2px solid #323232; background: #F5F5F0; color: #323232; }
.ga-banner button.ga-allow { background: #323232; color: #F5F5F0; }
.ga-settings { background: none; border: 0; padding: 0; font: inherit; color: inherit; text-decoration: underline; cursor: pointer; }
`;

    function showBanner() {
        if (document.querySelector('.ga-banner')) return;
        const choice = readChoice();
        const now = choice === 'granted' ? ' Your current choice: Allow.'
            : choice === 'denied' ? ' Your current choice: Decline.' : '';
        const box = document.createElement('div');
        box.className = 'ga-banner';
        box.setAttribute('role', 'dialog');
        box.setAttribute('aria-label', 'Analytics consent');
        // The link scrolls to the #privacy section of the page.
        box.innerHTML = '<p>Can this site use Google Analytics to count visits, clicks and downloads? No ads, no personal profile. ' +
            '<a href="#privacy">Privacy</a>.' + now + '</p>' +
            '<div class="ga-buttons"><button type="button" class="ga-allow">Allow</button>' +
            '<button type="button" class="ga-decline">Decline</button></div>';
        box.querySelector('.ga-allow').addEventListener('click', function () {
            saveChoice('granted');
            box.remove();
            loadGA();
        });
        box.querySelector('.ga-decline').addEventListener('click', function () {
            revokeGA();
            saveChoice('denied');
            box.remove();
            // gtag.js cannot be unloaded. A reload gives a clean page without it.
            if (loaded) location.reload();
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
        else {
            // Declined or not asked yet: no GA cookie may stay, also not one from an older visit.
            deleteGACookies(cookieDomains());
            if (choice !== 'denied') showBanner();
        }
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
})();
