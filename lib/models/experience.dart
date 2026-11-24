import 'package:json_annotation/json_annotation.dart';

part 'experience.g.dart';

/// Pengalaman portofolio yang disinkronkan dengan API Django REST Framework.
///
/// Field mengikuti `ExperienceSerializer` di backend. `category` berisi nilai
/// API (`full-time`, `internship`, `volunteer`), sedangkan label tampilannya
/// ada di `categoryDisplay`.
@JsonSerializable(fieldRename: FieldRename.snake)
class Experience {
  const Experience({
    required this.title,
    required this.description,
    required this.category,
    this.thumbnail = '',
    this.startDate,
    this.endDate,
    this.id,
    this.categoryDisplay = '',
    this.isOngoing = false,
  });

  factory Experience.fromJson(Map<String, dynamic> json) =>
      _$ExperienceFromJson(json);

  /// UUID dari server, tidak dikirim saat POST.
  @JsonKey(includeToJson: false)
  final String? id;

  final String title;
  final String description;
  final String category;

  /// URL gambar, boleh `null` di model Django.
  @JsonKey(defaultValue: '')
  final String thumbnail;

  @_DateOnlyConverter()
  final DateTime? startDate;

  /// `null` berarti pengalaman masih berlangsung.
  @_DateOnlyConverter()
  final DateTime? endDate;

  /// Label kategori dari server (read-only).
  @JsonKey(includeToJson: false, defaultValue: '')
  final String categoryDisplay;

  /// Dihitung server dari `end_date` kosong (read-only).
  @JsonKey(includeToJson: false, defaultValue: false)
  final bool isOngoing;

  Map<String, dynamic> toJson() => _$ExperienceToJson(this);
}

/// `DateField` DRF hanya menerima `YYYY-MM-DD`, bukan format ISO lengkap
/// (`2026-11-24T00:00:00.000`) yang dihasilkan `DateTime` secara default.
class _DateOnlyConverter implements JsonConverter<DateTime?, String?> {
  const _DateOnlyConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null ? null : DateTime.parse(json);

  @override
  String? toJson(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
