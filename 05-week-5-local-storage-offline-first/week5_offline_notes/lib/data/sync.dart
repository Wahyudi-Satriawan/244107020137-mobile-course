import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'repositories/note_repository.dart';
// Sesuaikan import ini dengan lokasi model Post dan provider API kamu dari minggu 4
// import '../models/post.dart'; 
// import 'providers.dart'; 

// =====================================================================
// 1. TOGGLE SIMULASI OFFLINE (forceOffline)
// =====================================================================
final forceOfflineProvider = StateProvider<bool>((ref) => false);

// =====================================================================
// 2. SINKRONISASI CATATAN KOTOR (DIRTY)
// =====================================================================
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  
  if (dirtyCount == 0) return 0; 

  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  
  return dirtyCount;
}

// =====================================================================
// 3. ATURAN KONFLIK (CONFLICT RESOLUTION)
// =====================================================================
/*
 * ATURAN KONFLIK: Last-Write-Wins berdasarkan updated_at.
 * Data dengan timestamp updated_at paling baru akan menimpa data lama.
 */

// =====================================================================
// 4. CACHE-FIRST READ UNTUK DATA API (POSTS)
// =====================================================================

// Helper untuk membaca dari SQLite (tabel cached_posts)
Future<List<dynamic>> readCachedPosts() async {
  final db = await openNotesDb();
  final rows = await db.query('cached_posts');
  return rows.map((row) => jsonDecode(row['payload'] as String)).toList();
}

// Fungsi utama Cache-First (Bisa dipanggil di dalam build Provider kamu)
Future<List<dynamic>> loadPostsCacheFirst(Ref ref, Dio dio) async {
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  final cached = await readCachedPosts(); 
  
  // Cek apakah toggle forceOffline aktif
  final isOffline = ref.read(forceOfflineProvider);
  
  if (!isOffline) {
    // 2. Di background: fetch Dio -> simpan ke cached_posts -> invalidate provider.
    refreshPostsInBackground(ref, dio); 
  }
  
  return cached;
}

// Fetch via Dio di background
Future<void> refreshPostsInBackground(Ref ref, Dio dio) async {
  try {
    final response = await dio.get('/posts');
    final data = response.data as List<dynamic>;
    
    final db = await openNotesDb();
    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      for (var item in data) {
        await txn.insert('cached_posts', {
          'id': item['id'],
          'payload': jsonEncode(item),
          'cached_at': DateTime.now().toIso8601String(),
        });
      }
    });
    
    // Refresh provider agar UI update dengan data terbaru
    // ref.invalidate(postListProvider); 
  } catch (e) {
    print("Background sync gagal (offline): $e");
  }
}