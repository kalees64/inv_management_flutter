class BillingItem {
  final dynamic productId; // Could be String or int
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  BillingItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory BillingItem.fromJson(Map<String, dynamic> json) {
    return BillingItem(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }
}

class QuotationModel {
  final String id;
  final dynamic customerId; // Dynamic to be safe
  final String customerName;
  final String date;
  final List<BillingItem> items;
  final double totalAmount;
  final String status;
  final int revisionNumber;
  final String? originalQuoteId;

  QuotationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.revisionNumber = 0,
    this.originalQuoteId,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'].toString(),
      customerId: json['customer_id'],
      customerName: json['customer_name'] ?? 'Unknown',
      date: json['date'],
      items: (json['items'] as List)
          .map((i) => BillingItem.fromJson(i))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      revisionNumber: json['revision_number'] ?? 0,
      originalQuoteId: json['original_quote_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'date': date,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status,
      'revision_number': revisionNumber,
      'original_quote_id': originalQuoteId,
    };
  }
}

class InvoiceModel {
  final String id;
  final String quotationId;
  final dynamic customerId;
  final String customerName;
  final String date;
  final String dueDate;
  final List<BillingItem> items;
  final double totalAmount;
  final double paidAmount;
  final String status;

  InvoiceModel({
    required this.id,
    required this.quotationId,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'].toString(),
      quotationId: json['quotation_id'].toString(),
      customerId: json['customer_id'],
      customerName: json['customer_name'] ?? 'Unknown',
      date: json['date'],
      dueDate: json['due_date'],
      items: (json['items'] as List)
          .map((i) => BillingItem.fromJson(i))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotation_id': quotationId,
      'customer_id': customerId,
      'customer_name': customerName,
      'date': date,
      'due_date': dueDate,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status,
    };
  }
}

class ReceiptModel {
  final String id;
  final String invoiceId;
  final double amount;
  final String date;
  final String paymentMethod;
  final String? transactionId;

  ReceiptModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.transactionId,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'].toString(),
      invoiceId: json['invoice_id'].toString(),
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'date': date,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
    };
  }
}
