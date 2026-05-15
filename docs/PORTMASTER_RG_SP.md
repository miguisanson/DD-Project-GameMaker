# PortMaster / Anbernic RG SP Export Notes

This project renders gameplay at a fixed internal resolution:

- Internal camera/application surface: `160x144`
- RG SP display: `640x480`
- Pixel-perfect fullscreen scale on RG SP: `3x`
- Final viewport on RG SP: `480x432`, centered with `80px` side bars and `24px` top/bottom bars

Do not stretch this game to `640x480`. A stretched fit would need about `3.33x`, which is fractional and will distort the 160x144 camera.

## GameMaker Export

Recommended export for PortMaster GameMaker ports:

1. In GameMaker, select the Android target.
2. Build as VM/bytecode, not YYC.
3. Create the APK.
4. Rename the APK to `donor.apk`.
5. Place it in the game folder used by your PortMaster launch script, for example:

```text
/mnt/mmc/ports/nohope/donor.apk
```

Avoid using a normal Linux export directly on the RG SP. GameMaker Linux exports are usually desktop Linux builds and are not native ARM handheld builds.

## PortMaster Runtime Error

The message in the photo:

```text
This port requires the GMToolkit runtime.
This port requires the Dotnet runtime.
```

means the PortMaster launch/patch script cannot find shared runtimes. It is not caused by the game display code.

On the device, open PortMaster and install:

- `GMToolkit`
- `DotNet`

If the device is offline, install runtimes with PortMaster's autoinstall/runtime package flow, then run PortMaster once so it can unpack them.

Common offline autoinstall folders:

```text
muOS:      /ports/autoinstall
Knulli:    /userdata/roms/ports/autoinstall
ArkOS:     /roms/ports/autoinstall
ROCKNIX:   /roms/ports/autoinstall
AmberELEC: /roms/ports/autoinstall
```

For individual `.squashfs` runtime files, common libs folders are:

```text
muOS:      /MUOS/PortMaster/libs
Knulli:    /userdata/system/.local/share/PortMaster/libs
ArkOS:     /roms/tools/PortMaster/libs
ROCKNIX:   /roms/ports/PortMaster/libs
AmberELEC: /roms/ports/PortMaster/libs
```

## Launch Script Settings

Add these exports before the runner starts:

```sh
export NOHOPE_PORTMASTER=1
export NOHOPE_DISPLAY_SCALE=3
```

`NOHOPE_PORTMASTER=1` makes new/old settings boot fullscreen on the handheld once. `NOHOPE_DISPLAY_SCALE=3` sets the intended RG SP startup scale; the in-game setting can still be changed later.

For a gmloader-style script, the important part looks like this:

```sh
export NOHOPE_PORTMASTER=1
export NOHOPE_DISPLAY_SCALE=3
export GMLOADER_SAVEDIR="$GAMEDIR/gamedata/"
export GMLOADER_PLATFORM="os_linux"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$GPTOKEYB "gmloader" -c ./controls.gptk &
pm_platform_helper "gmloader"
./gmloader donor.apk
```

If your current script already launches the game successfully after patching, do not replace the whole script. Just add the two `NOHOPE_*` exports before the final runner command.

The display code now forces fullscreen layout to an integer-scaled centered viewport, so the RG SP result should be:

```text
window:   640x480
viewport: 480x432 @ 80,24
camera:   160x144
scale:    3x
```

If a previous settings file keeps launching windowed, either switch `Settings > Fullscreen` back on in-game, or delete the old `settings_config.json` from the port save/config folder and launch again.

## Minimal Port Layout

Most firmware expects the script and game folder next to each other in the ports directory:

```text
ports/
  No Hope.sh
  nohope/
    donor.apk
    controls.gptk
    gamedata/
    conf/
```

Your exact path may be `/mnt/mmc/ports`, `/roms/ports`, or another firmware-specific mount. The screenshot shows this device resolving the game folder as:

```text
/mnt/mmc/ports/nohope
```

## Display Rules For This Game

- Keep the camera at `160x144`.
- Keep `application_surface` at `160x144`.
- Use integer viewport scales only.
- On RG SP, use `3x`; do not use fractional full-height scaling.
- Let black bars exist. They are the correct result for a 10:9 game on a 4:3 screen.
