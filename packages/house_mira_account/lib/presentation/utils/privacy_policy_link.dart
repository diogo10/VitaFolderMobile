import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy page opened from Settings.
///
/// [Uri] has no const constructor, so this stays a final parsed from a
/// string literal.
final Uri privacyPolicyUri = Uri.parse('https://housemira.com/privacy');

/// Launches [uri] in an in-app web view. Injectable for widget tests.
typedef PrivacyPolicyLauncher = Future<void> Function(Uri uri);

/// Default launcher used in production.
///
/// Throws a [StateError] when the platform refuses to open [uri] so call
/// sites can surface the failure instead of failing silently.
Future<void> defaultPrivacyPolicyLauncher(Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
  if (!launched) {
    throw StateError('Could not launch $uri');
  }
}
