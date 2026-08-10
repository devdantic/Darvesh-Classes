class StudentRequestModel {
  final String name;
  final String email;
  final String phone;
  final String address;
  final int standard;
  final String? imageUrl;

  StudentRequestModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.standard,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'standard': standard,
      'image_url': imageUrl,
    };
  }
}