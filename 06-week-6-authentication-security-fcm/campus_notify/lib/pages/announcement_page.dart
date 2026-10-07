import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  final String id;

  const AnnouncementPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Pengumuman #$id')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Ini adalah isi rincian dari pengumuman kampus ID: $id.',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}