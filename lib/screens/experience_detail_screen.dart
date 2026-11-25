import 'package:material_ui/material_ui.dart';
import 'package:myportofolio_mobile/models/experience.dart';
import 'package:myportofolio_mobile/services/api_client.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';
import 'package:myportofolio_mobile/widgets/auth_guard.dart';
import 'package:provider/provider.dart';

/// Format tanggal hari/bulan/tahun, sama dengan formulir pengalaman.
String formatExperienceDate(DateTime? date) =>
    date == null ? '-' : '${date.day}/${date.month}/${date.year}';

/// Rentang waktu pengalaman, misalnya `1/8/2026 - Sekarang`.
String experiencePeriod(Experience experience) {
  final end = experience.isOngoing
      ? 'Sekarang'
      : formatExperienceDate(experience.endDate);
  // start_date opsional di model Django.
  if (experience.startDate == null) {
    return experience.isOngoing ? 'Masih berlangsung' : 'Selesai $end';
  }
  return '${formatExperienceDate(experience.startDate)} - $end';
}

/// Detail pengalaman. Mengembalikan `true` lewat `Navigator.pop` jika
/// pengalaman dihapus, agar daftar menyegarkan isinya.
class ExperienceDetailScreen extends StatefulWidget {
  const ExperienceDetailScreen({super.key, required this.experience});

  final Experience experience;

  @override
  State<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  bool _isDeleting = false;

  Experience get experience => widget.experience;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengalaman?'),
        content: Text(
          '"${experience.title}" akan dihapus permanen dari portofolio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return confirmed ?? false; // menutup dialog di luar tombol = Batal
  }

  /// Menghapus lewat `DELETE /api/v1/experiences/<id>/` dengan token login.
  Future<void> _delete() async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted || !await _confirmDelete()) return;
    if (!mounted) return;

    final auth = context.read<AuthState>();
    final api = context.read<ApiClient>();
    setState(() {
      _isDeleting = true;
    });
    var deleted = false;
    ApiException? apiError;
    try {
      await api.deleteExperience(experience.id!, token: auth.token!);
      deleted = true;
    } on ApiException catch (e) {
      apiError = e;
    } catch (_) {
      if (mounted) _showSnackBar('Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
    if (!mounted) return;

    if (deleted) {
      Navigator.pop(context, true);
    } else if (apiError?.statusCode == 401) {
      // Token sudah tidak berlaku di server: hapus sesi lalu minta login.
      await auth.logout();
      if (!mounted) return;
      _showSnackBar('Sesi berakhir, silakan login kembali.');
      await ensureLoggedIn(context);
    } else if (apiError != null) {
      // 403 berarti akun ini bukan pemilik portofolio.
      _showSnackBar(
        'Gagal menghapus pengalaman (status ${apiError.statusCode}).',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          experience.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _delete,
              tooltip: 'Hapus Pengalaman',
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (experience.thumbnail.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  experience.thumbnail,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Gambar dari situs lain bisa gagal dimuat (mis. CORS di web).
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Gambar tidak dapat dimuat.'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _DetailField(label: 'Judul', value: experience.title),
            _DetailField(
              label: 'Kategori',
              value: experience.categoryDisplay.isEmpty
                  ? experience.category
                  : experience.categoryDisplay,
            ),
            _DetailField(label: 'Deskripsi', value: experience.description),
            _DetailField(
              label: 'Tanggal Mulai',
              value: formatExperienceDate(experience.startDate),
            ),
            _DetailField(
              label: 'Tanggal Selesai',
              value: experience.isOngoing
                  ? 'Sekarang (masih berlangsung)'
                  : formatExperienceDate(experience.endDate),
            ),
            _DetailField(
              label: 'URL Gambar',
              value: experience.thumbnail.isEmpty ? '-' : experience.thumbnail,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
