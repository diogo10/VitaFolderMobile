import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/features/paywall/presentation/cubit/paywall_cubit.dart';
import 'package:house_mira/features/paywall/presentation/cubit/paywall_state.dart';
import 'package:house_mira/features/paywall/presentation/widgets/paywall_feature_card_widget.dart';
import 'package:house_mira/features/paywall/presentation/widgets/paywall_plan_tile_widget.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

/// HouseMira Pro paywall, converted from
/// `designs/html/01-FamilyAdmin - PayWall.html`.
///
/// The catalog is mocked in [PaywallRepositoryImpl] until store billing is
/// wired; the trial/restore actions surface a placeholder snackbar.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<PaywallCubit>().loadPaywall());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: SandPalette.sand50,
      body: SafeArea(
        child: BlocConsumer<PaywallCubit, PaywallState>(
          listener: (context, state) {
            if (state is PaywallTrialStarted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l.paywallTrialStarted)));
            }
            if (state is PaywallRestoreCompleted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l.paywallRestoreStarted)),
                );
            }
            if (state is PaywallActionFailed) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l.paywallLoadFailed)));
            }
          },
          builder: (context, state) {
            if (state is PaywallLoadFailed) {
              return Column(
                children: [
                  _TopBar(title: l.paywallTitle),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l.paywallLoadFailed,
                            style: const TextStyle(
                              color: SandPalette.sand500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                context.read<PaywallCubit>().loadPaywall(),
                            child: Text(l.paywallRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is! PaywallLoaded) {
              return Column(
                children: [
                  _TopBar(title: l.paywallTitle),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            final loaded = state;
            final cubit = context.read<PaywallCubit>();

            return Column(
              children: [
                _TopBar(title: l.paywallTitle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            border: Border.all(
                              color: const Color(0xFFFEF3C7),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD97706),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l.paywallLimitReached,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l.paywallHeadline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            color: SandPalette.sand700,
                            fontSize: 30,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.paywallSubtext,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            color: SandPalette.sand300,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...loaded.data.features.asMap().entries.map((entry) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  entry.key < loaded.data.features.length - 1
                                  ? 12
                                  : 0,
                            ),
                            child: PaywallFeatureCardWidget(
                              feature: entry.value,
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                        ...loaded.data.plans.asMap().entries.map((entry) {
                          final plan = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key < loaded.data.plans.length - 1
                                  ? 12
                                  : 0,
                            ),
                            child: PaywallPlanTileWidget(
                              plan: plan,
                              selected: plan.id == loaded.selectedPlanId,
                              onSelected: () => cubit.selectPlan(plan.id),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        SandPrimaryButton(
                          label: l.paywallCtaTrial,
                          icon: Icons.bolt_rounded,
                          isLoading: loaded.isActing,
                          onPressed: loaded.isActing
                              ? null
                              : () => unawaited(cubit.startTrial()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.paywallTerms,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            color: SandPalette.sand300,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: loaded.isActing
                              ? null
                              : () => unawaited(cubit.restorePurchases()),
                          child: Text(
                            l.paywallRestore,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              color: SandPalette.sand300,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: SandPalette.sand100),
                  boxShadow: [
                    BoxShadow(
                      color: SandPalette.sand500.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: SandPalette.sand400,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: SandPalette.sand600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: SandPalette.sand50,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    color: SandPalette.sand700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
