import 'dart:async';

import 'package:house_mira/core/observability/app_logger.dart';
import 'package:house_mira/core/observability/crash_reporter.dart';
import 'package:house_mira/core/observability/performance_tracer.dart';
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

  /// Sends the HouseMira family-invite email via the `resend-email-v1`
  /// edge function, which renders the subject and HTML server-side from
  /// [locale] (`en`/`pt`, English fallback) and the invite data.
  ///
  /// When [inviteCode] is provided, the email CTA points at the web join
  /// page with the code appended; without a code it falls back to the
  /// generic join page — never a fabricated link.
  Future<bool> sendEmail({
    required String to,
    required String locale,
    String? inviterName,
    String? familyName,
    String? inviteCode,
  }) async {
    // Never log the recipient address or names: PII stays out of logs and
    // crash reports; only shape flags are recorded.
    final context = <String, Object?>{
      'function': 'resend-email-v1',
      'locale': locale,
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
              'locale': locale,
              'inviterName': ?inviterName,
              'familyName': ?familyName,
              'inviteCode': ?inviteCode,
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
}
