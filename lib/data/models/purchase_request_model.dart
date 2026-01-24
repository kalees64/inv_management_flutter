class PurchaseRequestModel {
  final String id;
  final int requesterId;
  final String date;
  final String status; // pending, approved, rejected
  final List<PurchaseRequestItem> items;
  final String? approvedBy;
  final String? rejectionReason;

  PurchaseRequestModel({
    required this.id,
    required this.requesterId,
    required this.date,
    required this.status,
    required this.items,
    this.approvedBy,
    this.rejectionReason,
  });

  factory PurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestModel(
      id: json['id'].toString(),
      requesterId: json['requester_id'],
      date: json['date'],
      status: json['status'],
      items: (json['items'] as List)
          .map((i) => PurchaseRequestItem.fromJson(i))
          .toList(),
      approvedBy: json['approved_by'],
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'date': date,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
    };
  }
}

class PurchaseRequestItem {
  final int? productId; // null if new product
  final String productName;
  final int quantity;
  final double estimatedPrice;

  PurchaseRequestItem({
    this.productId,
    required this.productName,
    required this.quantity,
    required this.estimatedPrice,
  });

  factory PurchaseRequestItem.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItem(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
    };
  }
}
