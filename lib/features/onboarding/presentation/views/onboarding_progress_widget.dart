import 'package:flutter/material.dart';
import 'package:house_mira/theme/sand_palette.dart';

class OnboardingProgressWidget extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const OnboardingProgressWidget({
    super.key,
    required this.currentPage,
    this.pageCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? SandPalette.sand500
                : SandPalette.sand200,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
