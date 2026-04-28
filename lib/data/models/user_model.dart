class UserModel {
  final int? id;
  final String nama;
  final String username;
  final String password; // SHA-256 hash
  final String createdAt;

  UserModel({
    this.id,
    required this.nama,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'username': username,
      'password': password,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? nama,
    String? username,
    String? password,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
