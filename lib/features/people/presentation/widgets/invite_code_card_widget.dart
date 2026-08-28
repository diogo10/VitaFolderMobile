import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class InviteCodeCardWidget extends StatelessWidget {
  final String code;
  final int expiresInDays;
  final VoidCallback? onCopyPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onRefreshPressed;
  final VoidCallback? onClose;

  const InviteCodeCardWidget({
    super.key,
    required this.code,
    required this.expiresInDays,
    this.onCopyPressed,
    this.onSharePressed,
    this.onRefreshPressed,
    this.onClose,
  });

  static const _cardColor = Color(0xFF9A7D59);
  static const _softWhite = Color(0xFFFDFBF8);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A725C43),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _CardLabel()),
              if (onClose != null)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: onClose,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: l.peopleWidgetsInviteCodeCopyTooltip,
                  onPressed: onCopyPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 19),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InviteActionButton(
                  icon: Icons.share_rounded,
                  label: l.peopleWidgetsInviteCodeShareButton,
                  onPressed: onSharePressed,
                  prominent: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InviteActionButton(
                  icon: Icons.share,
                  label: l.peopleWidgetsInviteCodeRefreshButton,
                  onPressed: onRefreshPressed,
                  prominent: false,
                  textColor: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l.peopleWidgetsInviteCodeExpiresSuffix,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 10, color: _softWhite),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.key_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          l.peopleWidgetsInviteCodeCardLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InviteActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool prominent;
  final Color? textColor;

  const _InviteActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: prominent
            ? _InviteCodeCardWidgetColors.white
            : Colors.white.withValues(alpha: 0.12),
        foregroundColor: prominent ? const Color(0xFF725C43) : Colors.white,
        side: prominent
            ? BorderSide.none
            : BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, size: 17, color: textColor),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

abstract final class _InviteCodeCardWidgetColors {
  static const white = Color(0xFFFDFBF8);
}
