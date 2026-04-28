import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/store_model.dart';
import '../../data/repositories/store_repository.dart';

class FormTokoScreen extends StatefulWidget {
  final StoreModel? store; // null = tambah baru, != null = edit
  const FormTokoScreen({super.key, this.store});

  @override
  State<FormTokoScreen> createState() => _FormTokoScreenState();
}

class _FormTokoScreenState extends State<FormTokoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeRepo = StoreRepository();

  final _pemilikCtrl = TextEditingController();
  final _namaTokoCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();

  DateTime _tanggalTerima = DateTime.now();
  double? _latitude;
  double? _longitude;
  String? _fotoPath;
  bool _isLoadingGps = false;
  bool _isSaving = false;

  bool get _isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.store!;
      _pemilikCtrl.text = s.namaPemilik;
      _namaTokoCtrl.text = s.namaToko;
      _alamatCtrl.text = s.alamat;
      _jumlahCtrl.text = s.jumlahTerima.toString();
      _latitude = s.latitude;
      _longitude = s.longitude;
      _fotoPath = s.fotoToko;
      try {
        _tanggalTerima = DateTime.parse(s.tanggalTerima);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pemilikCtrl.dispose();
    _namaTokoCtrl.dispose();
    _alamatCtrl.dispose();
    _jumlahCtrl.dispose();
    super.dispose();
  }

  Future<void> _ambilGps() async {
    setState(() => _isLoadingGps = true);
    try {
      // 1. Cek apakah layanan GPS aktif di perangkat
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          final buka = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('GPS Belum Aktif'),
              content: const Text(
                  'Layanan lokasi perangkat belum diaktifkan. '
                  'Aktifkan GPS terlebih dahulu?'),
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
          if (buka == true) await Geolocator.openLocationSettings();
        }
        return;
      }

      // 2. Cek dan minta izin lokasi via Geolocator
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      // 3. Izin diblokir permanen → arahkan ke pengaturan aplikasi
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          final buka = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Izin Lokasi Diblokir'),
              content: const Text(
                  'Izin lokasi diblokir permanen. '
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
          if (buka == true) await Geolocator.openAppSettings();
        }
        return;
      }

      // 4. Ambil koordinat GPS
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Koordinat GPS berhasil diambil'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil koordinat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _ambilFoto() async {
    // Minta izin kamera
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
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() => _fotoPath = image.path);
    }
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTerima,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggalTerima = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS belum diambil'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final store = StoreModel(
        id: widget.store?.id,
        namaPemilik: _pemilikCtrl.text.trim(),
        namaToko: _namaTokoCtrl.text.trim(),
        alamat: _alamatCtrl.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        jumlahTerima: int.parse(_jumlahCtrl.text),
        tanggalTerima: DateFormatter.toDb(_tanggalTerima),
        fotoToko: _fotoPath,
        createdAt: widget.store?.createdAt ?? DateFormatter.nowIso(),
      );
      if (_isEdit) {
        await _storeRepo.update(store);
      } else {
        await _storeRepo.insert(store);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Toko' : 'Tambah Toko Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Data Toko ─────────────────────────────────
              const _SectionTitle('Data Toko'),
              TextFormField(
                controller: _pemilikCtrl,
                decoration: const InputDecoration(labelText: 'Nama Pemilik'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _namaTokoCtrl,
                decoration: const InputDecoration(labelText: 'Nama Toko'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alamatCtrl,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Data Distribusi ───────────────────────────
              const _SectionTitle('Data Distribusi'),
              TextFormField(
                controller: _jumlahCtrl,
                decoration: const InputDecoration(
                    labelText: 'Jumlah Produk Diterima', suffixText: 'pcs'),
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
                title: const Text('Tanggal Terima'),
                subtitle: Text(DateFormatter.toDisplay(
                    DateFormatter.toDb(_tanggalTerima))),
                onTap: _pilihTanggal,
                trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
              ),
              const SizedBox(height: 20),

              // ── Lokasi GPS ────────────────────────────────
              const _SectionTitle('Lokasi GPS'),
              if (_latitude != null && _longitude != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_latitude!.toStringAsFixed(6)}\nLng: ${_longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isLoadingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isLoadingGps
                      ? 'Mengambil lokasi...'
                      : (_latitude != null ? 'Perbarui Koordinat GPS' : 'Ambil Koordinat GPS')),
                  onPressed: _isLoadingGps ? null : _ambilGps,
                ),
              ),
              const SizedBox(height: 20),

              // ── Foto Toko ─────────────────────────────────
              const _SectionTitle('Foto Toko (Opsional)'),
              if (_fotoPath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_fotoPath!),
                      height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(_fotoPath != null ? 'Ganti Foto' : 'Ambil Foto Toko'),
                  onPressed: _ambilFoto,
                ),
              ),
              const SizedBox(height: 28),

              // ── Simpan ────────────────────────────────────
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
                  label: Text(_isSaving ? 'Menyimpan...' : 'SIMPAN TOKO'),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
