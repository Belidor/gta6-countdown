// Keyboard access for the Buy Me a Coffee button.
// The widget (loaded at the end of index.html) builds a plain <div> that only reacts to the mouse.
// It builds the button on DOMContentLoaded, so setup runs just after that (and again on "load" as a fallback).
// Enter or Space opens and closes the panel. Escape closes it while focus is on this page
// (a key pressed inside the Buy Me a Coffee frame never reaches this page).
// When focus leaves the button and the panel, the panel closes.
(function () {
    function panelOverlay() {
        const frame = document.getElementById('bmc-iframe');
        return frame ? frame.parentElement : null;
    }
    function isOpen() {
        const overlay = panelOverlay();
        return !!overlay && overlay.style.width === '100%';
    }
    function close() {
        const overlay = panelOverlay();
        if (overlay && isOpen()) overlay.click();
    }

    // The widget swaps the button's content (cup image, chevron) on every open and close.
    // The button already has a label, so hide that content from screen readers.
    function hideDecoration(element) {
        Array.prototype.forEach.call(element.children, function (child) {
            child.setAttribute('aria-hidden', 'true');
        });
    }
    const narrow = window.matchMedia('(max-width: 479.98px)');

    function setup() {
        const button = document.getElementById('bmc-wbtn');
        if (!button || button.hasAttribute('role')) return;
        button.setAttribute('role', 'button');
        button.setAttribute('tabindex', '0');
        button.setAttribute('aria-label', 'Support me on Buy Me a Coffee');
        button.setAttribute('aria-expanded', 'false');
        hideDecoration(button);

        button.addEventListener('keydown', function (event) {
            if (event.key !== 'Enter' && event.key !== ' ') return;
            event.preventDefault();
            if (event.repeat) return;
            if (isOpen()) {
                close();
                return;
            }
            button.click();
            // On phones the open panel covers the whole screen and the button under it.
            // Put focus on the close cross, which the widget shows after 150 ms.
            if (narrow.matches) {
                setTimeout(function () {
                    const cross = document.getElementById('bmc-close-btn');
                    if (isOpen() && cross) cross.focus();
                }, 200);
            }
        });
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' && isOpen()) {
                close();
                button.focus();
            }
        });

        const overlay = panelOverlay();
        if (!overlay) return;
        document.addEventListener('focusin', function (event) {
            if (!isOpen()) return;
            const target = event.target;
            // On phones the open panel hides the button, so focus coming back to the button closes it too.
            if (narrow.matches && target === button) close();
            else if (!button.contains(target) && !overlay.contains(target)) close();
        });
        // The widget puts the panel before the button in the page, and the closed panel keeps its links
        // in the Tab order. Move it right after the button and make it inert while it is closed:
        // Tab then goes from the button into the open panel, and Shift+Tab comes back to the button.
        button.after(overlay);
        overlay.inert = !isOpen();

        // On phones the open panel covers the whole screen; its close cross is a plain <div>.
        const cross = document.getElementById('bmc-close-btn');
        if (cross) {
            cross.setAttribute('role', 'button');
            cross.setAttribute('tabindex', '0');
            cross.setAttribute('aria-label', 'Close');
            hideDecoration(cross);
            cross.addEventListener('keydown', function (event) {
                if (event.key !== 'Enter' && event.key !== ' ') return;
                event.preventDefault();
                close();
                button.focus();
            });
        }

        // Keep aria-expanded and inert in step with the panel, whether the mouse or the keyboard opened it.
        if ('MutationObserver' in window) {
            new MutationObserver(function () {
                const open = isOpen();
                button.setAttribute('aria-expanded', open ? 'true' : 'false');
                overlay.inert = !open;
            }).observe(overlay, { attributes: true, attributeFilter: ['style'] });
            new MutationObserver(function () {
                hideDecoration(button);
            }).observe(button, { childList: true });
        }
    }

    if (document.readyState === 'complete') setup();
    else {
        // setTimeout: the widget's own DOMContentLoaded listener must run first and build the button.
        document.addEventListener('DOMContentLoaded', function () { setTimeout(setup, 0); });
        window.addEventListener('load', setup);
    }
})();
