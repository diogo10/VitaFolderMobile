import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira_notes/presentation/utils/note_time_ago.dart';
import 'package:house_mira_core/generated/app_localizations.dart';

void main() {
  Future<String> format(
    WidgetTester tester,
    DateTime date, {
    Locale locale = const Locale('en'),
    DateTime? clock,
  }) async {
    var result = '';
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = formatNoteTimeAgo(context, date, clock: clock);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  group('formatNoteTimeAgo', () {
    final clock = DateTime.utc(2026, 9, 30, 12);

    testWidgets('minutes', (tester) async {
      expect(
        await format(
          tester,
          clock.subtract(const Duration(minutes: 2)),
          clock: clock,
        ),
        '2 min ago',
      );
    });

    testWidgets('hours', (tester) async {
      expect(
        await format(
          tester,
          clock.subtract(const Duration(hours: 3)),
          clock: clock,
        ),
        '3h ago',
      );
    });

    testWidgets('yesterday', (tester) async {
      expect(
        await format(
          tester,
          clock.subtract(const Duration(hours: 30)),
          clock: clock,
        ),
        'Yesterday',
      );
    });

    testWidgets('weekday within a week', (tester) async {
      final date = clock.subtract(const Duration(days: 3));
      final text = await format(tester, date, clock: clock);
      expect(text, isNotEmpty);
      expect(text, isNot(contains('ago')));
    });

    testWidgets('PT locale', (tester) async {
      expect(
        await format(
          tester,
          clock.subtract(const Duration(minutes: 5)),
          clock: clock,
          locale: const Locale('pt'),
        ),
        'há 5 min',
      );
      expect(
        await format(
          tester,
          clock.subtract(const Duration(hours: 30)),
          clock: clock,
          locale: const Locale('pt'),
        ),
        'Ontem',
      );
    });
  });
}
