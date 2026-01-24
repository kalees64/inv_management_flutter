import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../data/models/billing_models.dart';

class BillingProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<QuotationModel> _quotations = [];
  List<InvoiceModel> _invoices = [];
  List<ReceiptModel> _receipts = [];

  bool _isLoading = false;
  String? _error;

  List<QuotationModel> get quotations => _quotations;
  List<InvoiceModel> get invoices => _invoices;
  List<ReceiptModel> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Dashboard Metrics
  double get totalInvoiced =>
      _invoices.fold(0, (sum, i) => sum + i.totalAmount);
  double get totalPaid => _invoices.fold(0, (sum, i) => sum + i.paidAmount);
  double get totalPending => totalInvoiced - totalPaid;

  List<InvoiceModel> get overdueInvoices {
    final now = DateTime.now();
    return _invoices.where((i) {
      if (i.status == 'paid') return false;
      try {
        final due = DateTime.parse(i.dueDate);
        return due.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<InvoiceModel> get recentInvoices {
    final sorted = List<InvoiceModel>.from(_invoices);
    // Sort by ID is not reliable if strings are random. Sort by Date/ID hybrid if possible.
    // For now, descending sort of parsed ID if possible, else just by date if we had one (we have date).
    // Let's sort by dateDescending.
    sorted.sort((a, b) {
      try {
        return b.date.compareTo(a.date);
      } catch (e) {
        return 0; // fallback
      }
    });

    return sorted.take(5).toList();
  }

  // --- QUOTATIONS ---

  Future<void> fetchQuotations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/quotations');
      final List data = response.data;
      _quotations = data.map((e) => QuotationModel.fromJson(e)).toList();
    } catch (e) {
      print('Fetch quotations error: $e'); // Log locally
      _error = 'Failed to load quotations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuotation(QuotationModel quote) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.post('/quotations', data: quote.toJson()..remove('id'));
      await fetchQuotations();
      return true;
    } catch (e) {
      _error = 'Failed to create quotation: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createRevision(QuotationModel newQuote) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Logic: The UI has already prepared the 'newQuote' with revisionNumber + 1
      // and originalQuoteId set. We just need to post it.
      // Ideally backend handles numbering, but for json-server we do it manually in UI or here.
      // Since UI passes newQuote, let's assume it's ready.

      await _dio.post('/quotations', data: newQuote.toJson()..remove('id'));
      await fetchQuotations();
      return true;
    } catch (e) {
      _error = 'Failed to create revision: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteQuotation(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.delete('/quotations/$id');
      await fetchQuotations();
      return true;
    } catch (e) {
      _error = 'Failed to delete quotation: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuotationStatus(String id, String status) async {
    // Only allow update if not confirmed? Or usually we just update status.
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.patch('/quotations/$id', data: {'status': status});
      await fetchQuotations();
      return true;
    } catch (e) {
      _error = 'Failed to update quotation status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mock Email Send
  Future<void> sendQuotationEmail(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    // In real app, call backend endpoint
    // await _dio.post('/quotations/$id/email');
    await updateQuotationStatus(id, 'sent');
  }

  // --- INVOICES ---

  Future<void> fetchInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/invoices');
      final List data = response.data;
      _invoices = data.map((e) => InvoiceModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load invoices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> convertQuoteToInvoice(QuotationModel quote) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Create Invoice
      final invoice = InvoiceModel(
        id: '0',
        quotationId: quote.id,
        customerId: quote.customerId,
        customerName: quote.customerName,
        date: DateTime.now().toString().split(' ')[0],
        dueDate: DateTime.now()
            .add(const Duration(days: 30))
            .toString()
            .split(' ')[0],
        items: quote.items,
        totalAmount: quote.totalAmount,
        paidAmount: 0,
        status: 'unpaid',
      );

      await _dio.post('/invoices', data: invoice.toJson()..remove('id'));

      // 2. Mark Quote as Confirmed/Converted
      await _dio.patch(
        '/quotations/${quote.id}',
        data: {'status': 'converted'},
      );

      await fetchInvoices();
      await fetchQuotations();
      return true;
    } catch (e) {
      _error = 'Failed to convert to invoice: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- PAYMENTS & RECEIPTS ---

  Future<void> fetchReceipts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/receipts');
      final List data = response.data;
      _receipts = data.map((e) => ReceiptModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load receipts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordPayment(
    InvoiceModel invoice,
    double amount,
    String method, {
    String? transactionId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Create Receipt
      final receipt = ReceiptModel(
        id: '0',
        invoiceId: invoice.id,
        amount: amount,
        date: DateTime.now().toString().split(' ')[0],
        paymentMethod: method,
        transactionId: transactionId,
      );
      await _dio.post('/receipts', data: receipt.toJson()..remove('id'));

      // 2. Update Invoice Paid Amount & Status
      final newPaidAmount = invoice.paidAmount + amount;
      // Allow slight precision errors? rounded to 2 decimals
      final isPaid = newPaidAmount >= invoice.totalAmount - 0.01;
      final newStatus = isPaid ? 'paid' : 'partial';

      await _dio.patch(
        '/invoices/${invoice.id}',
        data: {'paid_amount': newPaidAmount, 'status': newStatus},
      );

      await fetchInvoices();
      await fetchReceipts();
      return true;
    } catch (e) {
      _error = 'Failed to record payment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
