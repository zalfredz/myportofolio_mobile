import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:myportofolio_mobile/main.dart';
import 'package:myportofolio_mobile/screens/experience_form.dart';

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
    testWidgets('kartu Tambah Pengalaman membuka formulir, Back kembali', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await _tapVisible(tester, find.text('Tambah Pengalaman'));
      expect(find.byType(ExperienceFormPage), findsOneWidget);

      // Tombol Back bawaan perangkat/browser.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_homeText), findsOneWidget);
    });

    testWidgets('drawer Add Experience membuka formulir, Home kembali', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp());

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

      await _pickDay(tester, 'Tanggal Selesai (opsional)', '10');
      await _pickDay(tester, 'Tanggal Mulai', '20');
      await _tapVisible(tester, find.text('Simpan'));

      expect(
        find.text('Tanggal selesai tidak boleh sebelum tanggal mulai!'),
        findsOneWidget,
      );
    });

    testWidgets('input valid menampilkan ringkasan, OK mengosongkan form', (
      tester,
    ) async {
      await pumpForm(tester);
      final now = DateTime.now();

      await tester.enterText(_field('Judul Pengalaman'), '  Asisten Dosen  ');
      await tester.enterText(_field('Deskripsi Pengalaman'), 'Mengajar lab');
      await _tapVisible(tester, find.text('Pilih kategori'));
      await tester.tap(find.text('Internship').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        _field('URL Gambar (opsional)'),
        'https://example.com/a.jpg',
      );
      await _pickDay(tester, 'Tanggal Mulai', '10');
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
      expect(find.text('Tanggal Selesai: -'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Form kembali kosong sehingga Simpan memunculkan error lagi.
      await _tapVisible(tester, find.text('Simpan'));
      expect(find.text('Judul pengalaman tidak boleh kosong!'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
