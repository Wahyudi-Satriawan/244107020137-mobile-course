import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// Daftar catatan dengan optimasi lazy loading via ListView.builder,
/// pemisahan widget item ke class terpisah, dan isolasi repaint boundary.
class NotesList extends StatelessWidget {
  final List<Note> notes;

  const NotesList(this.notes, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notes.length,
      // Mengurangi overhead penyimpanan state offscreen
      addAutomaticKeepAlives: false,
      // Mengisolasi repaint per item saat scroll
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteItemTile(note: note);
      },
    );
  }
}

/// Item widget terpisah untuk efisiensi memory & widget reuse
class NoteItemTile extends StatelessWidget {
  final Note note;

  const NoteItemTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.note, color: Colors.green),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          note.body.isEmpty ? '(Tidak ada isi)' : note.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: note.dirty
            ? const Tooltip(
                message: 'Belum tersinkron',
                child: Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.amber),
              )
            : const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
      ),
    );
  }
}
