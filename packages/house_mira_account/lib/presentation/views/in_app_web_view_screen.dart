import 'dart:async';

import 'package:flutter/material.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/observability/app_logger.dart';
import 'package:house_mira_core/theme/sand_palette.dart';
import 'package:house_mira_core/widgets/sand/sand_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app web viewer opened for first-party pages (Support, Privacy Policy).
///
/// Loads [url] in a WebView so users read web content without leaving the
/// app. Every web link tapped inside stays in the same WebView; only
/// non-web schemes (`mailto:`, `tel:`) open externally. Both [url] and
/// [title] are required — call sites pass the page's URL and its localized
/// header title.
class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({
    required this.url,
    required this.title,
    super.key,
    this.logger,
    this.launchExternal,
  });

  final String url;
  final String title;

  /// Observability sink for external-link failures. Falls back to a local
  /// [AppLogger] when absent so widget tests can build
  /// [InAppWebViewScreen] directly without DI.
  final AppLogger? logger;

  /// Override for opening non-web links (`mailto:`, `tel:`) in tests.
  /// Defaults to [launchUrl] with [LaunchMode.externalApplication].
  final Future<bool> Function(Uri uri)? launchExternal;

  @override
  State<InAppWebViewScreen> createState() => InAppWebViewScreenState();
}

/// Whether [uri] is a usable web-viewer URL: https with a non-empty host.
///
/// Used by [InAppWebViewScreen] before creating the WebView and on retry so
/// an invalid URL shows the localized error instead of a blank page.
@visibleForTesting
bool isValidWebViewUri(Uri? uri) =>
    uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;

/// Whether [uri] renders inside the in-app WebView.
///
/// Every web link (http/https, any host) stays in the WebView so users
/// never leave the app for another browser. Only non-web schemes
/// (`mailto:`, `tel:`, …) open externally — the WebView cannot render them.
@visibleForTesting
bool staysInWebView(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

class InAppWebViewScreenState extends State<InAppWebViewScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (!isValidWebViewUri(uri)) {
      _hasError = true;
      return;
    }
    final controller = WebViewController();
    _controller = controller;
    unawaited(_init(controller, uri!));
  }

  Future<void> _init(WebViewController controller, Uri uri) async {
    try {
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
            if (target != null && staysInWebView(target)) {
              return NavigationDecision.navigate;
            }
            if (target != null) {
              // Web links stay in the WebView above; only non-web schemes
              // (mailto:, tel:) open externally — the WebView cannot render
              // them. Failures surface the localized error SnackBar via
              // [_openExternal].
              unawaited(_openExternal(target));
            } else {
              _showExternalLinkError();
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
    } on Object catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  /// Opens [target] externally; exposed for widget tests so the
  /// external-link failure path can be exercised without a WebView.
  @visibleForTesting
  Future<void> openExternal(Uri target) => _openExternal(target);

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
        _showExternalLinkError();
      }
    } on Object catch (error, stackTrace) {
      (widget.logger ?? AppLogger()).warning(
        'support external link failed',
        tag: 'support',
        error: error,
        stackTrace: stackTrace,
      );
      _showExternalLinkError();
    }
  }

  void _showExternalLinkError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.supportExternalLinkError),
      ),
    );
  }

  Future<void> _retry() async {
    final uri = Uri.tryParse(widget.url);
    if (!isValidWebViewUri(uri)) return;
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
            SandHeader(title: widget.title),
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
