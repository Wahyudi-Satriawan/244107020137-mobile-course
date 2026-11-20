import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../providers/notes_providers.dart';
import '../widgets/notes_list.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Catatan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Judul Catatan',
                      hintText: 'Masukkan judul catatan',
                      errorText: errorMessage,
                    ),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setState(() {
                          errorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Isi Catatan (opsional)',
                      hintText: 'Tulis isi catatan di sini',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text;
                    final body = bodyController.text;

                    final (_, failure) = await ref
                        .read(addNoteProvider)
                        .call(title: title, body: body);

                    if (failure != null) {
                      setState(() {
                        errorMessage = failure.message;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(failure.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ref.invalidate(notesProvider);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Catatan berhasil ditambahkan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    bodyController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Kampus')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(notesProvider),
        ),
        data: (notes) => notes.isEmpty
            ? const Center(child: Text('Belum ada catatan.'))
            : NotesList(notes),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
