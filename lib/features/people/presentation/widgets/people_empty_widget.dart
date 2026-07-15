import 'package:flutter/material.dart';

class PeopleEmptyWidget extends StatelessWidget {
  const PeopleEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: Color(0xFFB0906C),
          ),
          SizedBox(height: 16),
          Text(
            'No family members yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF604B38),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first family member to get started.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFB0906C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
