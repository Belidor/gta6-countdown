import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! Countdown math and colors shared by the full screen and the glance.
(:glance)
module Countdown {

    //! GTA VI release date. The countdown ends at 00:00 on the watch's local clock.
    //! If Rockstar moves the date again, change these three numbers and rebuild.
    const RELEASE_YEAR = 2026;
    const RELEASE_MONTH = 11;
    const RELEASE_DAY = 19;

    const SECONDS_PER_DAY = 86400;

    //! Colors from the 64-color MIP palette, so they look the same on MIP and AMOLED screens.
    const COLOR_PINK = 0xFF55AA;
    const COLOR_ORANGE = 0xFFAA00;
    const COLOR_LIGHT = 0xAAAAAA;
    const COLOR_DIM = 0x555555;

    //! Seconds until the local clock shows the release day 00:00. Zero or less means the game is out.
    function secondsLeft() as Number {
        var releaseAsUtc = Gregorian.moment({
            :year => RELEASE_YEAR,
            :month => RELEASE_MONTH,
            :day => RELEASE_DAY,
            :hour => 0,
            :minute => 0,
            :second => 0
        }).value();
        return releaseAsUtc - System.getClockTime().timeZoneOffset - Time.now().value();
    }

    //! 1 on the release day, 2 on the next day, and so on.
    function dayAfterRelease(remaining as Number) as Number {
        return -remaining / SECONDS_PER_DAY + 1;
    }

    //! "11d 05h 44m"
    function shortText(remaining as Number) as String {
        return Lang.format("$1$d $2$h $3$m", [
            (remaining / SECONDS_PER_DAY).format("%02d"),
            ((remaining % SECONDS_PER_DAY) / 3600).format("%02d"),
            ((remaining % 3600) / 60).format("%02d")
        ]);
    }

    function releaseDateText() as String {
        return RELEASE_DAY.format("%02d") + "." + RELEASE_MONTH.format("%02d") + "." + RELEASE_YEAR;
    }
}
