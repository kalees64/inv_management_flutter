class SupplierModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final double rating;

  SupplierModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.rating,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      rating: (json['rating'] is String)
          ? double.tryParse(json['rating']) ?? 5.0
          : (json['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'rating': rating,
    };
  }
}
