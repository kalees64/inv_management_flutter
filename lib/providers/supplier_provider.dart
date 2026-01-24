import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../data/models/supplier_model.dart';

class SupplierProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSuppliers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get('/suppliers');
      final List data = response.data;
      _suppliers = data.map((e) => SupplierModel.fromJson(e)).toList();
      log('Suppliers fetched: ${_suppliers.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      log('Error fetching suppliers: $e', error: e, stackTrace: stackTrace);
      _error = 'Failed to load: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(SupplierModel supplier) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dio.post('/suppliers', data: supplier.toJson()..remove('id'));
      await fetchSuppliers();
      return true;
    } catch (e) {
      log('Error adding supplier: $e', error: e);
      _error = 'Failed to add: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(SupplierModel supplier) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.put('/suppliers/${supplier.id}', data: supplier.toJson());
      await fetchSuppliers();
      return true;
    } catch (e) {
      log('Error updating supplier: $e', error: e);
      _error = 'Failed to update: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.delete('/suppliers/$id');
      await fetchSuppliers();
      return true;
    } catch (e) {
      log('Error deleting supplier: $e', error: e);
      _error = 'Failed to delete: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
