import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../data/models/sales_model.dart';
import '../data/models/customer_model.dart';

class SalesProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<SalesModel> _sales = [];
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<SalesModel> get sales => _sales;
  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSales() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/sales');
      final List data = response.data;
      _sales = data.map((e) => SalesModel.fromJson(e)).toList();
    } catch (e) {
      log('Error fetching sales: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/customers');
      final List data = response.data;
      _customers = data.map((e) => CustomerModel.fromJson(e)).toList();
      log('Customers fetched: ${_customers.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      log('Error fetching customers: $e', error: e, stackTrace: stackTrace);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSale(SalesModel sale) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.post('/sales', data: sale.toJson()..remove('id'));
      await fetchSales();
      return true;
    } catch (e) {
      log('Error creating sale: $e', error: e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<CustomerModel?> addCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post(
        '/customers',
        data: customer.toJson()..remove('id'),
      );
      // The server returns the created object with the new ID
      final createdCustomer = CustomerModel.fromJson(response.data);
      await fetchCustomers();
      return createdCustomer;
    } catch (e) {
      log('Error adding customer: $e', error: e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.put('/customers/${customer.id}', data: customer.toJson());
      await fetchCustomers();
      return true;
    } catch (e) {
      log('Error updating customer: $e', error: e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.delete('/customers/$id');
      await fetchCustomers();
      return true;
    } catch (e) {
      log('Error deleting customer: $e', error: e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
