import 'package:flutter/material.dart';

class PersonCardWidget extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final int id;

  const PersonCardWidget({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color.fromARGB(33, 158, 158, 158),
              width: 1,
            ),
          ),
          width: double.infinity,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Text(
                  name[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    Text(
                      phone,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
