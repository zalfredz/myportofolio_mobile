import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myportofolio_mobile/services/api_client.dart';

/// ApiClient untuk tes: tidak memanggil jaringan, semua daftar kosong.
ApiClient fakeApiClient() => ApiClient(
  client: MockClient((request) async => http.Response('[]', 200)),
  baseUrl: 'http://test',
);
