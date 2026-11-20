class Announcement {
  final int id;
  final String title;
  final String subtitle;
  final String content;
  final String? imageUrl;

  const Announcement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    this.imageUrl,
  });
}
