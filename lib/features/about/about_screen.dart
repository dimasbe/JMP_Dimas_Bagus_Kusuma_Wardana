import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/login_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '-';
  String _platformName = '-';
  String _osVersion = '-';
  String _namaPetugas = '-';
  String _username = '-';
  String _loginTime = '-';
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final pkgInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String platform = '-';
    String osVer = '-';
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      platform = 'Android';
      osVer = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      platform = 'iOS';
      osVer = '${info.systemName} ${info.systemVersion}';
    }

    final loginTimeRaw = prefs.getString(AppConstants.keyLoginTime) ?? '';
    if (!mounted) return;
    setState(() {
      _appVersion = '${pkgInfo.version}+${pkgInfo.buildNumber}';
      _platformName = platform;
      _osVersion = osVer;
      _namaPetugas = prefs.getString(AppConstants.keyLoggedInNama) ?? '-';
      _username = prefs.getString(AppConstants.keyLoggedInUsername) ?? '-';
      _loginTime = loginTimeRaw.isNotEmpty
          ? DateFormatter.toDisplayDateTime(loginTimeRaw)
          : '-';
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari aplikasi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _gantiPassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.keyLoggedInUserId) ?? 0;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Konfirmasi Password Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok')),
                );
                return;
              }
              // Verifikasi password lama
              final user = await _userRepo.login(_username, oldCtrl.text);
              if (user == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password lama salah')),
                  );
                }
                return;
              }
              await _userRepo.changePassword(userId, newCtrl.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password berhasil diubah'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header App ────────────────────────────────
          Center(
            child: Column(
              children: [
                const Icon(Icons.assignment_turned_in,
                    size: 64, color: AppTheme.primary),
                const SizedBox(height: 8),
                const Text(AppConstants.appName,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Versi $_appVersion',
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Info Platform (Unit 001) ──────────────────
          _InfoSection(
            title: '📱 Info Platform',
            items: [
              _InfoItem(label: 'Platform', value: _platformName),
              _InfoItem(label: 'Versi OS', value: _osVersion),
              const _InfoItem(label: 'Framework', value: 'Flutter (Dart)'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Info Petugas ──────────────────────────────
          _InfoSection(
            title: '👤 Info Petugas',
            items: [
              _InfoItem(label: 'Nama', value: _namaPetugas),
              _InfoItem(label: 'Username', value: _username),
              _InfoItem(label: 'Login Sejak', value: _loginTime),
            ],
          ),
          const SizedBox(height: 24),

          // ── Aksi ──────────────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: const Text('Ganti Password'),
            onPressed: _gantiPassword,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const Divider(),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
