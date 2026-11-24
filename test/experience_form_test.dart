import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/experience_form.dart';
import 'package:myportofolio_mobile/screens/experience_list_screen.dart';
import 'package:myportofolio_mobile/screens/login_screen.dart';
import 'package:myportofolio_mobile/services/api_client.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';
import 'package:provider/provider.dart';

import 'test_helpers.dart';

const _homeText = 'Selamat datang di MyPortfolio Mobile!';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Memilih tanggal [day] pada bulan berjalan lewat date picker.
Future<void> _pickDay(WidgetTester tester, String label, String day) async {
  await _tapVisible(tester, _field(label));
  await tester.tap(find.text(day).last);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Mengisi dan mengirim [LoginScreen] (backend tiruan selalu menerima).
Future<void> _login(WidgetTester tester) async {
  expect(find.byType(LoginScreen), findsOneWidget);
  await tester.enterText(_field('Username'), 'owner');
  await tester.enterText(_field('Password'), 'secret');
  await _tapVisible(tester, find.widgetWithText(ElevatedButton, 'Login'));
}

/// Kartu Pengalaman -> daftar -> tombol + -> login -> formulir.
Future<void> _openFormFromCard(WidgetTester tester) async {
  await _tapVisible(tester, find.text('Pengalaman'));
  expect(find.byType(ExperienceListScreen), findsOneWidget);
  await _tapVisible(tester, find.byTooltip('Tambah Pengalaman'));
  await _login(tester);
}

/// Formulir langsung sebagai halaman utama, dengan pengguna sudah login.
Future<FakeBackend> _pumpForm(WidgetTester tester) async {
  final backend = FakeBackend();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: backend.client),
        ChangeNotifierProvider(
          create: (_) => AuthState(backend.client, initialToken: 'test-token'),
        ),
      ],
      child: const MaterialApp(home: ExperienceFormPage()),
    ),
  );
  return backend;
}

