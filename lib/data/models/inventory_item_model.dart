class InventoryItemModel {
  final String id;
  final int productId;
  final String productName;
  final String location; // 'shop', 'godown', 'van', 'transit'
  final int quantity;
  final int? minStockLevel;
  final String? category;
  final double? costPrice;
  final double? sellingPrice;

  InventoryItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.location,
    required this.quantity,
    this.minStockLevel,
    this.category,
    this.costPrice,
    this.sellingPrice,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'].toString(), // Ensure String
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown Product',
      location: json['location'],
      quantity: json['quantity'],
      minStockLevel: json['min_stock_level'],
      category: json['category'],
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      sellingPrice: (json['selling_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'location': location,
      'quantity': quantity,
      'min_stock_level': minStockLevel,
      'category': category,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
    };
  }
}
