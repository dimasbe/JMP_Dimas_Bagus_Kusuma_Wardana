import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/store_model.dart';
import '../../data/models/survey_record_model.dart';
import '../../data/repositories/survey_repository.dart';

class FormSurveiScreen extends StatefulWidget {
  final StoreModel store;
  const FormSurveiScreen({super.key, required this.store});

  @override
  State<FormSurveiScreen> createState() => _FormSurveiScreenState();
}

class _FormSurveiScreenState extends State<FormSurveiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surveyRepo = SurveyRepository();
  final _jumlahCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  DateTime _tanggalSurvei = DateTime.now();
  String? _fotoBuktiPath;
  bool _isSaving = false;
  int _userId = 0;
  String _namaPetugas = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt(AppConstants.keyLoggedInUserId) ?? 0;
      _namaPetugas = prefs.getString(AppConstants.keyLoggedInNama) ?? '';
    });
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _ambilFotoBukti() async {
    final status = await ph.Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        final buka = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Izin Kamera Diblokir'),
            content: const Text(
                'Izin kamera diblokir permanen. '
                'Buka pengaturan aplikasi untuk mengaktifkannya?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Buka Pengaturan')),
            ],
          ),
        );
        if (buka == true) await ph.openAppSettings();
      }
      return;
    }
    if (!status.isGranted) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera, // ← sensor kamera aktif (Unit 022)
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() => _fotoBuktiPath = image.path);
    }
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalSurvei,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggalSurvei = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoBuktiPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Foto bukti wajib diambil'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final record = SurveyRecordModel(
        storeId: widget.store.id!,
        userId: _userId,
        jumlahSaatIni: int.parse(_jumlahCtrl.text),
        tanggalSurvei: DateFormatter.toDb(_tanggalSurvei),
        fotoBukti: _fotoBuktiPath!,
        catatan: _catatanCtrl.text.isEmpty ? null : _catatanCtrl.text.trim(),
        createdAt: DateFormatter.nowIso(),
      );
      await _surveyRepo.insert(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Survei berhasil disimpan'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Survei'),
            Text(widget.store.namaToko,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info Toko (readonly) ────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.store.namaToko,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.store.alamat,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    Text('Stok awal: ${widget.store.jumlahTerima} pcs',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Data Survei ───────────────────────────
              TextFormField(
                controller: _jumlahCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok Saat Ini',
                  suffixText: 'pcs',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(v) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                title: const Text('Tanggal Survei'),
                subtitle: Text(DateFormatter.toDisplay(
                    DateFormatter.toDb(_tanggalSurvei))),
                onTap: _pilihTanggal,
                trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _catatanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Kondisi barang, keterangan lainnya...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, color: AppTheme.primary),
                title: const Text('Petugas'),
                subtitle: Text(_namaPetugas),
              ),
              const SizedBox(height: 20),

              // ── Foto Bukti (WAJIB) ────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _fotoBuktiPath == null
                        ? AppTheme.error.withValues(alpha: 0.5)
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.camera_alt, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        const Text('Foto Bukti',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('WAJIB',
                              style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_fotoBuktiPath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_fotoBuktiPath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(_fotoBuktiPath != null
                            ? 'Ambil Ulang Foto'
                            : 'Ambil Foto Bukti'),
                        onPressed: _ambilFotoBukti,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Simpan ────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _simpan,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label:
                      Text(_isSaving ? 'Menyimpan...' : 'SIMPAN SURVEI'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
