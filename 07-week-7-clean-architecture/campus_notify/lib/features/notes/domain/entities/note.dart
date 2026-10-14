class Note {
  Note({
    this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.dirty = 0,
  });

  int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  int dirty;
}