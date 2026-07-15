import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_folder_mobile/features/home/presentation/views/widgets/home_empty_invite_card_widget.dart';

void main() {
  group('HomeEmptyInviteCardWidget', () {
    testWidgets('renders Invite a Parent heading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyInviteCardWidget(onSharePressed: () {}),
          ),
        ),
      );

      expect(find.text('Invite a Parent'), findsOneWidget);
    });

    testWidgets('renders collaboration description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyInviteCardWidget(onSharePressed: () {}),
          ),
        ),
      );

      expect(
        find.text('Collaborate in your family hub'),
        findsOneWidget,
      );
    });

    testWidgets('renders Share button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyInviteCardWidget(onSharePressed: () {}),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Share'), findsOneWidget);
    });

    testWidgets('fires onSharePressed when Share is tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeEmptyInviteCardWidget(
              onSharePressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Share'));
      expect(pressed, isTrue);
    });
  });
}
