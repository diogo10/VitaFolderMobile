import 'package:flutter_test/flutter_test.dart';

import 'package:vita_folder_mobile/main.dart';

void main() {
  testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Home Content'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pump();
    expect(find.text('Search Content'), findsOneWidget);

    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(find.text('Favorites Content'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('Profile Content'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(find.text('Home Content'), findsOneWidget);
  });
}
