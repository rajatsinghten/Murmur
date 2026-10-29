# Murmur

On-device voice typing for macOS. Hold a global shortcut, speak, and the transcription is inserted into the frontmost app.

- **Push-to-talk** — hold the shortcut while you speak, release to insert the text.
- **On-device** — uses `SFSpeechRecognizer` with `requiresOnDeviceRecognition`; audio never leaves your Mac.
- **Menu bar app** — no Dock icon, with Start/Stop, a shortcut recorder, and an option to hide the menu bar icon.
- **Clipboard-safe** — pastes into the current app and then restores whatever was on your clipboard.

## Requirements

- macOS 14 Sonoma or newer
- Apple Silicon
- Xcode Command Line Tools

## Build

```sh
./build.sh          # release build into build/Murmur.app
./build.sh debug    # debug build
./package.sh        # build and create build/Murmur.dmg (unsigned)
```

`Murmur.png` is converted into the app's `.icns` icon automatically.

## Run

```sh
open build/Murmur.app
```

## Usage

- Default shortcut: **⌃⌥⌘R** (hold to record, release to finish).
- Click the waveform icon in the menu bar for **Start Dictation**, **Stop Dictation**, **Change Shortcut…**, **Show in Menu Bar**, and **Quit Murmur**.
- If you hide the menu bar icon, reopen the app to bring it back:

```sh
open build/Murmur.app
```

## Permissions

On first use Murmur asks for **Microphone** and **Speech Recognition**. To paste the finished text into the frontmost app it also needs **Accessibility** (System Settings → Privacy & Security → Accessibility).

## License

[MIT](LICENSE) © 2026 Rajat Kumar Singh.
