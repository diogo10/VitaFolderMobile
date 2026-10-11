import 'package:flutter/material.dart';
import 'package:house_mira_paywall/domain/entities/paywall_feature_entity.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/theme/sand_palette.dart';

/// A single Pro feature row from the paywall design: tinted icon tile plus
/// localized title and description. Copy and icon resolve from [feature.id].
class PaywallFeatureCardWidget extends StatelessWidget {
  const PaywallFeatureCardWidget({required this.feature, super.key});

  final PaywallFeatureEntity feature;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = _styleFor(feature.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SandPalette.sand100),
        boxShadow: [
          BoxShadow(
            color: SandPalette.sand500.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(style.icon, color: style.iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleFor(feature.id, l),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: SandPalette.sand700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _descriptionFor(feature.id, l),
                    style: const TextStyle(
                      fontFamily: 'Figtree',
                      color: SandPalette.sand300,
                      fontSize: 12,
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

  String _titleFor(String id, AppLocalizations l) {
    return switch (id) {
      'sorting' => l.paywallFeatureSortingTitle,
      'sync' => l.paywallFeatureSyncTitle,
      _ => l.paywallFeatureUnlimitedTitle,
    };
  }

  String _descriptionFor(String id, AppLocalizations l) {
    return switch (id) {
      'sorting' => l.paywallFeatureSortingDescription,
      'sync' => l.paywallFeatureSyncDescription,
      _ => l.paywallFeatureUnlimitedDescription,
    };
  }

  _FeatureStyle _styleFor(String id) {
    return switch (id) {
      'sorting' => const _FeatureStyle(
        icon: Icons.auto_awesome_rounded,
        background: Color(0xFFFDF3E3),
        iconColor: Color(0xFFE8930C),
      ),
      'sync' => const _FeatureStyle(
        icon: Icons.cloud_upload_rounded,
        background: Color(0xFFEAF3FE),
        iconColor: Color(0xFF3B82F6),
      ),
      _ => const _FeatureStyle(
        icon: Icons.all_inclusive_rounded,
        background: Color(0xFFF1ECE2),
        iconColor: SandPalette.sand500,
      ),
    };
  }
}

class _FeatureStyle {
  const _FeatureStyle({
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
}
