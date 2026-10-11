# Moonlight XR on the Steam Frame

[Moonlight XR](https://github.com/Gilleece/moonlight-android-xr) streams games from a PC running Sunshine or Apollo to a headset, as a large screen with an optional 3D depth effect. It is an Android app. Valve's Steam Frame runs Android apps through **Lepton**, Valve's Android compatibility layer, with SteamVR as the OpenXR runtime. The stock APK does not work there. This fork patches it so it does. Use the `steam-frame` branch.

Tested on a Steam Frame with SteamOS and Lepton 2.8.x, streaming from Sunshine over Wi-Fi, in October 2026. This project is not affiliated with Valve or the Moonlight projects.

## Native client

There is now a native Steam Frame client: **Moonlight XR for Frame**, at <https://github.com/simplysanatori/moonlight-xr-native>. It runs on the Frame directly, without Lepton. The repository will be public soon; until then the link returns a 404. The upstream pull request for this fork was closed for that reason. This fork stays published for people who already use it.

## Status

Confirmed on a Steam Frame, in the headset:

- Pairing, the PC list and game selection in Moonlight's 2D window.
- Streaming in VR, with the 3D depth effect.
- The room environments (Home Theater, Grand Cinema, Synthwave) and the void, with their brightness and glow settings.
- Resizing the picture by its corners.
- The pointer, the bar below the screen and its panels.
- The Steam Frame controllers in gamepad mode, mapped to an Xbox layout (see Controls), and the "Flip face buttons" setting.
- Passthrough, from [sune-ku's change](https://github.com/simplysanatori/moonlight-android-xr-steam-frame/pull/1). It is in the branch after v0.3. The v0.3 APK does not have it. Build from the branch, or use a later release if there is one.

Not tested: hand tracking, look to point, HDR.

## Requirements

- A Steam Frame running SteamOS, with SteamVR.
- Lepton, installed from Steam (Library > Tools).
- Sunshine or Apollo on the PC you stream from.
- A terminal on the Frame: Konsole in desktop mode, or SSH. The scripts use `bash`, `python3` and `curl`, which SteamOS has.
- Steam running while you install. The installer adds the library entry through Steam's local debugging port, which SteamOS enables by default.

## Install

1. Download `MoonlightXR-steam-frame-<version>.apk` from the [Releases page](https://github.com/simplysanatori/moonlight-android-xr-steam-frame/releases), or build it (see Building).
2. On the Frame, in a terminal:

   ```sh
   git clone https://github.com/simplysanatori/moonlight-android-xr-steam-frame.git
   cd moonlight-android-xr-steam-frame
   steam-frame/install.sh ~/Downloads/MoonlightXR-steam-frame-<version>.apk
   ```

   Use the file name you downloaded. The installer copies the APK and the launch wrapper to `~/Games/MoonlightXR/`. It adds a **Moonlight XR** entry to your Steam library and sets its compatibility tool to Lepton. It prints the entry's appid, which names the Lepton log.

To update, run `steam-frame/install.sh` again with the new APK. It updates the existing library entry.

## First run and pairing

1. Start SteamVR, put the headset on and launch **Moonlight XR** from the library.
2. The first launch takes about half a minute while Lepton installs the APK. Android's home screen shows for a few seconds. The launch wrapper then disables that home screen inside Lepton, so later launches go straight to Moonlight.
3. Moonlight's 2D window appears as a flat panel in SteamVR. Your PC should show up in the list. If it does not, add it by IP address with the + button.
4. Select the PC. Moonlight shows a PIN. Enter it in the Sunshine or Apollo web UI on the PC.
5. Pick a game. The stream opens in VR.

Optional extras:

- **Skip the PC list.** Set `PC_UUID` in `~/Games/MoonlightXR/autostart.conf` to open that PC's game list on launch. The file explains where to find the UUID. Add `APP_ID` or `APP_NAME` to start a game's stream straight away. The same values can be set per library entry in Steam's launch options, as `MOONLIGHT_XR_PC_UUID`, `MOONLIGHT_XR_APP_ID` and `MOONLIGHT_XR_APP_NAME` before the wrapper path.
- **Reuse an existing pairing.** If Moonlight's desktop app (flatpak) on the Frame is already paired with your PC, `steam-frame/seed-from-moonlight-qt.sh` copies that pairing into Moonlight XR. It is applied the first time a Moonlight XR library entry launches. It needs `openssl`.

## Controls

Every stream starts in pointer mode. Switch to gamepad mode with the gamepad button on the bar below the screen, or from the Display tab of the settings panel. After that, the gamepad mode shortcut switches between the two modes.

The default shortcut on the Frame is the left **View** button held with the left grip for half a second. The "Gamepad mode shortcut" setting also offers both thumbstick clicks, or both triggers with both grips.

### Gamepad mode

The two controllers act as one Xbox controller on the PC.

| Steam Frame | Xbox controller |
|---|---|
| Right A, B, X, Y | A, B, X, Y |
| Right Menu | Start |
| Left View | Back |
| Left d-pad | D-pad |
| Left and right bumpers | LB, RB |
| Left and right grips | LB, RB |
| Triggers | LT, RT |
| Thumbsticks | Left and right sticks |
| Thumbstick clicks | L3, R3 |

With the default shortcut, View held together with the left grip switches modes and sends no Back press.

Steam Input and SteamVR's controller bindings do not change this layout. The app reads the controllers through OpenXR and builds the gamepad itself. To swap A with B and X with Y, use the app's "Flip face buttons" setting (Settings > Gamepad Settings).

### Pointer mode

| Steam Frame | Action |
|---|---|
| Trigger | Click |
| Right A, or left d-pad down | Right click |
| Right B, or left d-pad right | Middle click |
| Thumbstick | Scroll |
| Thumbstick click | Pointer on or off |
| Grip | Move the screen |

The other buttons do nothing in pointer mode.

## Settings worth changing

The Frame decodes the video in software on its CPU. The 3D depth model also runs on the CPU, because its GPU path fails under Lepton. These settings keep the stream smooth:

- **Video bitrate: about 40 Mbps or less at 1440p.** At 100 Mbps the decoder falls behind. The app then requests a keyframe about every half second and the picture hitches.
- **Video resolution: 1440p or 1080p.** 1080p takes about half the decode time of 1440p.
- **3D: the Comfort or Balanced preset, or off.** The depth map runs a few hundred milliseconds behind the picture, so moving objects smear in 3D. Turn 3D off for fast games.
- **Depth updates per second: 20 (the default) or lower.** The CPU produces about 5 to 8 depth maps a second.
- **Codec:** the app uses H.264 on the Frame. It finds no usable HEVC or AV1 decoder under Lepton.

Change these in Moonlight's 2D window before a stream, or from the cog on the bar below the screen during one.

## Known limits

- **16 swapchains per session.** SteamVR allows an app 16. To fit a room under that limit, the fork leaves out the loading splash, pop-up notices, the bug report sheet, the Ko-fi sheet, the clock, the hand tracking hint and the picture glow.
- **Passthrough needs the last free swapchain.** If something else takes it first, passthrough stays opaque until the stream is restarted.
- **Software decoding.** The picture is more sensitive to bitrate and resolution than on a Quest or Pico.
- **The home screen comes back sometimes.** Lepton discards the app's container data after an APK update, or when a session ends within 30 seconds of starting. The home screen then shows once more on the next launch.
- **90 Hz only.** The runtime offers the app no other refresh rate.

## Troubleshooting

- **The library entry does nothing, or exits at once.** Check that Lepton is installed and that the entry's compatibility tool is Lepton (Properties > Compatibility). Then read the Lepton log (see Logs).
- **The installer says Steam's debugging port is not reachable.** Start Steam and run it again.
- **Only the 2D window shows.** That is the normal start. The VR view opens when a stream starts.
- **The picture hitches on a regular beat.** Lower the bitrate, or use 1080p.
- **Moving things look smeared or doubled.** Use a lower 3D preset, or turn 3D off.
- **Passthrough stays opaque.** Check that your build is newer than v0.3. Turn off "Show the controllers", then restart the stream.
- **A button does the wrong thing.** Steam's controller settings have no effect on this app. See Controls.
- **Pairing fails.** Check that the PC and the Frame are on the same network and that the PC's firewall allows Sunshine or Apollo.

## Logs

- `~/.local/share/Steam/logs/lepton-steamlaunch-<appid>.log`: Lepton's log, including the app's logcat output. Lines starting `moonlight-xr:` and `com.limelight.LimeLog:` come from the app.
- `~/.local/share/Steam/logs/lepton-logcats/`: logcat dumps, written when the app exits early.
- `/tmp/moonlightxr-launch.log`: the launch wrapper.

These logs contain your PC's name and address, your network details and device IDs. `steam-frame/collect-logs.sh` gathers all three into one file under `~/Games/MoonlightXR/logs/`, with those details masked. Read the file before you share it.

## Reporting problems

Open an issue on this repository. Include:

- The release or commit you are using.
- What you did, what you expected and what happened.
- The output of `steam-frame/collect-logs.sh`.
- Your stream settings: resolution, bitrate, frame rate and 3D preset.

Problems that also happen on a Quest or Pico belong to [upstream Moonlight XR](https://github.com/Gilleece/moonlight-android-xr/issues).

## What the fork changes

1. **Headset detection** (`PreferenceConfiguration.isLepton()`): Lepton reports manufacturer `Valve` and model `Lepton`, with no VR system feature, so the app took its flat 2D path. Lepton now counts as a headset, so streams use the OpenXR activity.
2. **Software video decoding** (`MediaCodecHelper`): Lepton's Android image has only the AOSP software decoders (`OMX.google.*`). Moonlight refuses those by default. They are allowed on Lepton.
3. **No crash on decoder setup** (`MediaCodecHelper`): the app first asks each decoder for Android's low latency mode. The AOSP software decoder rejects that, and the failed configure then crashes the process in `ACodec::LoadedState::onShutdown`. The low latency key is no longer offered to AOSP software decoders.
4. **Steam Frame controllers** (`xr_input.c`, `xr_gamepad.*`, `xr_shared.h`): bound through `XR_VALVE_frame_controller_interaction` and `/interaction_profiles/valve/frame_controller`. Without this, SteamVR presents them as Touch controllers. Gamepad mode gains the d-pad and Back.
5. **Face button swap** (`ControllerHandler.reportXrPad`): the "Flip face buttons" setting applies to the VR gamepad.
6. **No Android bars** (`UiHelper`): on Lepton the 2D activities hide the status and navigation bars.
7. **Decoder first** (`XrRenderer`): on Lepton the depth model's threads run at background priority, so the video decoder gets the CPU first. A late depth map smears the 3D a little. A late video frame causes a hitch and a keyframe request.
8. **Rooms under the swapchain limit** (`xr_session.c`, `xr_assets.c`): the app made 16 swapchains before a room was picked, so the room's swapchain failed and the environments never appeared. On SteamVR the items listed under Known limits are left out.
9. **Passthrough** (`xr_layers.c`, by sune-ku): SteamVR on the Frame shows passthrough only behind a projection layer. In passthrough mode the app submitted only quad layers, so the view stayed opaque. While alpha blending is on, a transparent 16x16 projection layer now goes under everything else. It is tried once per session. If the runtime refuses it, passthrough stays opaque.
10. **Launch wrapper and scripts** (`steam-frame/`): `install.sh` adds the library entry. `moonlightxr-launch.sh` disables the Android home screen, applies a seeded pairing and opens a PC or game from `autostart.conf`. `build.sh` builds on the Frame. `seed-from-moonlight-qt.sh` copies a desktop pairing. `collect-logs.sh` gathers masked logs.

## Building

`steam-frame/build.sh` downloads a self-contained toolchain into `~/.local/opt/android-build` and builds the checked-out branch. The signed APK goes to `steam-frame/release/`. It needs about 3 GB of disk, a network connection and no root. It runs on the Frame itself (arm64) or on an x86_64 Linux PC. A build takes a couple of minutes on the Frame. The signing key is generated on first use in `steam-frame/signing/`. Keep it, so later builds install over earlier ones. `steam-frame/install.sh` with no argument installs the newest build from `steam-frame/release/`.

Google ships no arm64 Linux NDK or `aapt2`, and the newest command line tools include an x86_64-only binary. On arm64 the script uses these instead:

| Part | Source |
|---|---|
| JDK 21 | Temurin, `OpenJDK21U-jdk_aarch64_linux_hotspot` |
| Android command line tools | `commandlinetools-linux-13114758_latest.zip` (release 19.0, pure Java) |
| SDK packages | `platforms;android-37.0`, `build-tools;36.0.0`, `build-tools;37.0.0` via `sdkmanager` |
| NDK | HomuHomu833/android-ndk-custom release r30, `android-ndk-r30-aarch64-linux-gnu.tar.xz`, linked as `$ANDROID_HOME/ndk/30.0.16248370` |
| aapt2 | lzhiyong/android-sdk-tools release 35.0.2, `android-sdk-tools-static-aarch64.zip` |

To build by hand, point `JAVA_HOME` and `ANDROID_HOME` at those, create `keystore.properties` from `keystore.properties.example`, and run:

```sh
git submodule update --init --recursive
./gradlew --no-daemon assembleNonRootRelease \
    -PmoonlightNdkVersion=30.0.16248370 \
    -Pandroid.aapt2FromMavenOverride=/path/to/android-sdk-tools/build-tools/aapt2 \
    -Pandroid.enableResourceOptimizations=false
```

`moonlightNdkVersion` overrides the NDK version in `app/build.gradle`. Resource optimisation must be off with that `aapt2`. Its `optimize` command writes no output, and the APK then has no manifest.

On an x86_64 Linux PC, use the standard Android SDK with NDK `29.0.14206865` and run `./gradlew assembleNonRootRelease`, as in the upstream README. The APK runs on the Frame the same way.

## Runtime notes

- Lepton runs the APK a Steam shortcut points at, when the shortcut's compatibility tool is `lepton`. A file named `lepton-show-flatscreen` next to the APK makes the 2D window visible in SteamVR.
- SteamVR's runtime offers `XR_KHR_opengl_es_enable`, `XR_KHR_android_create_instance` and `XR_VALVE_frame_controller_interaction`. It lacks `XR_KHR_composition_layer_cylinder`, `XR_KHR_composition_layer_color_scale_bias` and `XR_FB_composition_layer_settings`. It allows 16 swapchains per session. It shows passthrough only behind a projection layer.
- The TensorFlow Lite GPU delegate fails under Lepton (no OpenCL, and the GL path lacks an op), so depth runs on the CPU.

## Privacy

The fork's own files were checked before publishing: `STEAM_FRAME.md`, the README banner, `.gitignore`, everything in `steam-frame/`, the fork's commits and the release notes. The search covered personal and account names, host and client names, IPv4 and IPv6 addresses, MAC addresses, Wi-Fi network names, UUIDs and other device IDs, Steam user IDs, email addresses, access tokens, API keys, signing keys and passwords, and certificate material. Nothing personal was found in the current files or the fork's commits. The examples use placeholders (`/home/<you>`, empty `autostart.conf` values).

- `keystore.properties`, `*.keystore`, `steam-frame/signing/` and `steam-frame/release/` are ignored by git.
- The release APKs are signed with a certificate whose subject is `CN=Moonlight XR Frame local build`.
- `steam-frame/collect-logs.sh` masks addresses, IDs, PC names and network names in logs.

To repeat the check on a clone (each command should print 0):

```sh
git remote add upstream https://github.com/Gilleece/moonlight-android-xr.git
git fetch upstream master
R=upstream/master..HEAD
git log -p $R | grep '^+' | grep -v '127\.0\.0\.1' | grep -cE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'
git log -p $R | grep '^+' | grep -ciE '\b([0-9a-f]{2}:){5}[0-9a-f]{2}\b'
git log -p $R | grep '^+' | grep -ciE '\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
git log -p $R | grep '^+' | grep -cE 'gh[pousr]_[A-Za-z0-9]{20}|github_pa[t]_|sk-[A-Za-z0-9]{20}|BEGIN [A-Z ]*PRIVATE KEY'
git log -p $R | grep '^+' | grep -ciE 'storePassword=[^%$ ]|keyPassword=[^%$ ]'
git ls-files | grep -ciE '(^|/)keystore\.properties$|\.jks$|\.keystore$|\.pem$|\.p12$'
```

## AI assistance

The Frame changes, the scripts and this document were written with Anthropic's Claude (Claude Fable 5.1 and Claude Opus 5.5), through Claude Code running on a Steam Frame. The repository owner chose what to attempt, ran each build in the headset and reported the results. sune-ku made the passthrough change the same way on their own Frame. The upstream maintainer has not reviewed this code. Every item under Status was tested in the headset.

## Credits

- Sean Gilleece ([Gilleece](https://github.com/Gilleece)) wrote [Moonlight XR](https://github.com/Gilleece/moonlight-android-xr). Everything that is the app is his work. The upstream request for Steam Frame support is [issue #38](https://github.com/Gilleece/moonlight-android-xr/issues/38).
- Moonlight XR is a fork of [Moonlight for Android](https://github.com/moonlight-stream/moonlight-android) by the [Moonlight project](https://moonlight-stream.org).
- [sune-ku](https://github.com/sune-ku) contributed the passthrough change.
- The Steam Frame port was built by [simplysanatori](https://github.com/simplysanatori).

## Licence

Moonlight XR and Moonlight for Android are licensed under GPL-3.0, and so is this fork. See `LICENSE.txt`.
