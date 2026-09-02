import 'package:flutter/material.dart';
import 'package:house_mira/generated/app_localizations.dart';

class AddFamilyMemberCardWidget extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddFamilyMemberCardWidget({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: const Color(0xFFFFFCF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFD3B487),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7DDD0)),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFFB79872),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.peopleWidgetsAddFamilyMemberTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFB0906C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.peopleWidgetsAddFamilyMemberSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC5AD91),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFC0A789),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
