import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/store_model.dart';
import '../../data/repositories/store_repository.dart';
import 'detail_toko_screen.dart';
import 'form_toko_screen.dart';

class DaftarTokoScreen extends StatefulWidget {
  const DaftarTokoScreen({super.key});

  @override
  State<DaftarTokoScreen> createState() => _DaftarTokoScreenState();
}

class _DaftarTokoScreenState extends State<DaftarTokoScreen> {
  final _storeRepo = StoreRepository();
  final _searchCtrl = TextEditingController();
  List<StoreModel> _stores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStores({String query = ''}) async {
    setState(() => _isLoading = true);
    final stores = query.isEmpty
        ? await _storeRepo.getAll()
        : await _storeRepo.search(query);
    if (!mounted) return;
    setState(() {
      _stores = stores;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Toko Klien')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormTokoScreen()),
          );
          _loadStores(query: _searchCtrl.text);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama toko atau pemilik...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadStores();
                        },
                      )
                    : null,
              ),
              onChanged: (q) => _loadStores(query: q),
            ),
          ),

          // ── List Toko ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_mall_directory_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              _searchCtrl.text.isEmpty
                                  ? 'Belum ada toko terdaftar'
                                  : 'Toko tidak ditemukan',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadStores(query: _searchCtrl.text),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _stores.length,
                          itemBuilder: (_, i) => _StoreCard(
                            store: _stores[i],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailTokoScreen(store: _stores[i]),
                                ),
                              );
                              _loadStores(query: _searchCtrl.text);
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

class _StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onTap;
  const _StoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.store, color: AppTheme.primary),
        ),
        title: Text(store.namaToko,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${store.namaPemilik} · ${store.alamat}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
