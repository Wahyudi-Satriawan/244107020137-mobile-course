import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';

// Asumsi: noteRepositoryProvider sudah dideklarasikan di file provider Anda
// final noteRepositoryProvider = Provider((ref) => NoteRepository());

class NoteDetailPage extends ConsumerWidget {
  final int noteId;
  const NoteDetailPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(noteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      // Membaca langsung dari repository lokal seperti instruksi refactoring
      body: FutureBuilder<List<Note>>(
        future: repo.fetchNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notes = snapshot.data ?? [];
          final note = notes.firstWhere(
            (n) => n.id == noteId,
            orElse: () => Note(
              title: 'Tidak ditemukan',
              body: '',
              updatedAt: DateTime.now(),
              dirty: false,
            ),
          );

          if (note.id == null) {
            return const Center(child: Text('Catatan tidak ditemukan.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Terakhir diubah: ${note.updatedAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(note.body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        },
      ),
    );
  }
}