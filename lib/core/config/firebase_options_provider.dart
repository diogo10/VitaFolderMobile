import 'package:firebase_core/firebase_core.dart';
import 'package:house_mira/core/config/app_flavor.dart';
import 'package:house_mira/firebase_options.dart';

/// Returns the Firebase options for [flavor].
///
/// There is currently a single Firebase project, so every flavor resolves
/// to [DefaultFirebaseOptions.currentPlatform]. This function is the seam
/// for per-flavor Firebase apps: once separate `dev`/`staging`/`prod`
/// Firebase projects are provisioned, generate one options file per
/// project (`flutterfire configure --out=lib/firebase_options_<flavor>.dart`)
/// and switch on [flavor] here (plus per-flavor `google-services.json` /
/// `GoogleService-Info.plist` natively). See README "Environments & secrets".
FirebaseOptions firebaseOptionsFor(AppFlavor flavor) {
  switch (flavor) {
    case AppFlavor.dev:
      return DefaultFirebaseOptions.currentPlatform;
    case AppFlavor.staging:
      return DefaultFirebaseOptions.currentPlatform;
    case AppFlavor.prod:
      return DefaultFirebaseOptions.currentPlatform;
  }
}
