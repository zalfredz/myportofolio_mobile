import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

/// Proyek portofolio yang disinkronkan dengan API Django REST Framework.
///
/// Field mengikuti `ProjectSerializer` di backend (`technology_stack`,
/// `project_url`, `project_image_url`).
@JsonSerializable(fieldRename: FieldRename.snake)
class Project {
  const Project({
    required this.title,
    required this.description,
    required this.technologyStack,
    this.projectUrl = '',
    this.projectImageUrl = '',
    this.id,
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  /// UUID dari server, tidak dikirim saat POST.
  @JsonKey(includeToJson: false)
  final String? id;

  final String title;
  final String description;
  final String technologyStack;

  // Kedua URL boleh `null` di model Django, jadi diberi nilai default.
  @JsonKey(defaultValue: '')
  final String projectUrl;

  @JsonKey(defaultValue: '')
  final String projectImageUrl;

  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}
