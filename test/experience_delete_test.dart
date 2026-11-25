import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/experience_detail_screen.dart';
import 'package:myportofolio_mobile/screens/experience_list_screen.dart';
import 'package:myportofolio_mobile/screens/login_screen.dart';

import 'test_helpers.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Backend tiruan berisi satu pengalaman.
FakeBackend _backendWithOneExperience() {
  return FakeBackend()
    ..experiences.add({
      'id': 'exp-1',
      'title': 'Asisten Dosen',
      'description': 'Mengajar lab',
      'category': 'internship',
      'category_display': 'Internship',
      'thumbnail': null,
      'start_date': '2026-08-01',
      'end_date': null,
      'is_ongoing': true,
    });
}

/// Menu -> kartu Pengalaman -> item -> tombol hapus -> login.
Future<void> _openDetailAndTapDelete(WidgetTester tester) async {
  await _tapVisible(tester, find.text('Pengalaman'));
  await _tapVisible(tester, find.text('Asisten Dosen'));
  expect(find.byType(ExperienceDetailScreen), findsOneWidget);
  await _tapVisible(tester, find.byTooltip('Hapus Pengalaman'));
  expect(find.byType(LoginScreen), findsOneWidget);
  await tester.enterText(_field('Username'), 'owner');
  await tester.enterText(_field('Password'), 'secret');
  await _tapVisible(tester, find.widgetWithText(ElevatedButton, 'Login'));
}

void main() {
  testWidgets('hapus: konfirmasi, DELETE ber-token, daftar tersegarkan', (
    tester,
  ) async {
    final backend = _backendWithOneExperience();
    await tester.pumpWidget(MyApp(apiClient: backend.client));

    await _openDetailAndTapDelete(tester);
    expect(find.text('Hapus pengalaman?'), findsOneWidget);
    await _tapVisible(tester, find.text('Hapus'));

    final delete = backend.requests.lastWhere((r) => r.method == 'DELETE');
    expect(delete.url.path, '/api/v1/experiences/exp-1/');
    expect(delete.headers['Authorization'], 'Token test-token');
    expect(find.byType(ExperienceListScreen), findsOneWidget);
    expect(find.text('"Asisten Dosen" berhasil dihapus.'), findsOneWidget);
    expect(find.text('Belum ada pengalaman.'), findsOneWidget);
  });

  testWidgets('Batal tidak mengirim DELETE', (tester) async {
    final backend = _backendWithOneExperience();
    await tester.pumpWidget(MyApp(apiClient: backend.client));

    await _openDetailAndTapDelete(tester);
    await _tapVisible(tester, find.text('Batal'));

    expect(backend.requests.any((r) => r.method == 'DELETE'), isFalse);
    expect(find.byType(ExperienceDetailScreen), findsOneWidget);
  });

  testWidgets('403 (bukan pemilik) ditampilkan lewat SnackBar', (tester) async {
    final backend = _backendWithOneExperience()..deleteExperienceStatus = 403;
    await tester.pumpWidget(MyApp(apiClient: backend.client));

    await _openDetailAndTapDelete(tester);
    await _tapVisible(tester, find.text('Hapus'));

    expect(
      find.text('Gagal menghapus pengalaman (status 403).'),
      findsOneWidget,
    );
    expect(find.byType(ExperienceDetailScreen), findsOneWidget);
    expect(backend.experiences, hasLength(1));
  });

  testWidgets('401: sesi dihapus lalu diminta login kembali', (tester) async {
    final backend = _backendWithOneExperience()..deleteExperienceStatus = 401;
    await tester.pumpWidget(MyApp(apiClient: backend.client));

    await _openDetailAndTapDelete(tester);
    await _tapVisible(tester, find.text('Hapus'));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sesi berakhir, silakan login kembali.'), findsOneWidget);
    expect(
      backend.requests.any((r) => r.url.path == '/api/v1/auth/logout/'),
      isTrue,
    );
  });
}
