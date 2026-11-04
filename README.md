# My AI Computer (iPhone)

Native SwiftUI app, round 1: all six screens with sample data.

- `AIComputer/Sources/` – the app code
- `project.yml` – project definition (XcodeGen builds the Xcode project from it)
- `.github/workflows/ios.yml` – GitHub Actions: builds + screenshots on every push, TestFlight upload when run by hand

Bundle ID: `com.matheesha.aicomputer` (change it in `project.yml` and in the workflow's `simctl launch` lines if you register a different one).

GitHub secrets needed for TestFlight: `TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.

## AI Assistant → Claude Code on your PC (bridge)

The assistant answers through Claude Code on your PC, so it uses your Claude subscription.

1. Install Tailscale on the PC and the iPhone and sign in to the same account on both.
2. On the PC run `bridge/start-bridge.cmd`. The first run creates `bridge/.token`, the secret the phone needs (it is gitignored).
3. In the app go to **Settings → Claude Code Bridge**: enter the PC's Tailscale IP (`tailscale ip -4`) and the token, then tap **Save & Test**.

The bridge listens only on the Tailscale address and rejects requests without the token. To start it at login, put a shortcut to `start-bridge.cmd` in `shell:startup`.

## On-device Linux (in progress)

The terminal is moving to a real Alpine Linux shell that runs on the phone, using
[iSH-ARM64](https://github.com/OpenMinis/ish-arm64) (pinned as the `deps/ish` submodule).
The build scripts in `deps/` are adapted from [OpenMinis](https://github.com/OpenMinis/OpenMinis).
`.github/workflows/ish.yml` builds the engine libraries and the root filesystem.

## Licence

GPL-3.0 (see `LICENSE`), because the app includes iSH, which is GPL-licensed.
