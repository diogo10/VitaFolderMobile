import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/features/account/presentation/cubit/account_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/theme/theme_extensions.dart';

class AccountSettingsWidget extends StatelessWidget {
  final String familyCode;
  final bool isAdmin;
  const AccountSettingsWidget({
    super.key,
    required this.familyCode,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountSettingsSection(
            title: l.accountSettingsAccountSection,
            items: [
              _AccountSettingsItemData(
                icon: Icons.person_rounded,
                title: l.accountSettingsEditProfile,
                subtitle: l.accountSettingsEditProfileSubtitle,
                onTap: () => context.push('/manage-profile'),
              ),
              _AccountSettingsItemData(
                icon: Icons.notifications_rounded,
                title: l.accountSettingsNotifications,
                subtitle: l.accountSettingsNotificationsSubtitle,
                onTap: () => context.push('/notification-settings'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AccountSettingsSection(
            title: l.accountSettingsFamilySection,
            items: [
              if (isAdmin)
                _AccountSettingsItemData(
                  icon: Icons.house_rounded,
                  title: l.accountSettingsFamilySettings,
                  subtitle: l.accountSettingsFamilySettingsSubtitle,
                  onTap: () => context.push('/family-settings'),
                ),
              _AccountSettingsItemData(
                icon: Icons.person_add_alt_1_rounded,
                title: l.accountSettingsInviteMembers,
                subtitle: l.accountSettingsInviteMembersSubtitleWithCode(
                  familyCode,
                  l.accountSettingsInviteMembersSubtitle,
                ),
                onTap: () => context.go('/people'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AccountSettingsSection(
            title: l.accountSettingsSupportSection,
            items: [
              _AccountSettingsItemData(
                icon: Icons.help_outline_rounded,
                title: l.accountSettingsHelpFaq,
                subtitle: l.accountSettingsHelpFaqSubtitle,
              ),
              _AccountSettingsItemData(
                icon: Icons.privacy_tip_rounded,
                title: l.accountSettingsPrivacyPolicy,
                subtitle: l.accountSettingsPrivacyPolicySubtitle,
              ),
              _AccountSettingsItemData(
                icon: Icons.logout_rounded,
                title: l.accountSettingsSignOut,
                subtitle: l.accountSettingsSignOutSubtitle,
                accent: true,
                onTap: () {
                  context.read<AccountCubit>().signOut();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AccountSettingsSection(
            title: l.accountSettingsDangerSection,
            items: [
              _AccountSettingsItemData(
                icon: Icons.delete_forever_rounded,
                title: l.accountSettingsDeleteAccount,
                subtitle: l.accountSettingsDeleteAccountSubtitle,
                accent: true,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.accountDeleteDialogTitle),
        content: Text(l.accountDeleteDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l.accountDeleteDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AccountCubit>().deleteAccount();
    }
  }
}

class _AccountSettingsSection extends StatelessWidget {
  final String title;
  final List<_AccountSettingsItemData> items;

  const _AccountSettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface.withValues(alpha: 0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => _AccountSettingsItem(
                    data: entry.value,
                    isLast: entry.key == items.length - 1,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _AccountSettingsItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;
  final VoidCallback? onTap;

  const _AccountSettingsItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = false,
    this.onTap,
  });
}

class _AccountSettingsItem extends StatelessWidget {
  final _AccountSettingsItemData data;
  final bool isLast;

  const _AccountSettingsItem({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final iconBackground = data.accent
        ? context.colorScheme.error.withValues(alpha: 0.16)
        : context.colorScheme.primary.withValues(alpha: 0.12);
    final iconColor = data.accent
        ? context.colorScheme.error
        : context.colorScheme.primary;
    final titleColor = data.accent
        ? context.colorScheme.error
        : context.colorScheme.onSurface;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: iconColor, size: 22),
          ),
          title: Text(
            data.title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          subtitle: Text(
            data.subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onTap: data.onTap,
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
