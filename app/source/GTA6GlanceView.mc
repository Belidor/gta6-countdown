import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

//! One row in the glance list: title and time left.
//! The watch draws the launcher icon (the logo) to the left of this row by itself.
(:glance)
class GTA6GlanceView extends WatchUi.GlanceView {

    private var _timer as Timer.Timer?;

    public function initialize() {
        GlanceView.initialize();
    }

    //! The text changes once a minute, so a 10-second refresh is enough and keeps scrolling smooth.
    public function onShow() as Void {
        var timer = new Timer.Timer();
        timer.start(method(:onTick), 10000, true);
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
        var remaining = Countdown.secondsLeft();

        var title = "GTA VI - DAY " + Countdown.dayAfterRelease(remaining);
        var value = "OUT NOW";
        var valueColor = Countdown.COLOR_ORANGE;
        if (remaining > 0) {
            title = "GTA VI";
            value = Countdown.shortText(remaining);
            valueColor = Countdown.COLOR_PINK;
        }

        // Largest value font that fits the row width and leaves room for the title above it.
        var titleFont = Graphics.FONT_GLANCE;
        var titleHeight = dc.getFontHeight(titleFont);
        var fonts = [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_GLANCE] as Array<FontDefinition>;
        var valueFont = Graphics.FONT_XTINY as FontDefinition;
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(value, fonts[i]) <= w && titleHeight + dc.getFontHeight(fonts[i]) <= h) {
                valueFont = fonts[i];
                break;
            }
        }

        // Title and value as one block, centered in the row.
        var top = (h - titleHeight - dc.getFontHeight(valueFont)) / 2;
        dc.setColor(Countdown.COLOR_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, top, titleFont, title, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, top + titleHeight, valueFont, value, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
