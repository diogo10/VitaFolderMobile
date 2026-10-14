import 'dart:async';

import 'package:flutter/material.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/router/app_routes.dart';
import 'package:house_mira_core/theme/sand_palette.dart';
import 'package:house_mira_core/widgets/sand/sand_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app support center opened from the settings "Support" item.
///
/// Loads [AppRoutes.supportUrl] in a WebView so users read support content
/// without leaving the app. The [url] parameter exists for tests; production
/// always uses the default.
class SupportScreen extends StatefulWidget {
  const SupportScreen({
    super.key,
    this.url = AppRoutes.supportUrl,
    this.logger,
    this.launchExternal,
  });

  final String url;

  /// Observability sink for external-link failures. Falls back to a local
  /// [AppLogger] when absent so widget tests can build [SupportScreen]
  /// directly without DI.
  final AppLogger? logger;

  /// Override for opening external links in tests. Defaults to [launchUrl]
  /// with [LaunchMode.externalApplication].
  final Future<bool> Function(Uri uri)? launchExternal;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

/// First-party support location; only this host/path stays in the WebView.
final Uri _supportBase = Uri.parse(AppRoutes.supportUrl);

/// Whether [uri] is a usable support URL: https with a non-empty host.
///
/// Used by [SupportScreen] before creating the WebView and on retry so an
/// invalid URL shows the localized error instead of a blank page.
@visibleForTesting
bool isValidSupportUri(Uri? uri) =>
    uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;

bool _isValidSupportUri(Uri? uri) => isValidSupportUri(uri);

/// Whether [uri] stays inside the first-party support section.
///
/// Exact host match plus exact path or `$basePath/` prefix, so subdomains,
/// `support-evil` prefixes, and other hosts open externally.
@visibleForTesting
bool isInSupport(Uri uri) {
  if (uri.host != _supportBase.host) return false;
  final basePath = _supportBase.path;
  return uri.path == basePath || uri.path.startsWith('$basePath/');
}

class _SupportScreenState extends State<SupportScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (!_isValidSupportUri(uri)) {
      _hasError = true;
      return;
    }
    final controller = WebViewController();
    _controller = controller;
    unawaited(_init(controller, uri!));
  }

  Future<void> _init(WebViewController controller, Uri uri) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (!mounted) return;
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
        onNavigationRequest: (request) {
          final target = Uri.tryParse(request.url);
          if (target != null && isInSupport(target)) {
            return NavigationDecision.navigate;
          }
          if (target != null &&
              (target.isScheme('http') || target.isScheme('https'))) {
            unawaited(_openExternal(target));
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (error) {
          // Subresource failures (images, analytics) must not replace the
          // page with the error UI. `isForMainFrame` is nullable on some
          // platforms, so only an explicit false is ignored.
          if (error.isForMainFrame == false) return;
          if (!mounted) return;
          setState(() => _hasError = true);
        },
      ),
    );
    if (!mounted) return;
    await controller.loadRequest(uri);
  }

  Future<void> _openExternal(Uri target) async {
    final launcher =
        widget.launchExternal ??
        (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    try {
      final launched = await launcher(target);
      if (!launched && mounted) {
        (widget.logger ?? AppLogger()).warning(
          'support external link failed',
          tag: 'support',
          context: {'host': target.host},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.supportExternalLinkError,
            ),
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      (widget.logger ?? AppLogger()).warning(
        'support external link failed',
        tag: 'support',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.supportExternalLinkError,
            ),
          ),
        );
      }
    }
  }

  Future<void> _retry() async {
    final uri = Uri.tryParse(widget.url);
    if (!_isValidSupportUri(uri)) return;
    final controller = _controller;
    if (controller == null) return;
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    await controller.loadRequest(uri!);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final controller = _controller;
    return Scaffold(
      backgroundColor: SandPalette.sand50,
      body: SafeArea(
        child: Column(
          children: [
            SandHeader(title: l.accountSettingsSupport),
            if (!_hasError && _progress < 100)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _hasError || controller == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l.supportLoadError,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.tonalIcon(
                              onPressed: () => unawaited(_retry()),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l.supportRetry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : WebViewWidget(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}
