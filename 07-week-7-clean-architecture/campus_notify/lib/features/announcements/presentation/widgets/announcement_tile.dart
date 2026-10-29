import 'package:flutter/material.dart';

class AnnouncementTile extends StatelessWidget {
  final int id;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AnnouncementTile({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.orange),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
