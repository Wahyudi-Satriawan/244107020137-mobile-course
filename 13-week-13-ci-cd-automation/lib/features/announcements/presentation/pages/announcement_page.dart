import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  final String id;

  const AnnouncementPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final bannerUrl =
        'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=600&q=80';

    return Scaffold(
      appBar: AppBar(title: Text('Detail Pengumuman #$id')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              child: CachedNetworkImage(
                imageUrl: bannerUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                // Batasi memori decode pada Raster Thread (UI display width ~600px)
                memCacheWidth: 600,
                memCacheHeight: 300,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengumuman Akademik #$id',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dipublikasikan pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Ini adalah isi rincian dari pengumuman kampus ID: $id. Mahasiswa diharapkan memperhatikan jadwal dan tenggat waktu pelaksanaan kegiatan akademik terkait.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
