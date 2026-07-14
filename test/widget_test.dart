import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/account/presentation/cubit/account_cubit.dart';
import 'package:vita_folder_mobile/features/home/domain/usecase/get_home_data_usecase.dart';
import 'package:vita_folder_mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:vita_folder_mobile/features/reminders/domain/usecase/get_reminder_usecase.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:vita_folder_mobile/main.dart';

Widget _pumpApp() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<HomeCubit>(
        create: (_) => HomeCubit(
          getHomeDataUsecase:
              GetIt.instance<GetHomeDataUsecase>(instanceName: 'getHomeDataUsecase'),
        ),
      ),
      BlocProvider<RemindersCubit>(
        create: (_) => RemindersCubit(
          getReminderUsecase:
              GetIt.instance<GetReminderUsecase>(instanceName: 'getReminderUsecase'),
        ),
      ),
      BlocProvider<AccountCubit>(
        create: (_) => AccountCubit(),
      ),
    ],
    child: const MyApp(),
  );
}

void main() {
  setUpAll(() async {
    final serviceLocator = ServiceLocator();
    await serviceLocator.init();
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('MainView', () {
    testWidgets('displays Home tab by default', (tester) async {
      await tester.pumpWidget(_pumpApp());
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Good morning!'), findsOneWidget);
      expect(find.text('Search Content'), findsNothing);
      expect(find.text('Favorites Content'), findsNothing);
    });

    testWidgets('displays bottom navigation bar with 4 items',
        (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('switches tabs when tapping navigation items',
        (tester) async {
      await tester.pumpWidget(_pumpApp());

      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(find.text('Search Content'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pump();
      expect(find.text('Favorites Content'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pump();
      // AccountView shows loading indicator first, then Account text after delay
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      // Account appears both as nav label and content text
      expect(find.text('Account'), findsAtLeastNWidgets(2));

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('MyApp', () {
    testWidgets('has correct app title', (tester) async {
      await tester.pumpWidget(_pumpApp());

      final title = tester.widget<MaterialApp>(find.byType(MaterialApp)).title;
      expect(title, 'VitaFolder');
    });

    testWidgets('renders MainView as home', (tester) async {
      await tester.pumpWidget(_pumpApp());

      expect(find.byType(MainView), findsOneWidget);
    });
  });
}
