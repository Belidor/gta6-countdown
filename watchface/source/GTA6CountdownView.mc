import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! GTA VI release date. The countdown ends at 00:00 on the watch's local clock.
//! If Rockstar moves the date again, change these three numbers and rebuild.
const RELEASE_YEAR = 2026;
const RELEASE_MONTH = 11;
const RELEASE_DAY = 19;

//! Colors from the 64-color MIP palette, so they look the same on MIP and AMOLED screens.
const COLOR_PINK = 0xFF55AA;
const COLOR_ORANGE = 0xFFAA00;
const COLOR_LIGHT = 0xAAAAAA;
const COLOR_DIM = 0x555555;

const SECONDS_PER_DAY = 86400;
const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

class GTA6CountdownView extends WatchUi.WatchFace {

    private var _logo as BitmapResource?;
    private var _isAwake as Boolean = true;
    private var _burnInProtection as Boolean = false;
    //! Release day 00:00 read as UTC. The local time zone offset is applied on every draw.
    private var _releaseAsUtc as Number = 0;

    public function initialize() {
        WatchFace.initialize();
        var settings = System.getDeviceSettings();
        if (settings has :requiresBurnInProtection) {
            _burnInProtection = settings.requiresBurnInProtection;
        }
        _releaseAsUtc = Gregorian.moment({
            :year => RELEASE_YEAR,
            :month => RELEASE_MONTH,
            :day => RELEASE_DAY,
            :hour => 0,
            :minute => 0,
            :second => 0
        }).value();
    }

    public function onLayout(dc as Dc) as Void {
        _logo = WatchUi.loadResource($.Rez.Drawables.Logo) as BitmapResource;
    }

    public function onExitSleep() as Void {
        _isAwake = true;
        WatchUi.requestUpdate();
    }

    public function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var clock = System.getClockTime();
        // Seconds until the local clock shows the release day 00:00. Zero or less means the game is out.
        var remaining = _releaseAsUtc - clock.timeZoneOffset - Time.now().value();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (!_isAwake && _burnInProtection) {
            drawAlwaysOn(dc, clock, remaining);
        } else {
            drawFull(dc, clock, remaining);
        }
    }

    //! Normal mode: time, logo, countdown. Seconds only while the watch is awake.
    private function drawFull(dc as Dc, clock as ClockTime, remaining as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.15).toNumber(), pickFontByHeight((h * 0.12).toNumber()), formatTime(clock), CENTER);

        var logo = _logo;
        if (logo != null) {
            dc.drawBitmap(cx - logo.getWidth() / 2, (h * 0.435).toNumber() - logo.getHeight() / 2, logo);
        }

        if (remaining > 0) {
            drawCountdown(dc, cx, (h * 0.70).toNumber(), (w * 0.80).toNumber(), (h * 0.11).toNumber(), remaining);
            dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.885).toNumber(), Graphics.FONT_XTINY, releaseDateText(), CENTER);
        } else {
            dc.setColor(COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.70).toNumber(), Graphics.FONT_MEDIUM, "OUT NOW", CENTER);
            dc.setColor(COLOR_LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, (h * 0.82).toNumber(), Graphics.FONT_XTINY, "DAY " + (-remaining / SECONDS_PER_DAY + 1), CENTER);
        }
    }

    //! Digits "DD:HH:MM[:SS]" with a small label under each group.
    private function drawCountdown(dc as Dc, cx as Number, y as Number, maxWidth as Number, maxAscent as Number, remaining as Number) as Void {
        var values = [
            remaining / SECONDS_PER_DAY,
            (remaining % SECONDS_PER_DAY) / 3600,
            (remaining % 3600) / 60
        ] as Array<Number>;
        if (_isAwake) {
            values.add(remaining % 60);
        }

        var parts = [] as Array<String>;
        for (var i = 0; i < values.size(); i++) {
            parts.add(values[i].format("%02d"));
        }
        var line = join(parts, ":");

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
            dc.setColor(COLOR_PINK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, parts[i], LEFT);
            dc.setColor(COLOR_LIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + partWidth / 2, labelY, Graphics.FONT_XTINY, labels[i], CENTER);
            x += partWidth;
            if (i < parts.size() - 1) {
                dc.setColor(COLOR_DIM, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, y, font, ":", LEFT);
                x += colonWidth;
            }
        }
    }

    //! Always-on mode on AMOLED: few lit pixels, no logo, small shift every minute against burn-in.
    private function drawAlwaysOn(dc as Dc, clock as ClockTime, remaining as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var step = h / 40;
        var shiftsX = [0, 1, -1, -1, 1] as Array<Number>;
        var shiftsY = [0, 1, 1, -1, -1] as Array<Number>;
        var shift = clock.min % shiftsX.size();
        var cx = w / 2 + shiftsX[shift] * step;
        var cy = h / 2 + shiftsY[shift] * step;

        dc.setColor(COLOR_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.09).toNumber(), pickFontByHeight((h * 0.12).toNumber()), formatTime(clock), CENTER);

        var text = "OUT NOW";
        if (remaining > 0) {
            text = Lang.format("$1$d $2$h $3$m", [
                (remaining / SECONDS_PER_DAY).format("%02d"),
                ((remaining % SECONDS_PER_DAY) / 3600).format("%02d"),
                ((remaining % 3600) / 60).format("%02d")
            ]);
        }
        dc.setColor(COLOR_PINK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + (h * 0.10).toNumber(), Graphics.FONT_SMALL, text, CENTER);
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

    //! Largest number font whose digits are not taller than maxAscent.
    private function pickFontByHeight(maxAscent as Number) as FontDefinition {
        var fonts = [
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE
        ] as Array<FontDefinition>;
        for (var i = 0; i < fonts.size(); i++) {
            if (Graphics.getFontAscent(fonts[i]) <= maxAscent) {
                return fonts[i];
            }
        }
        return Graphics.FONT_MEDIUM;
    }

    private function formatTime(clock as ClockTime) as String {
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return hour.format("%d") + ":" + clock.min.format("%02d");
    }

    private function releaseDateText() as String {
        return RELEASE_DAY.format("%02d") + "." + RELEASE_MONTH.format("%02d") + "." + RELEASE_YEAR;
    }

    private function join(parts as Array<String>, separator as String) as String {
        var result = "";
        for (var i = 0; i < parts.size(); i++) {
            if (i > 0) {
                result += separator;
            }
            result += parts[i];
        }
        return result;
    }
}
