class SalesModel {
  final String id;
  final String customerId;
  final String date;
  final double totalAmount;
  final double paidAmount;
  final String paymentMode; // 'cash', 'credit', 'bank'
  final List<SalesItem> items;

  SalesModel({
    required this.id,
    required this.customerId,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMode,
    required this.items,
  });

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    return SalesModel(
      id: json['id'].toString(),
      customerId: json['customer_id'].toString(),
      date: json['date'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      paymentMode: json['payment_mode'],
      items: (json['items'] as List).map((i) => SalesItem.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'date': date,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_mode': paymentMode,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class SalesItem {
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String? inventoryItemId; // To track exact inventory record

  SalesItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.inventoryItemId,
  });

  factory SalesItem.fromJson(Map<String, dynamic> json) {
    return SalesItem(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      inventoryItemId: json['inventory_item_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'inventory_item_id': inventoryItemId,
    };
  }
}