/// Mengisi semua field wajib kecuali tanggal selesai.
Future<void> _fillRequired(WidgetTester tester) async {
  await tester.enterText(_field('Judul Pengalaman'), '  Asisten Dosen  ');
  await tester.enterText(_field('Deskripsi Pengalaman'), 'Mengajar lab');
  await _tapVisible(tester, find.byType(DropdownButtonFormField<String>));
  await tester.tap(find.text('Internship').last);
  await tester.pumpAndSettle();
  await _pickDay(tester, 'Tanggal Mulai', '10');
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Font tes (Ahem) jauh lebih lebar dari font asli, sehingga teks di
    // DrawerHeader overflow. Teks diperkecil agar tes fokus ke alur.
    TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .textScaleFactorTestValue =
        0.5;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearTextScaleFactorTestValue();
  });

  group('navigasi ke formulir pengalaman', () {
    testWidgets(
      'kartu Pengalaman -> daftar -> + membuka formulir, Back kembali',
      (tester) async {
        await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));

        await _openFormFromCard(tester);
        expect(find.byType(ExperienceFormPage), findsOneWidget);

        // Tombol Back bawaan perangkat/browser: form -> daftar -> menu.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ExperienceListScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(_homeText), findsOneWidget);
      },
    );

    testWidgets('drawer Experiences membuka daftar pengalaman', (tester) async {
      await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));

      await _openDrawer(tester);
      await tester.tap(find.text('Experiences'));
      await tester.pumpAndSettle();
      expect(find.byType(ExperienceListScreen), findsOneWidget);
      expect(find.text('Belum ada pengalaman.'), findsOneWidget);
    });

    testWidgets('drawer Add Experience membuka formulir, Home kembali', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));

      await _openDrawer(tester);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Add Project'), findsOneWidget);
      await tester.tap(find.text('Add Experience'));
      await tester.pumpAndSettle();
      await _login(tester);
      expect(find.byType(ExperienceFormPage), findsOneWidget);

      await _openDrawer(tester);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text(_homeText), findsOneWidget);
      expect(find.byType(ExperienceFormPage), findsNothing);
    });
  });

  group('konfirmasi meninggalkan formulir', () {
    Future<void> openFilledForm(WidgetTester tester) async {
      await tester.pumpWidget(MyApp(apiClient: fakeApiClient()));
      await _openFormFromCard(tester);
      await tester.enterText(_field('Judul Pengalaman'), 'Asisten Dosen');
      await tester.pump();
    }

    testWidgets('Back dengan isian: Batal tetap di form, Buang kembali', (
      tester,
    ) async {
      await openFilledForm(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Buang perubahan?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(ExperienceFormPage), findsOneWidget);
      expect(find.text('Asisten Dosen'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buang'));
      await tester.pumpAndSettle();
      expect(find.byType(ExperienceListScreen), findsOneWidget);
    });

    testWidgets('Home di drawer dengan isian meminta konfirmasi', (
      tester,
    ) async {
      await openFilledForm(tester);

      await _openDrawer(tester);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Buang perubahan?'), findsOneWidget);

      await tester.tap(find.text('Buang'));
      await tester.pumpAndSettle();
      expect(find.text(_homeText), findsOneWidget);
      expect(find.byType(ExperienceFormPage), findsNothing);
    });
  });

  group('validasi formulir pengalaman', () {
    testWidgets('input kosong atau hanya spasi ditolak', (tester) async {
      await _pumpForm(tester);

      await tester.enterText(_field('Judul Pengalaman'), '   ');
      await _tapVisible(tester, find.text('Simpan'));

      expect(find.text('Judul pengalaman tidak boleh kosong!'), findsOneWidget);
      expect(
        find.text('Deskripsi pengalaman tidak boleh kosong!'),
        findsOneWidget,
      );
      expect(find.text('Kategori wajib dipilih!'), findsOneWidget);
      expect(find.text('Tanggal mulai wajib dipilih!'), findsOneWidget);
      expect(
        find.text('Pilih tanggal selesai atau aktifkan "Masih berlangsung"!'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('URL tanpa http/https ditolak', (tester) async {
      await _pumpForm(tester);

      await tester.enterText(_field('URL Gambar (opsional)'), 'example.com/a');
      await _tapVisible(tester, find.text('Simpan'));

      expect(find.textContaining('Masukkan URL yang valid'), findsOneWidget);
    });

    testWidgets('tanggal selesai sebelum tanggal mulai ditolak', (
      tester,
    ) async {
      await _pumpForm(tester);

      await _pickDay(tester, 'Tanggal Selesai', '10');
      await _pickDay(tester, 'Tanggal Mulai', '20');
      await _tapVisible(tester, find.text('Simpan'));

      expect(
        find.text('Tanggal selesai tidak boleh sebelum tanggal mulai!'),
        findsOneWidget,
      );
    });

    testWidgets('input valid dikirim ke API, ringkasan, lalu ke daftar', (
      tester,
    ) async {
      final backend = await _pumpForm(tester);
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');

      await _fillRequired(tester);
      await tester.enterText(
        _field('URL Gambar (opsional)'),
        'https://example.com/a.jpg',
      );
      await _pickDay(tester, 'Tanggal Selesai', '20');
      await _tapVisible(tester, find.text('Simpan'));

      expect(find.text('Pengalaman berhasil disimpan!'), findsOneWidget);
      expect(find.text('Judul: Asisten Dosen'), findsOneWidget);
      expect(find.text('Deskripsi: Mengajar lab'), findsOneWidget);
      expect(find.text('Kategori: Internship'), findsOneWidget);
      expect(
        find.text('URL Gambar: https://example.com/a.jpg'),
        findsOneWidget,
      );
      expect(
        find.text('Tanggal Mulai: 10/${now.month}/${now.year}'),
        findsOneWidget,
      );
      expect(
        find.text('Tanggal Selesai: 20/${now.month}/${now.year}'),
        findsOneWidget,
      );

      final post = backend.requests.lastWhere((r) => r.method == 'POST');
      expect(post.headers['Authorization'], 'Token test-token');
      expect(jsonDecode(post.body), {
        'title': 'Asisten Dosen',
        'description': 'Mengajar lab',
        'category': 'internship',
        'thumbnail': 'https://example.com/a.jpg',
        'start_date': '${now.year}-${two(now.month)}-10',
        'end_date': '${now.year}-${two(now.month)}-20',
      });

      // OK membawa ke daftar yang sudah memuat entri baru.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(ExperienceListScreen), findsOneWidget);
      expect(find.text('Asisten Dosen'), findsOneWidget);
    });

    testWidgets('Masih berlangsung mengosongkan tanggal selesai', (
      tester,
    ) async {
      final backend = await _pumpForm(tester);

      await _fillRequired(tester);
      await _pickDay(tester, 'Tanggal Selesai', '20');
      await _tapVisible(tester, find.text('Masih berlangsung'));

      final endField = tester.widget<TextFormField>(_field('Tanggal Selesai'));
      expect(endField.enabled, isFalse);
      expect(endField.controller!.text, isEmpty);

      await _tapVisible(tester, find.text('Simpan'));
      expect(find.text('Tanggal Selesai: Sekarang'), findsOneWidget);
      final post = backend.requests.lastWhere((r) => r.method == 'POST');
      expect((jsonDecode(post.body) as Map)['end_date'], isNull);
    });
  });

  group('pengiriman ke API', () {
    testWidgets('dari daftar: login, simpan, kembali ke daftar tersegarkan', (
      tester,
    ) async {
      final backend = FakeBackend();
      await tester.pumpWidget(MyApp(apiClient: backend.client));

      await _openFormFromCard(tester);
      expect(find.byType(ExperienceFormPage), findsOneWidget);
      await _fillRequired(tester);
      await _tapVisible(tester, find.text('Masih berlangsung'));
      await _tapVisible(tester, find.text('Simpan'));
      expect(find.text('Pengalaman berhasil disimpan!'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(ExperienceListScreen), findsOneWidget);
      expect(find.text('Asisten Dosen'), findsOneWidget);
      // Back dari daftar kembali ke menu, bukan ke form.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_homeText), findsOneWidget);
    });

    testWidgets('401: sesi dihapus lalu diminta login kembali', (tester) async {
      final backend = await _pumpForm(tester);
      backend.createExperienceStatus = 401;

      await _fillRequired(tester);
      await _tapVisible(tester, find.text('Masih berlangsung'));
      await _tapVisible(tester, find.text('Simpan'));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Sesi berakhir, silakan login kembali.'),
        findsOneWidget,
      );
      expect(
        backend.requests.any((r) => r.url.path == '/api/v1/auth/logout/'),
        isTrue,
      );
    });

    testWidgets('error lain ditampilkan lewat SnackBar', (tester) async {
      final backend = await _pumpForm(tester);
      backend.createExperienceStatus = 400;

      await _fillRequired(tester);
      await _tapVisible(tester, find.text('Masih berlangsung'));
      await _tapVisible(tester, find.text('Simpan'));

      expect(
        find.text('Gagal menyimpan pengalaman (status 400).'),
        findsOneWidget,
      );
      expect(find.byType(ExperienceFormPage), findsOneWidget);
    });
  });
}
