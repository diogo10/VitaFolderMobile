import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/injections/service_locator.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/account_state.dart';
import 'package:house_mira/features/account/presentation/views/account_loaded_widget.dart';
import 'package:house_mira/features/account/presentation/views/no_account_view.dart';
import 'package:house_mira/features/home/presentation/cubit/home_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/people_cubit.dart';
import 'package:house_mira/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:house_mira/generated/app_localizations.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<AccountCubit>().loadAccount());
  }

  // Each tab owns its cubit inside its StatefulShellBranch, so sibling
  // cubits are not in this view's provider scope. Refresh them through the
  // shared GetIt singletons instead; when a tab was never visited there is
  // nothing to refresh (it loads on first visit).
  void _refreshAllTabs() {
    _refreshHomeTab();
    _refreshPeopleTab();
    _refreshRemindersTab();
  }

  void _refreshHomeTab() {
    try {
      unawaited(context.read<HomeCubit>().getHomeData(isRefresh: true));
      return;
    } on Object catch (_) {
      // Not an ancestor provider: fall back to the shared singleton.
    }
    try {
      unawaited(
        slInstance<HomeCubit>(
          instanceName: 'homeCubit',
        ).getHomeData(isRefresh: true),
      );
    } on Object catch (_) {
      // Home tab never visited: it loads on first visit.
    }
  }

  void _refreshPeopleTab() {
    try {
      unawaited(context.read<PeopleCubit>().getPeople(isRefresh: true));
      return;
    } on Object catch (_) {
      // Not an ancestor provider: fall back to the shared singleton.
    }
    try {
      unawaited(
        slInstance<PeopleCubit>(
          instanceName: 'peopleCubit',
        ).getPeople(isRefresh: true),
      );
    } on Object catch (_) {
      // People tab never visited: it loads on first visit.
    }
  }

  void _refreshRemindersTab() {
    try {
      final remindersCubit = context.read<RemindersCubit>();
      unawaited(
        remindersCubit.getReminders(type: remindersCubit.selectedType),
      );
      return;
    } on Object catch (_) {
      // Not an ancestor provider: fall back to the shared singleton.
    }
    try {
      final remindersCubit = slInstance<RemindersCubit>(
        instanceName: 'remindersCubit',
      );
      unawaited(
        remindersCubit.getReminders(type: remindersCubit.selectedType),
      );
    } on Object catch (_) {
      // Reminders tab never visited: it loads on first visit.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountCubit, AccountState>(
      listener: (context, state) {
        final l = AppLocalizations.of(context)!;

        if (state is AccountLogoutSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.accountSignedOut)));

          _refreshAllTabs();
        }

        if (state is AccountDeletedSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.accountDeletedSuccess)));

          _refreshAllTabs();
        }

        if (state is AccountDeleteFailed) {
          final message = switch (state.code) {
            AccountDeleteErrorCode.soleOwner => l.accountDeleteSoleOwner,
            AccountDeleteErrorCode.sendFailed => l.accountDeleteFailed,
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }

        if (state is AccountLoginSuccess) {
          _refreshAllTabs();
        }

        if (state is LoginFailed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.accountLoginFailed)));
        }

        if (state is PasswordResetSent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.accountPasswordResetSent)));
        }

        if (state is PasswordResetError) {
          final message = switch (state.code) {
            PasswordResetErrorCode.emptyEmail =>
              l.accountPasswordResetEnterEmail,
            PasswordResetErrorCode.sendFailed => l.accountPasswordResetFailed,
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state is AccountLoading ||
            state is AccountDeleting ||
            state is AccountDeleteFailed) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NoAccount ||
            state is AccountLogoutSuccess ||
            state is AccountDeletedSuccess ||
            state is LoginFailed ||
            state is PasswordResetSent ||
            state is PasswordResetError) {
          return const NoAccountView();
        }

        if (state is AccountLoaded) {
          return const AccountLoadedWidget();
        }

        return const SizedBox.shrink();
      },
    );
  }
}
