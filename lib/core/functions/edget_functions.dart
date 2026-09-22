import 'dart:async';

import 'package:house_mira/core/router/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgetFunctions {
  /// Creates the edge-functions client.
  ///
  /// When [supabaseClient] is omitted, `Supabase.instance.client` is used.
  /// Tests should pass a mock client.
  EdgetFunctions({SupabaseClient? supabaseClient})
    : _client = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _client;

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
    final res = await _client.functions.invoke(
      'resend-email-v1',
      body: {
        'to': to,
        'subject': subject,
        'html': _inviteHtml(inviteCode, familyName),
      },
    );
    final data = res.data;

    return data is Map && data['success'] == true;
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
