import 'package:flutter/material.dart';
import 'package:house_mira/theme/sand_palette.dart';

class OnboardingProgressWidget extends StatelessWidget {

  const OnboardingProgressWidget({
    required this.currentPage, super.key,
    this.pageCount = 3,
  });
  final int currentPage;
  final int pageCount;

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
