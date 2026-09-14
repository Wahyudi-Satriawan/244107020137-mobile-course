import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1. NOTIFIER: Mengelola logika dan state asinkron statistik
class StatsNotifier extends AsyncNotifier<List<String>> {
  // Generator nilai acak untuk probabilitas kegagalan 30%
  // Dibuat terbuka (@visibleForTesting) agar dapat diinjeksi saat pengujian
  @visibleForTesting
  Random random = Random();

  // Durasi jeda jaringan (dapat diatur ke Duration.zero saat unit test)
  @visibleForTesting
  Duration delay = const Duration(seconds: 2);

  @override
  Future<List<String>> build() async {
    // Memulai proses pengambilan data secara asinkron
    return _fetchStats();
  }

  /// Fungsi privat yang mensimulasikan fetch data dari server API
  Future<List<String>> _fetchStats() async {
    // Simulasi latensi jaringan selama 2 detik
    await Future.delayed(delay);

    // Simulasi kegagalan dengan rasio 30% (probabilitas 0.0 - 0.299)
    if (random.nextDouble() < 0.3) {
      throw Exception('Koneksi terputus: Server statistik tidak merespons.');
    }

    // Mengembalikan list statis 3 item data secara immutable (const)
    return const [
      'Total Pengguna Aktif: 1.420 Akun',
      'Tingkat Keberhasilan: 94.8%',
      'Rata-rata Waktu Respons: 120 ms',
    ];
  }
}

/// 2. PROVIDER: Deklarasi global dengan pengetikan tipe data yang eksplisit
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);

/// 3. UI: Tampilan antarmuka berbasis ConsumerWidget
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch HANYA diletakkan di dalam method build untuk memantau perubahan AsyncValue
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Sistem'),
      ),
      // AsyncValue.when menangani ketiga state: loading, error, dan success secara deklaratif
      body: statsAsync.when(
        // Kondisi 1: Loading -> Menampilkan CircularProgressIndicator di tengah layar
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Kondisi 2: Error -> Menampilkan pesan kegagalan dan tombol coba lagi
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  // ref.invalidate mereset state provider dan memicu build() ulang
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),

        // Kondisi 3: Success -> Menampilkan ListView dengan 3 item
        data: (stats) => ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: stats.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(
              stats[index],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}