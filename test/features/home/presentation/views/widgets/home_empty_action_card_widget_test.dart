import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_action_card_widget.dart';

void main() {
  group('HomeEmptyActionCardWidget', () {
    const icon = Icons.group_rounded;
    const title = 'Test Title';
    const subtitle = 'Test subtitle description.';
    const buttonLabel = 'Go';

    testWidgets('renders icon, title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyActionCardWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
              buttonLabel: buttonLabel,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text(subtitle), findsOneWidget);
    });

    testWidgets('renders button with correct label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyActionCardWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
              buttonLabel: buttonLabel,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, buttonLabel), findsOneWidget);
    });

    testWidgets('fires onPressed when button is tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyActionCardWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
              buttonLabel: buttonLabel,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, buttonLabel));
      expect(pressed, isTrue);
    });

    testWidgets('renders different content for different props',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyActionCardWidget(
              icon: Icons.star_rounded,
              title: 'Another Title',
              subtitle: 'Another subtitle.',
              buttonLabel: 'Submit',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Another Title'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Test Title'), findsNothing);
    });
  });
}
