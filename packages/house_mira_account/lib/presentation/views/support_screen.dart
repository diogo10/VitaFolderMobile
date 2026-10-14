import 'dart:async';

import 'package:flutter/material.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/router/app_routes.dart';
import 'package:house_mira_core/theme/sand_palette.dart';
import 'package:house_mira_core/widgets/sand/sand_header.dart';
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

class _SupportScreenState extends State<SupportScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final controller = WebViewController();
    unawaited(controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(
      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        ),
      ),
    );
    unawaited(controller.loadRequest(Uri.parse(widget.url)));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: SandPalette.sand50,
      body: SafeArea(
        child: Column(
          children: [
            SandHeader(title: l.accountSettingsSupport),
            if (_progress < 100) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
