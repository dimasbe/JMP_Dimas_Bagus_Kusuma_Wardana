import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/survey_record_model.dart';
import '../../data/repositories/survey_repository.dart';
import '../stores/detail_toko_screen.dart';
import '../../data/repositories/store_repository.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with AutomaticKeepAliveClientMixin {  // ← tambah ini

  final _surveyRepo = SurveyRepository();
  final _storeRepo = StoreRepository();
  final _searchCtrl = TextEditingController();

  List<SurveyRecordModel> _allRiwayat = [];
  List<SurveyRecordModel> _filteredRiwayat = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => false; // ← false = selalu reload saat buka tab

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    final riwayat = await _surveyRepo.getAll();
    if (!mounted) return;
    setState(() {
      _allRiwayat = riwayat;
      _filteredRiwayat = riwayat;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRiwayat = _allRiwayat;
      } else {
        _filteredRiwayat = _allRiwayat
            .where((r) =>
        (r.namaToko ?? '')
            .toLowerCase()
            .contains(query.toLowerCase()) ||
            (r.namaPetugas ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← tambah ini
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Survei'),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama toko atau petugas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search('');
                  },
                )
                    : null,
              ),
              onChanged: _search,
            ),
          ),

          // ── Total Riwayat ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Semua Riwayat Kunjungan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_filteredRiwayat.length} data',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── List Riwayat ──────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRiwayat.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    _searchCtrl.text.isEmpty
                        ? 'Belum ada riwayat survei'
                        : 'Data tidak ditemukan',
                    style: const TextStyle(
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadRiwayat,
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filteredRiwayat.length,
                itemBuilder: (_, i) => _RiwayatCard(
                  survey: _filteredRiwayat[i],
                  onTap: () async {
                    final store = await _storeRepo
                        .getById(_filteredRiwayat[i].storeId);
                    if (store != null && mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetailTokoScreen(store: store),
                        ),
                      );
                      _loadRiwayat();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final SurveyRecordModel survey;
  final VoidCallback onTap;

  const _RiwayatCard({
    required this.survey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.assignment, color: AppTheme.primary),
        ),
        title: Text(
          survey.namaToko ?? '-',
          style:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatter.toDisplay(survey.tanggalSurvei),
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              'Stok: ${survey.jumlahSaatIni} pcs · ${survey.namaPetugas ?? "-"}',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right,
            color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}