import 'package:material_ui/material_ui.dart';
import 'package:myportofolio_mobile/screens/experience_form.dart';
import 'package:myportofolio_mobile/screens/project_form.dart';
import 'package:myportofolio_mobile/screens/project_list_screen.dart';
import 'package:myportofolio_mobile/services/auth_state.dart';
import 'package:myportofolio_mobile/widgets/left_drawer.dart';
import 'package:myportofolio_mobile/widgets/project_card.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  static const String npm = '2506656412';
  static const String nama = 'Alfredo Harsono';
  static const String kelas = 'PBP C';
  // Shade 700/800 dipilih agar teks putih di atasnya tetap kontras (WCAG AA).
  static final List<ItemHomepage> items = [
    ItemHomepage(
      'Lihat Proyek',
      Icons.folder,
      Colors.blue.shade700,
      page: const ProjectListScreen(),
    ),
    ItemHomepage(
      'Tambah Proyek',
      Icons.add_circle,
      Colors.green.shade800,
      page: const ProjectFormPage(),
      requiresLogin: true,
    ),
    ItemHomepage(
      'Tambah Pengalaman',
      Icons.work,
      Colors.purple.shade700,
      page: const ExperienceFormPage(),
    ),
    ItemHomepage('Logout', Icons.logout, Colors.red.shade700, action: _logout),
  ];

  static Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthState>();
    if (!auth.isLoggedIn) return;
    final messenger = ScaffoldMessenger.of(context);
    await auth.logout();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Berhasil logout.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyPortfolio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Row(
              children: [
                Expanded(
                  child: InfoCard(title: 'NPM', content: npm),
                ),
                Expanded(
                  child: InfoCard(title: 'Name', content: nama),
                ),
                Expanded(
                  child: InfoCard(title: 'Class', content: kelas),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Selamat datang di MyPortfolio Mobile!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            GridView.count(
              primary: false,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // 2 kolom: 4 kartu tersusun 2x2 dan label panjang seperti
              // "Tambah Pengalaman" tetap muat di layar sempit (320-360).
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              children: items.map((item) => ItemCard(item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ItemHomepage {
  const ItemHomepage(
    this.name,
    this.icon,
    this.color, {
    this.page,
    this.requiresLogin = false,
    this.action,
  });

  final String name;
  final IconData icon;
  final Color color;

  /// Halaman yang dibuka dengan `Navigator.push()` saat kartu ditekan.
  /// `null` berarti kartu hanya menampilkan SnackBar.
  final Widget? page;

  /// Jika `true`, pengguna harus login sebelum [page] dibuka.
  final bool requiresLogin;

  /// Aksi khusus yang dijalankan setelah SnackBar, misalnya logout.
  final Future<void> Function(BuildContext context)? action;
}
