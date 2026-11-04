# My AI Computer (iPhone)

Native SwiftUI app, round 1: all six screens with sample data.

- `AIComputer/Sources/` – the app code
- `project.yml` – project definition (XcodeGen builds the Xcode project from it)
- `.github/workflows/ios.yml` – GitHub Actions: builds + screenshots on every push, TestFlight upload when run by hand

Bundle ID: `com.matheesha.aicomputer` (change it in `project.yml` and in the workflow's `simctl launch` lines if you register a different one).

GitHub secrets needed for TestFlight: `TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.
