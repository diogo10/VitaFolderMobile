# Fonts & notification icons

## Fonts

Fonts ship inside the bundle; nothing is downloaded at runtime.

Families are declared in the app `pubspec.yaml` under `flutter: fonts:` and
the files live in `assets/fonts/`:

| Family | Use | Weights | Files |
| --- | --- | --- | --- |
| Figtree | Theme/body (`AppConstants.fontFamily`) | 400, 500, 600, 700, 800 | `assets/fonts/Figtree-Bold.ttf` and siblings |
| Outfit | Headings and labels | 500, 600, 700, 800 | `assets/fonts/Outfit-Bold.ttf` and siblings |

Both families come from Google Fonts under the SIL Open Font License 1.1
(`assets/fonts/OFL-Figtree.txt`, `assets/fonts/OFL-Outfit.txt`).

Rules:

- **Never reintroduce a runtime font fetch.** `google_fonts` and its
  `allowRuntimeFetching` flag were removed for that reason: the theme used to
  resolve the family over the network and release builds disabled the
  download, which made every release build throw while the first themed text
  was rendered (FATAL Crashlytics issue `e800d234`).
- **Declare every family a `TextStyle` uses.** A family that is not declared
  renders with the platform fallback font instead of the intended one.
- **Keep the file naming and the declared weight in sync.** The name follows
  the Google Fonts convention (family, then weight — for example
  `assets/fonts/Figtree-Bold.ttf` is the 700 face) and the declared `weight`
  must match the weight the binary carries.
- To add a weight or a family: download the file from Google Fonts, drop it
  in `assets/fonts/`, declare it in `pubspec.yaml` under `flutter: fonts:`
  with the matching `weight`, and run the guard below.

Guard: `test/theme/font_bundle_test.dart` reads the font manifest of the
built bundle, parses each bundled font binary, and fails when a declared
family or weight does not match the file, when a family is missing from the
bundle, or when the theme requests an undeclared family.

## Notification icons

Android notification icons are passed to `flutter_local_notifications` as the
**bare drawable resource name** — `ic_notification`, not the qualified
Android form that carries the drawable-type prefix.

The plugin resolves the name with the Android resource lookup for the
drawable type and the app package, which returns 0 for a qualified name.
`initialize()` then fails with `invalid_icon`, the default small icon is
never stored, and the small-icon setter receives 0 — so **no reminder
notification is ever displayed** (NON_FATAL Crashlytics issue `434603cf`).

The drawable itself is
`android/app/src/main/res/drawable/ic_notification.xml`: a white-on-transparent
silhouette. An adaptive-icon mipmap is not a valid small icon and
notifications using one are dropped by the OS at fire time.

Guard: `test/android_manifest_test.dart` reads the icon name from
`packages/house_mira_reminders/lib/application/reminder_notification_service.dart`,
rejects qualified names, and asserts the matching drawable exists in
`android/app/src/main/res/drawable/`.
