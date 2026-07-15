import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_header_widget.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_settings_widget.dart';

class AccountLoadedWidget extends StatelessWidget {
  const AccountLoadedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountHeaderWidget(),
            AccountSettingsWidget(),
          ],
        ),
      ),
    );
  }
}
