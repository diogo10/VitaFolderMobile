import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/reminders/presentation/screens/reminders_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vita Folder Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const RemindersView(),
    );
  }
}
