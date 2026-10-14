import 'dart:async';

import 'package:flutter/material.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
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
  const SupportScreen({super.key, this.url = AppRoutes.supportUrl});

  final String url;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

/// First-party support location; only this host/path stays in the WebView.
final Uri _supportBase = Uri.parse(AppRoutes.supportUrl);

class _SupportScreenState extends State<SupportScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) {
      _hasError = true;
      return;
    }
    final controller = WebViewController();
    _controller = controller;
    unawaited(_init(controller, uri));
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
          if (target != null && _isInSupport(target)) {
            return NavigationDecision.navigate;
          }
          if (target != null) {
            unawaited(launchUrl(target, mode: LaunchMode.externalApplication));
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (_) {
          if (!mounted) return;
          setState(() => _hasError = true);
        },
      ),
    );
    if (!mounted) return;
    await controller.loadRequest(uri);
  }

  static bool _isInSupport(Uri uri) {
    if (uri.host != _supportBase.host) return false;
    final basePath = _supportBase.path;
    return uri.path == basePath || uri.path.startsWith('$basePath/');
  }

  Future<void> _retry() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) return;
    final controller = _controller;
    if (controller == null) return;
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    await controller.loadRequest(uri);
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
