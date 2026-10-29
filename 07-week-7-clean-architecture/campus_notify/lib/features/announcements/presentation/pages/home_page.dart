import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/announcement_tile.dart';
import '../widgets/fcm_token_card.dart';

class HomePage extends ConsumerWidget {
  final String truncatedToken;

  const HomePage({super.key, required this.truncatedToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengumuman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: 'Catatan',
            onPressed: () => context.push('/notes'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FcmTokenCard(token: truncatedToken),
            const SizedBox(height: 16),
            const Text(
              'Daftar Pengumuman Kampus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  final id = index + 1;
                  return AnnouncementTile(
                    id: id,
                    title: 'Pengumuman Kampus #$id',
                    subtitle: 'Klik untuk membaca detail pengumuman',
                    onTap: () {
                      context.push('/pengumuman/$id');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
