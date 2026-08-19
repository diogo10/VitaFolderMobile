import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/onboarding_palette.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class OnboardingFamilyHeroWidget extends StatelessWidget {
  const OnboardingFamilyHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 260,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseAnimation(
            child: Container(
              width: 256,
              height: 256,
              decoration: const BoxDecoration(
                color: OnboardingPalette.sand200,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: _FloatAnimation(
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/onboarding/family_photo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 42,
            right: 6,
            child: _TagBadge(
              label: l.onboardingAtHome,
              background: const Color(0xFFDCFCE7),
              foreground: const Color(0xFF15803D),
            ),
          ),
          Positioned(
            bottom: 34,
            left: 2,
            child: _TagBadge(
              label: l.onboardingAtWork,
              background: const Color(0xFFDBEAFE),
              foreground: const Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingRemindersHeroWidget extends StatelessWidget {
  const OnboardingRemindersHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            left: 0,
            child: Transform.rotate(
              angle: -0.05,
              child: Transform.translate(
                offset: const Offset(0, 12),
                child: _FloatAnimation(
                  child: _ReminderCard(
                    icon: Icons.medication_rounded,
                    iconBackground: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFEF4444),
                    title: l.onboardingReminderMedicineTitle,
                    subtitle: l.onboardingReminderMedicineTime,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 96,
            right: 0,
            child: Transform.rotate(
              angle: 0.035,
              child: _ReminderCard(
                icon: Icons.notifications_rounded,
                iconBackground: OnboardingPalette.sand500,
                iconColor: Colors.white,
                title: l.onboardingReminderGroceryTitle,
                subtitle: l.onboardingReminderGroceryTime,
                avatars: const [
                  'assets/images/onboarding/avatar_1.jpg',
                  'assets/images/onboarding/avatar_2.jpg',
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSecurityHeroWidget extends StatelessWidget {
  const OnboardingSecurityHeroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 280,
      height: 320,
      child: _FloatAnimation(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: OnboardingPalette.sand500,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 64,
                color: OnboardingPalette.sand50,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OnboardingPalette.sand100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: OnboardingPalette.sand500,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l.onboardingEndToEndEncryption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: OnboardingPalette.sand600,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _TagBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String>? avatars;

  const _ReminderCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.avatars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OnboardingPalette.sand100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OnboardingPalette.sand700,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: OnboardingPalette.sand400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (avatars != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 24,
              child: Stack(
                children: [
                  for (var i = 0; i < avatars!.length; i++)
                    Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(avatars![i], fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FloatAnimation extends StatefulWidget {
  final Widget child;

  const _FloatAnimation({required this.child});

  @override
  State<_FloatAnimation> createState() => _FloatAnimationState();
}

class _FloatAnimationState extends State<_FloatAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final Animation<double> _offset = Tween<double>(
    begin: 0,
    end: -15,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: widget.child,
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;

  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.05,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.5,
    end: 0.8,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
