import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_mira/features/home/presentation/views/widgets/home_empty_header_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';

Widget _pumpApp() {
  return const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: HomeEmptyHeaderWidget()),
  );
}

void main() {
  group('HomeEmptyHeaderWidget', () {
    testWidgets('renders welcome heading', (tester) async {
      await tester.pumpWidget(_pumpApp());
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeEmptyHeaderWidget)),
      )!;

      expect(find.text(l.homeEmptyHeaderTitle), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(_pumpApp());
      final l = AppLocalizations.of(
        tester.element(find.byType(HomeEmptyHeaderWidget)),
      )!;

      expect(find.text(l.homeEmptyHeaderDescription), findsOneWidget);
    });
  });
}
