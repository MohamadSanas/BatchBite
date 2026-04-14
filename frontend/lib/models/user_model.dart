class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.role,
    required this.isVerifiedSeller,
  });

  final int id;
  final String name;
  final String email;
  final String university;
  final String role;
  final bool isVerifiedSeller;

  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'seller';

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: j['id'] as int,
      name: j['name'] as String,
      email: j['email'] as String,
      university: j['university'] as String,
      role: j['role'] as String,
      isVerifiedSeller: j['is_verified_seller'] as bool,
    );
  }
}
