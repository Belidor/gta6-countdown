# GTA VI Countdown for Garmin

A Connect IQ watch face and a watch app with a glance that count down to the
GTA VI release: 19 November 2026, 00:00 on the watch clock.

Site: https://gta6.belidor.cc/

| Folder | What it is |
|---|---|
| `watchface/` | Watch face: time, logo, countdown, AMOLED always-on mode |
| `app/` | Watch app: a glance for the glance list and a full-screen view with seconds |
| `landing/` | Static landing page, deployed to https://gta6.belidor.cc by `.github/workflows/pages.yml` |
| `promo/` | Images and text for the announcement |
| `store/` | Connect IQ Store screenshots, icon and listing text |

## Build

You need the Connect IQ SDK from the SDK Manager:
https://developer.garmin.com/connect-iq/sdk/

```bash
cd watchface   # or: cd app
./build.sh            # .prg for Forerunner 965
./build.sh fenix7     # .prg for another device
./build.sh products   # refresh the device list from the SDK Manager downloads
./build.sh export     # .iq package for every device in manifest.xml
```

`build.sh` creates a signing key in `keys/` on the first run. Keep a private
backup of it: store updates must be signed with the same key. `keys/` is in
`.gitignore`.

## Sideload

Copy the `.prg` file to `GARMIN/Apps` on the watch (on a Mac, use OpenMTP),
then unplug the watch.

## Release date

The date is in `watchface/source/GTA6CountdownView.mc` and
`app/source/Countdown.mc` (`RELEASE_YEAR`, `RELEASE_MONTH`, `RELEASE_DAY`).

## Legal

Unofficial fan project. Not affiliated with or endorsed by Rockstar Games or
Take-Two Interactive. Grand Theft Auto, GTA VI and the GTA VI logo are
trademarks of Take-Two Interactive Software, Inc. The MIT license covers the
code only; see `LICENSE`.
