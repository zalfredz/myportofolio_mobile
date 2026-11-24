import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/experience_form.dart';
import 'package:myportofolio_mobile/screens/experience_list_screen.dart';

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

/// Kartu Pengalaman membuka daftar, lalu tombol + membuka formulir.
Future<void> _openFormFromCard(WidgetTester tester) async {
  await _tapVisible(tester, find.text('Pengalaman'));
  expect(find.byType(ExperienceListScreen), findsOneWidget);
  await _tapVisible(tester, find.byTooltip('Tambah Pengalaman'));
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
    Future<void> pumpForm(WidgetTester tester) =>
        tester.pumpWidget(const MaterialApp(home: ExperienceFormPage()));

    testWidgets('input kosong atau hanya spasi ditolak', (tester) async {
      await pumpForm(tester);

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
      await pumpForm(tester);

      await tester.enterText(_field('URL Gambar (opsional)'), 'example.com/a');
      await _tapVisible(tester, find.text('Simpan'));

      expect(find.textContaining('Masukkan URL yang valid'), findsOneWidget);
    });

    testWidgets('tanggal selesai sebelum tanggal mulai ditolak', (
      tester,
    ) async {
      await pumpForm(tester);

      await _pickDay(tester, 'Tanggal Selesai', '10');
      await _pickDay(tester, 'Tanggal Mulai', '20');
      await _tapVisible(tester, find.text('Simpan'));

      expect(
        find.text('Tanggal selesai tidak boleh sebelum tanggal mulai!'),
        findsOneWidget,
      );
    });

    /// Mengisi semua field wajib kecuali tanggal selesai.
    Future<void> fillRequired(WidgetTester tester) async {
      await tester.enterText(_field('Judul Pengalaman'), '  Asisten Dosen  ');
      await tester.enterText(_field('Deskripsi Pengalaman'), 'Mengajar lab');
      await _tapVisible(tester, find.text('Pilih kategori'));
      await tester.tap(find.text('Internship').last);
      await tester.pumpAndSettle();
      await _pickDay(tester, 'Tanggal Mulai', '10');
    }

    testWidgets('input valid menampilkan ringkasan, OK mengosongkan form', (
      tester,
    ) async {
      await pumpForm(tester);
      final now = DateTime.now();

      await fillRequired(tester);
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

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Form kembali kosong sehingga Simpan memunculkan error lagi.
      await _tapVisible(tester, find.text('Simpan'));
      expect(find.text('Judul pengalaman tidak boleh kosong!'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Masih berlangsung mengosongkan tanggal selesai', (
      tester,
    ) async {
      await pumpForm(tester);

      await fillRequired(tester);
      await _pickDay(tester, 'Tanggal Selesai', '20');
      await _tapVisible(tester, find.text('Masih berlangsung'));

      final endField = tester.widget<TextFormField>(_field('Tanggal Selesai'));
      expect(endField.enabled, isFalse);
      expect(endField.controller!.text, isEmpty);

      await _tapVisible(tester, find.text('Simpan'));
      expect(find.text('Tanggal Selesai: Sekarang'), findsOneWidget);

      // Setelah OK, switch kembali mati.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    });
  });
}
