import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/pages/stats_page.dart';

class FakeRandom implements Random {
  final double stubbedValue;
  FakeRandom(this.stubbedValue);

  @override
  double nextDouble() => stubbedValue;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('StatsNotifier Unit Tests', () {
    test('State awal saat provider pertama kali diinisialisasi adalah AsyncLoading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialState = container.read(statsProvider);

      expect(initialState, isA<AsyncLoading<List<String>>>());
    });

    test('Memuat 3 data statistik saat probabilitas sukses (nilai acak >= 0.3)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(statsProvider.notifier);
      notifier.delay = Duration.zero;
      notifier.random = FakeRandom(0.7);

      final data = await container.read(statsProvider.future);

      expect(data.length, 3);
      expect(data[0], contains('Total Pengguna Aktif'));
      expect(container.read(statsProvider), isA<AsyncData<List<String>>>());
    });

    test('Menghasilkan AsyncError saat terjadi kegagalan (nilai acak < 0.3)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(statsProvider.notifier);
      notifier.delay = Duration.zero;
      notifier.random = FakeRandom(0.1);

      expect(
        () async => await container.read(statsProvider.future),
        throwsA(isA<Exception>()),
      );

      final state = container.read(statsProvider);
      expect(state, isA<AsyncError<List<String>>>());
    });
  });
}