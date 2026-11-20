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
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Tanya AI',
            onPressed: () => context.push('/chat'),
          ),
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
                itemCount: 10,
                physics: const AlwaysScrollableScrollPhysics(),
                addAutomaticKeepAlives: false,
                itemBuilder: (context, index) {
                  final id = index + 1;
                  // URL gambar thumbnail untuk optimasi CachedNetworkImage
                  final imageUrl = id % 2 == 0
                      ? 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=200&q=80'
                      : 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=200&q=80';
                  return AnnouncementTile(
                    id: id,
                    title: 'Pengumuman Kampus #$id',
                    subtitle: 'Klik untuk membaca detail pengumuman',
                    imageUrl: imageUrl,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chat'),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Tanya AI'),
      ),
    );
  }
}
