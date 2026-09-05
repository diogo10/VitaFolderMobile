import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:house_mira/core/widgets/sand/sand_header.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_cubit.dart';
import 'package:house_mira/features/account/presentation/cubit/notification_settings_state.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';
import 'package:house_mira/theme/theme_extensions.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationSettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: SandPalette.sand50,
      body: SafeArea(
        child: Column(
          children: [
            SandHeader(title: l.notificationSettingsTitle),
            Expanded(
              child:
                  BlocConsumer<
                    NotificationSettingsCubit,
                    NotificationSettingsState
                  >(
                    listener: (context, state) {
                      if (state is NotificationSettingsLoaded &&
                          state.permissionDenied != null) {
                        final message =
                            state.permissionDenied ==
                                NotificationPermissionDenied.permanentlyDenied
                            ? l.notificationSettingsPermissionPermanentlyDenied
                            : l.notificationSettingsPermissionDenied;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                    builder: (context, state) {
                      if (state is NotificationSettingsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is NotificationSettingsError) {
                        return Center(child: Text(l.notificationSettingsError));
                      }

                      final loaded = state as NotificationSettingsLoaded;
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            l.notificationSettingsSection,
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
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
                                  color: context.colorScheme.shadow.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  secondary: _SettingsIcon(
                                    icon: Icons.notifications_active_rounded,
                                    color: context.colorScheme.primary,
                                  ),
                                  title: Text(
                                    l.notificationSettingsEnableNotifications,
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    l.notificationSettingsEnableNotificationsSubtitle,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                  value: loaded.notificationsEnabled,
                                  onChanged: (value) => context
                                      .read<NotificationSettingsCubit>()
                                      .setNotificationsEnabled(value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
