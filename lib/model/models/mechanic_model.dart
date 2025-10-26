import 'package:cloud_firestore/cloud_firestore.dart';

class Mechanic {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String about;
  final String email;
  final String role;

  /// رابط الصورة (قد يكون null أو فاضي)
  final String? photoUrl;

  Mechanic({
    required this.role,
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.about,
    required this.email,
    this.photoUrl,
  });

  factory Mechanic.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Mechanic(
      role    : d['role']     ?? '',
      id      : doc.id,
      name    : d['name']     ?? '',
      address : d['address']  ?? '',
      phone   : d['phone']    ?? '',
      about   : d['about']    ?? '',
      email   : d['email']    ?? '',
      photoUrl: (d['photoUrl']?.toString().trim().isEmpty ?? true)
          ? null
          : d['photoUrl'].toString().trim(),
    );
  }
}
