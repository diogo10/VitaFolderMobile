import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/widgets/reminder_widget.dart';

void main() {
  group('ReminderWidget', () {
    const title = 'Test Title';
    const body = 'Test Body Content';

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ReminderWidget(title: title, body: body),
        ),
      );
    }

    testWidgets('renders title and body text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text(title), findsOneWidget);
      expect(find.text(body), findsOneWidget);
    });

    testWidgets('renders title with bold style', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final titleWidget = tester.widget<Text>(find.text(title));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.fontSize, 20);
    });

    testWidgets('renders body with greyish style', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final bodyWidget = tester.widget<Text>(find.text(body));
      expect(bodyWidget.style?.color, Colors.black54);
      expect(bodyWidget.style?.fontSize, 16);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
