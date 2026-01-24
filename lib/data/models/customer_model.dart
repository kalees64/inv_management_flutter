class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final double creditLimit;
  final double currentDebt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.creditLimit,
    required this.currentDebt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'].toString(), // Ensure String
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      creditLimit: (json['credit_limit'] is String)
          ? double.tryParse(json['credit_limit']) ?? 0.0
          : (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentDebt: (json['current_debt'] is String)
          ? double.tryParse(json['current_debt']) ?? 0.0
          : (json['current_debt'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'credit_limit': creditLimit,
      'current_debt': currentDebt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
