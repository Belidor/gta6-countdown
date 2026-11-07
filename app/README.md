# GTA VI Countdown — app with a glance

The same countdown as the watch face in `../watchface`, but as a watch app, so
any watch face can stay on.

## Where it shows up

- **Glance list.** Press UP or DOWN on the watch face: one line, `GTA VI` and
  `11d 05h 44m`. The watch draws the launcher icon next to it.
- **Apps list.** Press START and pick GTA VI Countdown.
- **Full screen.** Select the glance or open the app: big logo and a
  `DD:HH:MM:SS` countdown. BACK closes it.

After release it shows `OUT NOW` and the day number since launch.

The glance needs Connect IQ 4.0 or newer (Forerunner 965, fēnix 7, Venu 2 and
newer). On older watches the app is only in the apps list.

## Build

```bash
./build.sh              # bin/GTA6App-fr965.prg for Forerunner 965
./build.sh fenix7       # .prg for another device
./build.sh products     # refresh the device list in manifest.xml
./build.sh export       # bin/GTA6App.iq for every device
```

## Sideload

Copy `bin/GTA6App-fr965.prg` to `GARMIN/Apps` on the watch and unplug it. If
the glance is missing, open the glance list and choose Edit → Add.

## Release date

`RELEASE_YEAR`, `RELEASE_MONTH` and `RELEASE_DAY` in `source/Countdown.mc`.

## Logo

The GTA VI logo is a trademark of Take-Two Interactive Software, Inc. It is not
covered by the MIT license.
