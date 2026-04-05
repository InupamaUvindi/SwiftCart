class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isVerifiedSeller;
  final String? storeName;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isVerifiedSeller = false,
    this.storeName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isVerifiedSeller': isVerifiedSeller,
      'storeName': storeName,
      'registeredAt': DateTime.now(),
    };
  }
}