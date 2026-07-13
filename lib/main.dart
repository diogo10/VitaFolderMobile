import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vita_folder_mobile/app.dart';
import 'package:vita_folder_mobile/core/injections/service_locator.dart';
import 'package:vita_folder_mobile/features/posts/presentation/cubit/posts_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => slInstance<PostsCubit>(instanceName: 'postsCubit'),
        ),
      ],
      child: const App(),
    ),
  );
}
