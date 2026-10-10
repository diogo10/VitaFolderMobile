import 'package:flutter/material.dart';
import 'package:house_mira_paywall/domain/entities/paywall_plan_entity.dart';
import 'package:house_mira_core/generated/app_localizations.dart';
import 'package:house_mira_core/theme/sand_palette.dart';

/// A selectable subscription plan pill from the paywall design. Titles and
/// notes resolve from [plan.id] via `AppLocalizations`; prices arrive on
/// the mocked entity.
class PaywallPlanTileWidget extends StatelessWidget {
  const PaywallPlanTileWidget({
    required this.plan,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final PaywallPlanEntity plan;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? SandPalette.sand500 : SandPalette.sand100,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: SandPalette.sand500.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? SandPalette.sand500
                          : SandPalette.sand200,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: SandPalette.sand500,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _titleFor(plan.id, l),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                color: SandPalette.sand700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (plan.savePercent != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9F5EA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.paywallSaveBadge(plan.savePercent!),
                                style: const TextStyle(
                                  fontFamily: 'Figtree',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF27835F),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _noteFor(plan, l),
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          color: SandPalette.sand300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.monthlyPriceLabel,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: SandPalette.sand700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.paywallPerMonth,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        color: SandPalette.sand300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(String id, AppLocalizations l) {
    return switch (id) {
      'monthly' => l.paywallMonthlyTitle,
      _ => l.paywallAnnualTitle,
    };
  }

  String _noteFor(PaywallPlanEntity plan, AppLocalizations l) {
    if (plan.isAnnual && plan.annualTotalLabel != null) {
      return l.paywallAnnualNote(plan.annualTotalLabel!);
    }
    return l.paywallMonthlyNote;
  }
}
