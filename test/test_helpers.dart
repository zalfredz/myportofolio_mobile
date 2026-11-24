import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myportofolio_mobile/services/api_client.dart';

/// Backend tiruan untuk tes: tanpa jaringan, meniru respons DRF.
class FakeBackend {
  FakeBackend() {
    client = ApiClient(baseUrl: 'http://test', client: MockClient(_handle));
  }

  late final ApiClient client;

  /// Semua request yang diterima, untuk diperiksa di tes.
  final requests = <http.Request>[];

  /// Pengalaman yang tersimpan; ikut dikembalikan oleh GET.
  final experiences = <Map<String, dynamic>>[];

  /// Status untuk POST experience (mis. 401 untuk token kedaluwarsa).
  int createExperienceStatus = 201;

  static const _categoryLabels = {
    'full-time': 'Full-Time',
    'internship': 'Internship',
    'volunteer': 'Volunteer',
  };

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/api/v1/auth/token/') {
      return http.Response('{"token": "test-token"}', 200);
    }
    if (path == '/api/v1/auth/logout/') return http.Response('', 204);
    if (path == '/api/v1/experiences/' && request.method == 'GET') {
      return http.Response(jsonEncode(experiences), 200);
    }
    if (path == '/api/v1/experiences/' && request.method == 'POST') {
      if (createExperienceStatus != 201) {
        return http.Response('{"detail": "error"}', createExperienceStatus);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final saved = {
        ...body,
        'id': 'id-${experiences.length + 1}',
        'category_display': _categoryLabels[body['category']] ?? '',
        'is_ongoing': body['end_date'] == null,
      };
      experiences.add(saved);
      return http.Response(jsonEncode(saved), 201);
    }
    return http.Response('[]', 200);
  }
}

/// ApiClient untuk tes yang tidak memanggil jaringan, semua daftar kosong.
ApiClient fakeApiClient() => FakeBackend().client;
