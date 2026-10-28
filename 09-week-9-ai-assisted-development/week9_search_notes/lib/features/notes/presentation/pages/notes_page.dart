import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/notes_providers.dart';
import '../widgets/notes_list.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredNotesProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari catatan berdasarkan judul...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),
          // ── List / Empty / Loading / Error ─────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(allNotesProvider),
              ),
              data: (notes) {
                if (notes.isEmpty && query.isNotEmpty) {
                  return const EmptyStateView(
                    message: 'Tidak ada catatan yang cocok dengan pencarian.',
                    icon: Icons.search_off,
                  );
                }
                if (notes.isEmpty) {
                  return const EmptyStateView(
                    message: 'Belum ada catatan. Tambahkan catatan baru!',
                    icon: Icons.note_add_outlined,
                  );
                }
                return NotesList(notes);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final repo = ref.read(noteRepositoryProvider);
          await repo.addNote(
            title: 'Belajar Flutter',
            body: 'Materi AI-Assisted Development',
          );
          ref.invalidate(allNotesProvider);
        },
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
