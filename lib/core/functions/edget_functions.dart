import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class EdgetFunctions {

  Future<bool> sendEmail({required String to, required String subject}) async {
    final res = await Supabase.instance.client.functions.invoke(
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

    return data != null && data['success'] == true;
  }
}
