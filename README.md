# Sumi

A focused native macOS Markdown editor.

The app intentionally keeps the scope small:

- Native macOS window, toolbar, sidebar, file dialogs, and text editing.
- Typora-style single writing surface with a centered readable column.
- Native macOS window tabs: each open document is its own window, tabbed together
  by the system once 2+ are open.
- Markdown syntax highlighting and common formatting commands, plus an Insert
  menu for links, images, tables, and other common Markdown elements.
- Local `.md` file open/save, with a native Open-or-New chooser at launch.
- No PDF export, no Typst/Rust pipeline, no pagination.

The app has no bundled editing engine dependency. The bundle script copies Swift runtime libraries into `.app/Contents/Frameworks` when Xcode reports they are needed. AppKit and SwiftUI remain macOS system frameworks and are not copied into the app bundle.

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build -c release
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
./scripts/make-app-bundle.sh
open .build/Sumi.app
```

## Release Package

Create a downloadable macOS disk image:

```bash
./scripts/make-release-dmg.sh
```

The generated installer-style package is:

```text
.build/dist/Sumi.dmg
```

Release DMGs contain a universal app binary for both Intel (`x86_64`) and Apple
Silicon (`arm64`) Macs.

The bundle script ad-hoc signs local builds by default so the app bundle is
internally valid. For GitHub Releases that should open normally after download,
configure Apple Developer ID signing and notarization secrets in the repository:

- `APPLE_CODESIGN_IDENTITY`, for example `Developer ID Application: Example, Inc. (TEAMID)`
- `APPLE_DEVELOPER_ID_CERTIFICATE_BASE64`
- `APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`
- `KEYCHAIN_PASSWORD`

GitHub Releases are created automatically when a `v*` tag is pushed, for example:

```bash
git tag v0.1.0
git push origin main --tags
```

Without Developer ID notarization, macOS may still show the standard warning for
apps downloaded from the internet even though the bundle is ad-hoc signed.

## Acknowledgement

Thank Claude Code and codex for their greatful help.
