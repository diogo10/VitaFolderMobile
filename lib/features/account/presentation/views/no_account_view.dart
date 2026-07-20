import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_no_account_auth_widget.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_no_account_footer_widget.dart';
import 'package:vita_folder_mobile/features/account/presentation/views/account_no_account_header_widget.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

class NoAccountView extends StatelessWidget {
  const NoAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AccountNoAccountHeaderWidget(),
              SizedBox(height: 28),
              AccountNoAccountAuthWidget(),
              SizedBox(height: 28),
              AccountNoAccountFooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
