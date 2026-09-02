import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/generated/app_localizations.dart';

class PeopleEmptyWidget extends StatefulWidget {
  final VoidCallback? onCreateFamilyPressed;
  final ValueChanged<String>? onJoinFamilyPressed;
  final RefreshCallback? onRefresh;

  const PeopleEmptyWidget({
    super.key,
    this.onCreateFamilyPressed,
    this.onJoinFamilyPressed,
    this.onRefresh,
  });

  @override
  State<PeopleEmptyWidget> createState() => _PeopleEmptyWidgetState();
}

class _PeopleEmptyWidgetState extends State<PeopleEmptyWidget> {
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _handleCreateFamilyPressed() {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.needToBeLoggedIn)),
      );
      return;
    }
    widget.onCreateFamilyPressed?.call();
  }

  void _handleJoinFamilyPressed(String code) {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.needToBeLoggedIn)),
      );
      return;
    }
    widget.onJoinFamilyPressed?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const primary = Color(0xFF604B38);
    const accent = Color(0xFFB0906C);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.peopleLoadedTheCircle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF604B38),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    // headline (localized)
                    l.peopleEmptyTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    // subtitle / description (localized)
                    l.peopleEmptyDescription,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: accent),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _handleCreateFamilyPressed,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          l.peopleEmptyCreateFamily,
                          style: const TextStyle(color: Color(0xFF604B38)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Invite code card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.peopleEmptyEnterCode,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextField(
                                    controller: _inviteCodeController,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          letterSpacing: 4,
                                          fontSize: 18,
                                        ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'XX-0000',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => _handleJoinFamilyPressed(
                                  _inviteCodeController.text,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  l.peopleEmptyJoinFamily,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.peopleEmptyAskAdmin,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick actions
                  Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF7EDE3),
                          child: Icon(Icons.mail_outline, color: primary),
                        ),
                        title: Text(l.peopleEmptyEmailInvite),
                        subtitle: Text(l.peopleEmptyEmailInviteSubtitle),
                        onTap: () => launchUrl(Uri(scheme: 'mailto', path: '')),
                      ),
                      const SizedBox(height: 6),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF7EDE3),
                          child: Icon(Icons.lock_outline, color: primary),
                        ),
                        title: Text(l.peopleEmptyPrivateSecure),
                        subtitle: Text(l.peopleEmptyPrivateSecureSubtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
