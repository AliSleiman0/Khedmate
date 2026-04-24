# App icon assets

Drop the following files here (not checked in until final assets arrive):

- `icon.png` — 1024x1024 PNG (square) used as the primary launcher icon on iOS + Android legacy.
- `icon-foreground.png` — 1024x1024 PNG with transparent background, used for Android adaptive icons. Keep the logo within the inner ~66% to respect adaptive-icon safe area.

After adding the files run:

```bash
dart run flutter_launcher_icons
```

The config lives in `mobile/pubspec.yaml` under `flutter_launcher_icons`.
Background color is brand blue (`#1B4F72`).
