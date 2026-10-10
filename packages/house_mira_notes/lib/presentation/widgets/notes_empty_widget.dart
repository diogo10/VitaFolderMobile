import 'package:flutter/material.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/theme/sand_palette.dart';

/// Empty-list state per `designs/html/01-FamilyAdmin - Notes (Empty).html`:
/// white illustration tile with a document + amber add badge, copy,
/// and a "Create Your First Note" CTA.
class NotesEmptyWidget extends StatelessWidget {
  const NotesEmptyWidget({super.key, this.onCreate});

  /// Optional create callback (wired by the view; null renders text only).
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 64),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(52),
              boxShadow: [
                BoxShadow(
                  color: SandPalette.sand500.withValues(alpha: 0.14),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE5D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: ClipPath(
                          clipper: _FoldClipper(),
                          child: Container(
                            width: 28,
                            height: 28,
                            color: const Color(0xFFE0D6C2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 52,
                  right: 40,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFEF3C7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD97706,
                          ).withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l.notesEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: SandPalette.sand700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              l.notesEmptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: SandPalette.sand400,
                height: 1.5,
              ),
            ),
          ),
          if (onCreate != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              height: 60,
              child: FilledButton(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: SandPalette.sand500,
                  foregroundColor: SandPalette.sand50,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.notesEmptyCreateButton,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Right-triangle fold for the document illustration corner.
class _FoldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_FoldClipper oldClipper) => false;
}
