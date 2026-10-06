import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

/// Signed-out state per
/// `designs/html/01-FamilyAdmin - Notes for Unlogged User.html`:
/// tilted-notes illustration, copy, Sign In / Join actions, create-account
/// link. Navigation is injected so the widget stays logic-less.
class NotesUnauthenticatedWidget extends StatelessWidget {
  const NotesUnauthenticatedWidget({
    required this.onSignIn,
    required this.onJoinFamily,
    required this.onCreateAccount,
    super.key,
  });
  final VoidCallback onSignIn;
  final VoidCallback onJoinFamily;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          SizedBox(
            width: 196,
            height: 152,
            child: Stack(
              children: [
                Positioned(
                  left: 2,
                  top: 0,
                  child: Transform.rotate(
                    angle: -0.09,
                    child: Container(
                      width: 72,
                      height: 71,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD97706,
                            ).withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NoteLine(widthFactor: 0.7, color: Color(0xFFF59E0B)),
                          SizedBox(height: 6),
                          _NoteLine(
                            widthFactor: 0.92,
                            color: Color(0xFFFDE68A),
                          ),
                          SizedBox(height: 6),
                          _NoteLine(
                            widthFactor: 0.55,
                            color: Color(0xFFFDE68A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 96,
                  top: 60,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: Container(
                      width: 88,
                      height: 84,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.20),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NoteLine(
                            widthFactor: 0.45,
                            color: Color(0xFF60A5FA),
                          ),
                          SizedBox(height: 8),
                          _NoteLine(widthFactor: 0.8, color: Color(0xFF93C5FD)),
                          SizedBox(height: 8),
                          _NoteLine(widthFactor: 0.6, color: Color(0xFF93C5FD)),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 65,
                  top: 48,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SandPalette.sand500.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sticky_note_2_rounded,
                        size: 24,
                        color: SandPalette.sand400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l.notesUnauthenticatedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: SandPalette.sand700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              l.notesUnauthenticatedMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: SandPalette.sand400,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: SandPalette.sand500,
                foregroundColor: SandPalette.sand50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                l.notesSignInToStart,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onJoinFamily,
              style: OutlinedButton.styleFrom(
                foregroundColor: SandPalette.sand600,
                backgroundColor: Colors.white,
                side: const BorderSide(color: SandPalette.sand200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                l.notesJoinFamily,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l.notesNewToApp,
            style: const TextStyle(fontSize: 12, color: SandPalette.sand300),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCreateAccount,
            child: Text(
              l.notesCreateAccount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: SandPalette.sand500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.widthFactor, required this.color});
  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
