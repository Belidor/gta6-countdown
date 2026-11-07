import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

//! Full screen: big logo and a live countdown with seconds. BACK closes the app.
class GTA6View extends WatchUi.View {

    private var _logo as BitmapResource?;
    private var _timer as Timer.Timer?;

    public function initialize() {
        View.initialize();
    }

    public function onLayout(dc as Dc) as Void {
        _logo = WatchUi.loadResource($.Rez.Drawables.Logo) as BitmapResource;
    }

    public function onShow() as Void {
        var timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
        _timer = timer;
    }

    public function onHide() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
            _timer = null;
        }
    }

    public function onTick() as Void {
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var remaining = Countdown.secondsLeft();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var logo = _logo;
        if (logo != null) {
            dc.drawBitmap(cx - logo.getWidth() / 2, (h * 0.36).toNumber() - logo.getHeight() / 2, logo);
        }

        if (remaining > 0) {
            drawCountdown(dc, cx, (h * 0.69).toNumber(), (w * 0.82).toNumber(), (h * 0.12).toNumber(), remaining);
            dc.setColor(Countdown.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.885).toNumber(), Graphics.FONT_XTINY, Countdown.releaseDateText(), CENTER);
        } else {
            dc.setColor(Countdown.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.69).toNumber(), Graphics.FONT_MEDIUM, "OUT NOW", CENTER);
            dc.setColor(Countdown.COLOR_LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.81).toNumber(), Graphics.FONT_XTINY, "DAY " + Countdown.dayAfterRelease(remaining), CENTER);
        }
    }

    //! Digits "DD:HH:MM:SS" with a small label under each group.
    private function drawCountdown(dc as Dc, cx as Number, y as Number, maxWidth as Number, maxAscent as Number, remaining as Number) as Void {
        var values = [
            remaining / Countdown.SECONDS_PER_DAY,
            (remaining % Countdown.SECONDS_PER_DAY) / 3600,
            (remaining % 3600) / 60,
            remaining % 60
        ] as Array<Number>;

        var parts = [] as Array<String>;
        var line = "";
        for (var i = 0; i < values.size(); i++) {
            parts.add(values[i].format("%02d"));
            line += (i > 0 ? ":" : "") + parts[i];
        }

        var fonts = [
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL
        ] as Array<FontDefinition>;
        var font = Graphics.FONT_TINY as FontDefinition;
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(line, fonts[i]) <= maxWidth && Graphics.getFontAscent(fonts[i]) <= maxAscent) {
                font = fonts[i];
                break;
            }
        }

        // With VCENTER the text box is centered on y; the digits sit on the baseline.
        var baseline = y - dc.getFontHeight(font) / 2 + Graphics.getFontAscent(font);
        var labelY = baseline + dc.getFontHeight(Graphics.FONT_XTINY) / 2 + 2;
        var colonWidth = dc.getTextWidthInPixels(":", font);
        var x = cx - dc.getTextWidthInPixels(line, font) / 2;
        var labels = pickLabels(dc, dc.getTextWidthInPixels("00", font) + colonWidth / 2);

        for (var i = 0; i < parts.size(); i++) {
            var partWidth = dc.getTextWidthInPixels(parts[i], font);
            dc.setColor(Countdown.COLOR_PINK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, parts[i], LEFT);
            dc.setColor(Countdown.COLOR_LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + partWidth / 2, labelY, Graphics.FONT_XTINY, labels[i], CENTER);
            x += partWidth;
            if (i < parts.size() - 1) {
                dc.setColor(Countdown.COLOR_DIM, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, y, font, ":", LEFT);
                x += colonWidth;
            }
        }
    }

    //! Longest label set where every label fits under its two digits without touching the next one.
    private function pickLabels(dc as Dc, slotWidth as Number) as Array<String> {
        var sets = [
            ["DAYS", "HRS", "MIN", "SEC"],
            ["DAY", "HR", "MIN", "SEC"],
            ["D", "H", "M", "S"]
        ] as Array<Array<String>>;
        for (var s = 0; s < sets.size() - 1; s++) {
            var fits = true;
            for (var i = 0; i < sets[s].size(); i++) {
                if (dc.getTextWidthInPixels(sets[s][i], Graphics.FONT_XTINY) > slotWidth) {
                    fits = false;
                    break;
                }
            }
            if (fits) {
                return sets[s];
            }
        }
        return sets[sets.size() - 1];
    }
}
