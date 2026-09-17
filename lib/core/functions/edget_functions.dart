import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class EdgetFunctions {
  /// Creates the edge-functions client.
  ///
  /// When [supabaseClient] is omitted, `Supabase.instance.client` is used.
  /// Tests should pass a mock client.
  EdgetFunctions({SupabaseClient? supabaseClient})
    : _client = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> sendEmail({required String to, required String subject}) async {
    final res = await _client.functions.invoke(
      'resend-email-v1',
      body: {
        'to': to,
        'subject': subject,
        'html': '''
          <html>
            <body>
              <p>Click <a href="https://google.com">here</a> to enroll.</p>
            </body>
          </html>
        ''',
      },
    );
    final data = res.data;

    return data is Map && data['success'] == true;
  }
}
