import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/repositories/survey_repository.dart';
import '../../widgets/network_status_chip.dart';
import '../about/about_screen.dart';
import '../stores/daftar_toko_screen.dart';
import '../stores/form_toko_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storeRepo = StoreRepository();
  final _surveyRepo = SurveyRepository();

  String _namaPetugas = '';
  int _totalToko = 0;
  int _totalKunjunganBulanIni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final totalToko = await _storeRepo.count();
    final totalKunjungan = await _surveyRepo.countThisMonth();
    if (!mounted) return;
    setState(() {
      _namaPetugas = prefs.getString(AppConstants.keyLoggedInNama) ?? '';
      _totalToko = totalToko;
      _totalKunjunganBulanIni = totalKunjungan;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Produk'),
        actions: [
          const NetworkStatusChip(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Salam ─────────────────────────────────────
            const Text(
              'Selamat datang,',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            Text(
              _namaPetugas,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            Text(
              DateFormatter.toLongDisplay(DateFormatter.todayDb()),
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // ── Ringkasan Statistik ────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.store,
                    label: 'Total Toko',
                    value: _isLoading ? '...' : '$_totalToko',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.assignment_turned_in,
                    label: 'Kunjungan\nBulan Ini',
                    value: _isLoading ? '...' : '$_totalKunjunganBulanIni',
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Tombol Aksi ───────────────────────────────
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.store_mall_directory_outlined,
              label: 'Lihat Daftar Toko',
              subtitle: 'Cari & kelola data toko klien',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarTokoScreen()),
                );
                _loadData();
              },
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.add_business_outlined,
              label: 'Tambah Toko Baru',
              subtitle: 'Daftarkan toko klien baru',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormTokoScreen()),
                );
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
