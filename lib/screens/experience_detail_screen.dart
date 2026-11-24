import 'package:material_ui/material_ui.dart';
import 'package:myportofolio_mobile/models/experience.dart';

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

class ExperienceDetailScreen extends StatelessWidget {
  const ExperienceDetailScreen({super.key, required this.experience});

  final Experience experience;

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
