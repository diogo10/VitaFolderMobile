import 'package:flutter/material.dart';

enum FamilyMemberRole {
  admin('Admin', Color(0xFFF6D584), Color(0xFF9B6500)),
  parent('Parent', Color(0xFFD9E8FF), Color(0xFF3974C9)),
  child('Child', Color(0xFFE8DFFF), Color(0xFF6D4BD2)),
  member('Member', Color(0xFFD9F5EA), Color(0xFF27835F));

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const FamilyMemberRole(
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  );
}

class FamilyMemberCardWidget extends StatelessWidget {
  final String name;
  final String relationship;
  final String detail;
  final FamilyMemberRole role;
  final Color avatarColor;
  final VoidCallback? onPressed;

  const FamilyMemberCardWidget({
    super.key,
    required this.name,
    required this.relationship,
    required this.detail,
    required this.role,
    required this.avatarColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF604B38);

    return Material(
      color: const Color(0xFFF4EFE7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE7DDD0)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: avatarColor,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: brown,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: role.backgroundColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            role.label,
                            style: TextStyle(
                              color: role.foregroundColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$relationship · $detail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFA98B6B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE3D7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC0A789),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    if (value.isEmpty) return "";
    final words = value.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
