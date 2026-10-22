import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the cubits a pushed route owns against emitting into a closed
/// cubit.
///
/// The router hands those cubits to `BlocProvider(create:)`, so leaving the
/// screen closes them while their async flow is still running (the native
/// Google/Apple sheet, a store call, a backend request). `Cubit.emit`
/// throws `StateError: Cannot emit new states after calling close` then,
/// which the app reports as a fatal error and the user sees as a crash
/// (FATAL Crashlytics issue `04df8a6a042f93d2a9590f8d9525e328`).
///
/// Every emit that can run after an `await` therefore goes through the
/// cubit's `_emitIfOpen` helper, which drops the state instead of throwing.
/// This test reads the sources and fails when a direct `emit(` can follow
/// an `await` in one of those cubits.
void main() {
  const routeScopedCubits = '''
packages/house_mira_login/lib/presentation/cubit/sign_up_cubit.dart
packages/house_mira_account/lib/presentation/cubit/manage_profile_cubit.dart
packages/house_mira_account/lib/presentation/cubit/notification_settings_cubit.dart
packages/house_mira_people/lib/presentation/cubit/invite_people_cubit.dart
packages/house_mira_people/lib/presentation/cubit/family_settings_cubit.dart
packages/house_mira_paywall/lib/presentation/cubit/paywall_cubit.dart
packages/house_mira_reminders/lib/presentation/cubit/create_reminder_cubit.dart
''';

  for (final path in routeScopedCubits.trim().split('\n')) {
    group(path, () {
      final source = File(path).readAsStringSync();

      test('guards every emit that can run after an await', () {
        final violations = <String>[];

        for (final method in _asyncMethods(source)) {
          var awaited = false;
          for (final call in _directEmitCalls(method.body)) {
            final before = method.body.substring(0, call.start);
            if (before.contains('await')) awaited = true;
            if (awaited) {
              violations.add(
                '${method.name}: '
                '${method.body.substring(call.start, call.end)}',
              );
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'emit() after an await throws once the route closed the '
              'cubit. Use the _emitIfOpen helper instead:\n'
              '${violations.join('\n')}',
        );
      });

      test('declares the _emitIfOpen guard', () {
        expect(
          source,
          contains('void _emitIfOpen('),
          reason: 'the cubit must guard its emits against a closed cubit',
        );
      });
    });
  }
}

/// An async method of a cubit source with its body.
class _AsyncMethod {
  _AsyncMethod(this.name, this.body);

  final String name;
  final String body;
}

final _methodStart = RegExp(
  r'(?:Future<[^>]*>|Future<void>|void)\s+(\w+)\([^)]*\)\s*(?:async\s*)?\{',
);

/// Every `async` method of [source] with its balanced body.
List<_AsyncMethod> _asyncMethods(String source) {
  final methods = <_AsyncMethod>[];
  for (final match in _methodStart.allMatches(source)) {
    final declaration = source.substring(match.start, match.end);
    if (!declaration.contains('async')) continue;
    final body = _balancedBody(source, match.end - 1);
    if (body != null) methods.add(_AsyncMethod(match.group(1)!, body));
  }
  return methods;
}

/// The source of the block that starts at [openBrace], braces included.
String? _balancedBody(String source, int openBrace) {
  var depth = 0;
  for (var i = openBrace; i < source.length; i++) {
    final char = source[i];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) return source.substring(openBrace, i + 1);
    }
  }
  return null;
}

final _emitCall = RegExp(r'(?<![\w.])emit\(');

/// Every direct `emit(` call in [body].
///
/// The `_emitIfOpen` helper is a different call and is not matched.
List<({int start, int end})> _directEmitCalls(String body) {
  final calls = <({int start, int end})>[];
  for (final match in _emitCall.allMatches(body)) {
    final before = body.substring(0, match.start);
    if (before.endsWith('_emitIfOpen(') || before.endsWith('void ')) continue;
    calls.add((start: match.start, end: match.end + 'emit('.length));
  }
  return calls;
}
