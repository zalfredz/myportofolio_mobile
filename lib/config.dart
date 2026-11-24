/// Base URL backend Django REST Framework.
///
/// Default `http://10.0.2.2:8000` adalah alamat komputer host jika dipanggil
/// dari emulator Android. Untuk Chrome/Web, timpa dengan
/// `--dart-define=API_BASE_URL=http://localhost:8000`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
