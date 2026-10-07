import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/utils/route_parser.dart';

class FakeTokenStore {
  String? access;
  String? refresh;

  bool get hasAccess => access != null && access!.isNotEmpty;
  bool get needsLogin => refresh == null || refresh!.isEmpty;
}

void main() {
  group('Testing Route Parser FCM Payload', () {
    test('Route parser menangani route kosong atau null tanpa crash', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': ''}), '/');
      expect(routeFromMessage({'route': '   '}), '/');
    });

    test('Route parser memformat string route dengan benar', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });
  });

  group('Testing Logika Sesi Token Store', () {
    test('Status sesi dianggap aktif jika access token tersimpan', () {
      final store = FakeTokenStore()..access = 'mock_access_token';
      expect(store.hasAccess, isTrue);
    });

    test('Wajib login ulang jika refresh token kosong', () {
      final store = FakeTokenStore()..refresh = '';
      expect(store.needsLogin, isTrue);
    });
  });
}