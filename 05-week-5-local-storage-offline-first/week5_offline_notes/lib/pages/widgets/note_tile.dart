import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/note.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  const NoteTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(
        note.body,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Menampilkan badge (ikon) jika dirty true (belum sinkron)
      trailing: note.dirty
          ? const Tooltip(
              message: 'Belum tersinkron',
              child: Icon(Icons.cloud_off, color: Colors.orange),
            )
          : const Icon(Icons.cloud_done, color: Colors.green),
      onTap: () {
        // Menggunakan GoRouter untuk navigasi ke halaman detail
        context.push('/note/${note.id}');
      },
    );
  }
}