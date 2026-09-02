import 'package:flutter/material.dart';
import 'package:house_mira/core/widgets/sand/sand_brand_mark.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class AccountNoAccountHeaderWidget extends StatelessWidget {
  const AccountNoAccountHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: const SandBrandMark()),
        const SizedBox(height: 24),
        const Center(child: _AccountNoAccountHeroWidget()),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              height: 1.18,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(
                text: l.accountNoAccountTitleTop,
                style: TextStyle(color: SandPalette.sand700),
              ),
              const TextSpan(text: '\n'),
              TextSpan(
                text: l.accountNoAccountTitleBottom,
                style: TextStyle(color: SandPalette.sand500),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Text(
            l.accountNoAccountSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SandPalette.sand400,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _AccountNoAccountChip(
              label: l.accountNoAccountChipChores,
              icon: Icons.cleaning_services_rounded,
              background: const Color(0xFFFFFBEB),
              foreground: const Color(0xFFB45309),
              border: const Color(0xFFFDE68A),
              iconColor: const Color(0xFFF59E0B),
            ),
            _AccountNoAccountChip(
              label: l.accountNoAccountChipAppointments,
              icon: Icons.event_available_rounded,
              background: const Color(0xFFEFF6FF),
              foreground: const Color(0xFF1D4ED8),
              border: const Color(0xFFBFDBFE),
              iconColor: const Color(0xFF60A5FA),
            ),
            _AccountNoAccountChip(
              label: l.accountNoAccountChipFamilyCircle,
              icon: Icons.groups_rounded,
              background: const Color(0xFFFFF1F2),
              foreground: const Color(0xFFE11D48),
              border: const Color(0xFFFECDD3),
              iconColor: const Color(0xFFFB7185),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountNoAccountHeroWidget extends StatelessWidget {
  const _AccountNoAccountHeroWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: SandPalette.sand100,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: SandPalette.sand200.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          _FloatAnimation(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SandPalette.sand500,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: SandPalette.sand500.withValues(alpha: 0.32),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                size: 32,
                color: SandPalette.sand50,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: SizedBox(
              width: 80,
              height: 32,
              child: Stack(
                children: [
                  _HeroAvatar(
                    image: 'assets/images/onboarding/avatar_1.jpg',
                    left: 0,
                  ),
                  _HeroAvatar(
                    image: 'assets/images/onboarding/avatar_2.jpg',
                    left: 24,
                  ),
                  Positioned(
                    left: 48,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: SandPalette.sand400,
                        shape: BoxShape.circle,
                        border: Border.all(color: SandPalette.sand50, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+3',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SandPalette.sand50,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SandPalette.sand100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_rounded,
                size: 18,
                color: SandPalette.sand500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String image;
  final double left;

  const _HeroAvatar({required this.image, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: SandPalette.sand50, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}

class _AccountNoAccountChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
  final Color iconColor;

  const _AccountNoAccountChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
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
    end: -8,
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
