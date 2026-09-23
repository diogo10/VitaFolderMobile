import 'dart:async';

import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
import 'package:house_mira/core/router/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgetFunctions {
  /// Creates the edge-functions client.
  ///
  /// When [supabaseClient] is omitted, `Supabase.instance.client` is used.
  /// Tests should pass a mock client.
  EdgetFunctions({
    SupabaseClient? supabaseClient,
    CrashReporter? crashReporter,
    AppLogger? logger,
    PerformanceTracer? tracer,
  }) : _client = supabaseClient ?? Supabase.instance.client,
       _logger = logger ?? AppLogger(crashReporter: crashReporter),
       _tracer = tracer ?? NoOpPerformanceTracer();

  final SupabaseClient _client;
  final AppLogger _logger;
  final PerformanceTracer _tracer;

  /// Sends a family-invite email via the `resend-email-v1` edge function.
  ///
  /// When [inviteCode] is provided, the email embeds the same App Link the
  /// mobile app handles ([AppRoutes.inviteLink],
  /// e.g. `https://vitafolder.app/invite/<code>`) so tapping it on a
  /// device deep-links into the join flow. Without a code the email falls
  /// back to a generic enroll prompt — never a fabricated link.
  Future<bool> sendEmail({
    required String to,
    required String subject,
    String? inviteCode,
    String? familyName,
  }) async {
    // Never log the recipient address: PII stays out of logs and crash
    // reports; only shape flags are recorded.
    final context = <String, Object?>{
      'function': 'resend-email-v1',
      'has_invite_code': inviteCode != null,
    };
    _logger.debug('invoking edge function', tag: 'edge', context: context);
    try {
      final succeeded = await _tracer.trace(
        'edge-invoke-resend-email-v1',
        (trace) async {
          final res = await _client.functions.invoke(
            'resend-email-v1',
            body: {
              'to': to,
              'subject': subject,
              'html': _inviteHtml(inviteCode, familyName),
            },
          );
          final data = res.data;
          final ok = data is Map && data['success'] == true;
          await trace.putAttribute('success', '$ok');
          final dynamic status = res.status;
          if (status is int) {
            await trace.putMetric('status', status);
          }
          return ok;
        },
        attributes: {'function': 'resend-email-v1'},
      );
      _logger.info(
        'edge function completed',
        tag: 'edge',
        context: {...context, 'success': succeeded},
      );
      return succeeded;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'edge function failed',
        tag: 'edge',
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static String _inviteHtml(String? inviteCode, String? familyName) {
    final link = AppRoutes.inviteLink(inviteCode);
    final family = (familyName ?? '').trim();
    final who = family.isEmpty ? 'your family' : family;
    if (link == null) {
      return '''
          <html>
            <body>
              <p>You have been invited to join $who on VitaFolder.</p>
              <p>Open the app and enter your invite code to enroll.</p>
            </body>
          </html>
        ''';
    }
    return '''
          <html>
            <body>
              <p>You have been invited to join $who on VitaFolder.</p>
              <p>Click <a href="$link">here</a> to enroll.</p>
            </body>
          </html>
        ''';
  }
}
