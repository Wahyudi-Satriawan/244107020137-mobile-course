import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AnnouncementTile extends StatelessWidget {
  final int id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const AnnouncementTile({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  // Performance Optimization: batasi memori decode pada Raster Thread
                  memCacheWidth: 120,
                  memCacheHeight: 120,
                  placeholder: (context, url) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.campaign, color: Colors.orange),
                  ),
                ),
              )
            : const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.campaign, color: Colors.orange),
              ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
