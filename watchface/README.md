# GTA VI Countdown — watch face

Shows the time, the GTA VI logo and a countdown to 19 November 2026, 00:00 on
the watch clock.

## Modes

- **Normal.** Time, logo, `DD:HH:MM:SS` countdown and the release date.
- **Always-on (AMOLED).** Only the time and the countdown without seconds, no
  logo. The text moves a little every minute against burn-in.
- **Sleep on MIP screens.** Same as normal, without seconds.
- **After release.** `OUT NOW` and the day number since launch.

## Build

```bash
./build.sh              # bin/GTA6Countdown-fr965.prg for Forerunner 965
./build.sh fenix7       # .prg for another device
./build.sh products     # refresh the device list in manifest.xml
./build.sh export       # bin/GTA6Countdown.iq for every device
```

The device list keeps watches with Connect IQ 3.0+ and a color screen
(`tools/update_products.py`).

## Sideload

Copy `bin/GTA6Countdown-fr965.prg` to `GARMIN/Apps` on the watch, unplug it,
then hold UP → Watch Face → GTA VI Countdown.

## Release date

`RELEASE_YEAR`, `RELEASE_MONTH` and `RELEASE_DAY` at the top of
`source/GTA6CountdownView.mc`.

## Logo

The GTA VI logo is a trademark of Take-Two Interactive Software, Inc. It is not
covered by the MIT license. `art/gta6_logo_source.png` is the source file;
the build uses `resources/drawables/gta6_logo.png` and scales it per screen.
