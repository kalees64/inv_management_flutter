import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../data/models/sales_model.dart';

class ReportsProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  double _totalSales = 0.0;
  double _totalPurchases = 0.0;
  int _totalOrders = 0;
  List<SalesModel> _recentSales = [];
  bool _isLoading = false;

  double get totalSales => _totalSales;
  double get totalPurchases => _totalPurchases;
  int get totalOrders => _totalOrders;
  List<SalesModel> get recentSales => _recentSales;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch Sales
      final salesResponse = await _dio.get('/sales');
      final List salesData = salesResponse.data;
      final sales = salesData.map((e) => SalesModel.fromJson(e)).toList();

      _totalSales = sales.fold(0, (sum, item) => sum + item.totalAmount);
      _totalOrders = sales.length;
      _recentSales = sales.take(5).toList();

      // Fetch Purchases (Mocked calculation from Purchase Requests for now)
      // In real scenario, we'd check confirmed Invoice amounts.
      _totalPurchases = 5000.0; // Mock
    } catch (e) {
      print('Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
