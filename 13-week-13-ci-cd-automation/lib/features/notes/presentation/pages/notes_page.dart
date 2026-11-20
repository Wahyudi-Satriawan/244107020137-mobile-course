import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../providers/notes_providers.dart';
import '../widgets/notes_list.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _AddNoteDialog(parentContext: context, ref: ref),
    );
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
        key: const Key('add-note-fab'),
        onPressed: () => _showAddNoteDialog(context, ref),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final BuildContext parentContext;
  final WidgetRef ref;

  const _AddNoteDialog({required this.parentContext, required this.ref});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('note-title-field'),
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Judul Catatan',
                hintText: 'Masukkan judul catatan',
                errorText: _errorMessage,
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('note-body-field'),
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan (opsional)',
                hintText: 'Tulis isi catatan di sini',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-note-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('save-note-button'),
          onPressed: () async {
            final title = _titleController.text;
            final body = _bodyController.text;

            final (_, failure) = await widget.ref
                .read(addNoteProvider)
                .call(title: title, body: body);

            if (failure != null) {
              if (mounted) {
                setState(() {
                  _errorMessage = failure.message;
                });
              }
              if (widget.parentContext.mounted) {
                ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                  SnackBar(
                    content: Text(failure.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              widget.ref.invalidate(notesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              if (widget.parentContext.mounted) {
                ScaffoldMessenger.of(widget.parentContext).showSnackBar(
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
  }
}
