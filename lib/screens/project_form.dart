import 'package:material_ui/material_ui.dart';
import 'package:myportofolio_mobile/models/project.dart';
import 'package:myportofolio_mobile/services/api_client.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';
import 'package:myportofolio_mobile/widgets/auth_guard.dart';
import 'package:myportofolio_mobile/widgets/left_drawer.dart';
import 'package:provider/provider.dart';

/// Formulir tambah proyek. Field mengikuti `ProjectSerializer` di Django.
class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _technologyStack = '';
  String _projectUrl = '';
  String _projectImageUrl = '';
  bool _isSubmitting = false;

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field tidak boleh kosong!';
    }
    return null;
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _validateUrl(String? value, {required bool required}) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return required ? 'Project URL tidak boleh kosong!' : null;
    return _isValidUrl(url)
        ? null
        : 'Masukkan URL yang valid (diawali http:// atau https://)';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Mengosongkan form dan nilai yang tersimpan di state.
  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _title = '';
      _description = '';
      _technologyStack = '';
      _projectUrl = '';
      _projectImageUrl = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;

    final auth = context.read<AuthState>();
    final api = context.read<ApiClient>();
    setState(() {
      _isSubmitting = true;
    });
    Project? created;
    ApiException? apiError;
    try {
      created = await api.createProject(
        Project(
          title: _title.trim(),
          description: _description.trim(),
          technologyStack: _technologyStack.trim(),
          projectUrl: _projectUrl.trim(),
          projectImageUrl: _projectImageUrl.trim(),
        ),
        token: auth.token!,
      );
    } on ApiException catch (e) {
      apiError = e;
    } catch (_) {
      if (mounted) _showSnackBar('Tidak dapat terhubung ke server.');
    } finally {
      // Hentikan loading sebelum dialog/login tampil.
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
    if (!mounted) return;

    if (created != null) {
      await _showSuccessDialog(created);
      if (mounted) _resetForm();
    } else if (apiError?.statusCode == 401) {
      // Token sudah tidak berlaku di server: hapus sesi lalu minta login.
      await auth.logout();
      if (!mounted) return;
      _showSnackBar('Sesi berakhir, silakan login kembali.');
      await ensureLoggedIn(context);
    } else if (apiError != null) {
      _showSnackBar('Gagal menyimpan proyek (status ${apiError.statusCode}).');
    }
  }

  Future<void> _showSuccessDialog(Project project) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proyek berhasil ditambahkan!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Judul: ${project.title}'),
                Text('Deskripsi: ${project.description}'),
                Text('Tech Stack: ${project.technologyStack}'),
                Text('Project URL: ${project.projectUrl}'),
                Text(
                  'Image URL: '
                  '${project.projectImageUrl.isEmpty ? '-' : project.projectImageUrl}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      hintText: hint ?? label,
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Add Project Form')),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Title ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLength: 255, // max_length Project.title
                  decoration: _decoration('Title'),
                  onChanged: (value) => setState(() => _title = value),
                  validator: (value) => _validateRequired(value, 'Title'),
                ),
              ),
              // === Description ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLines: 5,
                  decoration: _decoration('Description'),
                  onChanged: (value) => setState(() => _description = value),
                  validator: (value) => _validateRequired(value, 'Description'),
                ),
              ),
              // === Tech Stack ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: _decoration(
                    'Tech Stack',
                    hint: 'Contoh: Flutter, Django, Figma',
                  ),
                  onChanged: (value) =>
                      setState(() => _technologyStack = value),
                  validator: (value) => _validateRequired(value, 'Tech Stack'),
                ),
              ),
              // === Project URL ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.url,
                  decoration: _decoration(
                    'Project URL',
                    hint: 'https://github.com/username/proyek',
                  ),
                  onChanged: (value) => setState(() => _projectUrl = value),
                  validator: (value) => _validateUrl(value, required: true),
                ),
              ),
              // === Project Image URL ===
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.url,
                  maxLength: 500, // max_length Project.project_image_url
                  decoration: _decoration(
                    'Project Image URL (Optional)',
                    hint: 'https://example.com/image.jpg',
                  ),
                  onChanged: (value) =>
                      setState(() => _projectImageUrl = value),
                  validator: (value) => _validateUrl(value, required: false),
                ),
              ),
              // === Tombol Simpan ===
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.indigo),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
