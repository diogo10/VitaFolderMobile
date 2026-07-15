import 'package:flutter/material.dart';

class RolePermissionsCardWidget extends StatelessWidget {
  final VoidCallback? onLearnMorePressed;

  const RolePermissionsCardWidget({super.key, this.onLearnMorePressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D5C5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_rounded, size: 17, color: Color(0xFFB79872)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role Permissions',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF725C43),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Admins can manage all members. Parents can add tasks. '
                  'Children have view-only access.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA98B6B),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: onLearnMorePressed,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF725C43),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Learn more →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
