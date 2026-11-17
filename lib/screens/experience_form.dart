import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:myportofolio_mobile/widgets/left_drawer.dart';

/// Formulir tambah pengalaman. Field dan aturannya mengikuti model
/// `Experience` serta `ExperienceForm` di proyek Django myportofolio.
class ExperienceFormPage extends StatefulWidget {
  const ExperienceFormPage({super.key});

  @override
  State<ExperienceFormPage> createState() => _ExperienceFormPageState();
}

class _ExperienceFormPageState extends State<ExperienceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String _title = '';
  String _description = '';
  String? _category;
  String _thumbnail = '';
  DateTime? _startDate;
  DateTime? _endDate;

  /// Pengalaman yang masih berlangsung tidak punya tanggal selesai,
  /// sama seperti `end_date` kosong (`is_ongoing`) di model Django.
  bool _isOngoing = false;

  // Sama dengan pilihan yang ditampilkan ExperienceForm di Django.
  static const List<String> _categories = [
    'Full-Time',
    'Internship',
    'Volunteer',
  ];

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // Format hari/bulan/tahun agar tahun selalu tampil.
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  /// Membuka date picker lalu menyimpan tanggal ke state dan ke field teksnya.
  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? _startDate ?? DateTime.now(),
      // Tanggal selesai tidak bisa dipilih sebelum tanggal mulai.
      firstDate: isStart ? DateTime(1950) : (_startDate ?? DateTime(1950)),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        _startDateController.text = _formatDate(picked);
      } else {
        _endDate = picked;
        _endDateController.text = _formatDate(picked);
      }
    });
  }

  /// Mengosongkan form. Variabel state ikut dikosongkan karena `reset()`
  /// hanya mengembalikan tampilan field, bukan nilai yang sudah disimpan.
  void _resetForm() {
    _formKey.currentState!.reset();
    _startDateController.clear();
    _endDateController.clear();
    setState(() {
      _title = '';
      _description = '';
      _category = null;
      _thumbnail = '';
      _startDate = null;
      _endDate = null;
      _isOngoing = false;
    });
  }

  void _setOngoing(bool value) {
    setState(() {
      _isOngoing = value;
      if (value) {
        _endDate = null;
        _endDateController.clear();
      }
    });
  }

  /// `true` jika ada isian yang akan hilang saat meninggalkan halaman.
  bool get _hasUnsavedInput =>
      _title.trim().isNotEmpty ||
      _description.trim().isNotEmpty ||
      _category != null ||
      _thumbnail.trim().isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _isOngoing;

  /// Menanyakan konfirmasi jika ada isian. Hasil `true` berarti boleh keluar.
  Future<bool> _confirmLeave() async {
    if (!_hasUnsavedInput) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Isian formulir pengalaman belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return discard ?? false; // menutup dialog di luar tombol = Batal
  }

  /// Tombol Back perangkat/browser saat ada isian: tanya dulu, lalu keluar.
  Future<void> _handleBack(bool didPop, Object? _) async {
    if (didPop || !await _confirmLeave()) return;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Formulir dibuka dari drawer sehingga menjadi halaman paling bawah.
      SystemNavigator.pop();
    }
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field tidak boleh kosong!';
    }
    return null;
  }

  String? _validateThumbnail(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null; // opsional, sama seperti di model
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid
        ? null
        : 'Masukkan URL yang valid (diawali http:// atau https://)';
  }

  String? _validateEndDate(String? _) {
    if (_isOngoing) return null;
    if (_endDate == null) {
      return 'Pilih tanggal selesai atau aktifkan "Masih berlangsung"!';
    }
    if (_startDate != null &&
        _startDate != null &&
        _endDate!.isBefore(_startDate!)) {
      return 'Tanggal selesai tidak boleh sebelum tanggal mulai!';
    }
    return null;
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
    );
  }

  void _showSummary() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pengalaman berhasil disimpan!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Judul: ${_title.trim()}'),
                Text('Deskripsi: ${_description.trim()}'),
                Text('Kategori: $_category'),
                Text(
                  'URL Gambar: ${_thumbnail.trim().isEmpty ? '-' : _thumbnail.trim()}',
                ),
                Text('Tanggal Mulai: ${_formatDate(_startDate!)}'),
                Text(
                  'Tanggal Selesai: ${_isOngoing ? 'Sekarang' : _formatDate(_endDate!)}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedInput,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tambah Pengalaman',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: LeftDrawer(onLeave: _confirmLeave),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Judul ===
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLength: 255, // max_length model Experience.title
                    decoration: _decoration(
                      'Judul Pengalaman',
                      hint: 'Contoh: Deputy of Departemen Keilmuan Mahasiswa',
                    ),
                    onChanged: (value) => setState(() => _title = value),
                    validator: (value) =>
                        _validateRequired(value, 'Judul pengalaman'),
                  ),
                ),
                // === Deskripsi ===
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLines: 5,
                    decoration: _decoration(
                      'Deskripsi Pengalaman',
                      hint: 'Ceritakan pengalamanmu',
                    ),
                    onChanged: (value) => setState(() => _description = value),
                    validator: (value) =>
                        _validateRequired(value, 'Deskripsi pengalaman'),
                  ),
                ),
                // === Kategori ===
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: _decoration('Kategori'),
                    hint: const Text('Pilih kategori'),
                    initialValue: _category,
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _category = value),
                    validator: (value) =>
                        value == null ? 'Kategori wajib dipilih!' : null,
                  ),
                ),
                // === URL Gambar ===
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    keyboardType: TextInputType.url,
                    decoration: _decoration(
                      'URL Gambar (opsional)',
                      hint: 'https://example.com/image.jpg',
                    ),
                    onChanged: (value) => setState(() => _thumbnail = value),
                    validator: _validateThumbnail,
                  ),
                ),
                // === Tanggal Mulai ===
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    decoration: _decoration(
                      'Tanggal Mulai',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () => _pickDate(isStart: true),
                    validator: (_) => _startDate == null
                        ? 'Tanggal mulai wajib dipilih!'
                        : null,
                  ),
                ),
                // === Tanggal Selesai ===
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    enabled: !_isOngoing,
                    decoration: _decoration(
                      'Tanggal Selesai',
                      hint: _isOngoing ? 'Sekarang' : null,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () => _pickDate(isStart: false),
                    validator: _validateEndDate,
                  ),
                ),
                // === Masih Berlangsung ===
                SwitchListTile(
                  title: const Text('Masih berlangsung'),
                  subtitle: const Text('Saya masih menjalani pengalaman ini'),
                  value: _isOngoing,
                  onChanged: _setOngoing,
                ),
                // === Tombol Simpan ===
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showSummary();
                        }
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
