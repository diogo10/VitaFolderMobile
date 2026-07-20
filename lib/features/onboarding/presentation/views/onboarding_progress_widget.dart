import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/theme_extensions.dart';

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) {
          final isActive = index == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}
