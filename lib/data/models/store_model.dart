class StoreModel {
  final int? id;
  final String namaPemilik;
  final String namaToko;
  final String alamat;
  final double latitude;
  final double longitude;
  final int jumlahTerima;
  final String tanggalTerima;
  final String? fotoToko;
  final String createdAt;

  StoreModel({
    this.id,
    required this.namaPemilik,
    required this.namaToko,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.jumlahTerima,
    required this.tanggalTerima,
    this.fotoToko,
    required this.createdAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      id: map['id'] as int?,
      namaPemilik: map['nama_pemilik'] as String,
      namaToko: map['nama_toko'] as String,
      alamat: map['alamat'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      jumlahTerima: map['jumlah_terima'] as int,
      tanggalTerima: map['tanggal_terima'] as String,
      fotoToko: map['foto_toko'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_pemilik': namaPemilik,
      'nama_toko': namaToko,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'jumlah_terima': jumlahTerima,
      'tanggal_terima': tanggalTerima,
      'foto_toko': fotoToko,
      'created_at': createdAt,
    };
  }

  StoreModel copyWith({
    int? id,
    String? namaPemilik,
    String? namaToko,
    String? alamat,
    double? latitude,
    double? longitude,
    int? jumlahTerima,
    String? tanggalTerima,
    String? fotoToko,
    String? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      namaPemilik: namaPemilik ?? this.namaPemilik,
      namaToko: namaToko ?? this.namaToko,
      alamat: alamat ?? this.alamat,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      jumlahTerima: jumlahTerima ?? this.jumlahTerima,
      tanggalTerima: tanggalTerima ?? this.tanggalTerima,
      fotoToko: fotoToko ?? this.fotoToko,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
