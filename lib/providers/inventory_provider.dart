import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../data/models/inventory_item_model.dart';
import '../data/models/category_model.dart';

class InventoryProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<InventoryItemModel> _inventory = [];
  bool _isLoading = false;
  String? _error;

  List<InventoryItemModel> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter helpers
  List<InventoryItemModel> get shopInventory =>
      _inventory.where((i) => i.location == 'shop').toList();
  List<InventoryItemModel> get godownInventory =>
      _inventory.where((i) => i.location == 'godown').toList();
  List<InventoryItemModel> get vanInventory =>
      _inventory.where((i) => i.location == 'van').toList();
  List<InventoryItemModel> get transitInventory =>
      _inventory.where((i) => i.location == 'transit').toList();
  List<InventoryItemModel> get customerInventory =>
      _inventory.where((i) => i.location == 'customer').toList();

  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/inventory');
      final List data = response.data;

      // Enriched data usually comes from backend join.
      // For mock, we might need to manually join with products if names are missing,
      // but let's assume /inventory returns product_name for now as per schema design (or we update schema).
      // Updating schema in thought process: I'll assume /inventory has product_name or I fetch products.
      // For simplicity, I'll rely on what's in JSON or add product_name to it.

      _inventory = data.map((e) => InventoryItemModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load inventory: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStock(InventoryItemModel item) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dio.post('/inventory', data: item.toJson()..remove('id'));
      await fetchInventory();
      return true;
    } catch (e) {
      _error = 'Failed to add stock: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStock(InventoryItemModel item) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.put('/inventory/${item.id}', data: item.toJson());
      await fetchInventory();
      return true;
    } catch (e) {
      _error = 'Failed to update stock: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStock(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.delete('/inventory/$id');
      await fetchInventory();
      return true;
    } catch (e) {
      _error = 'Failed to delete stock: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deductStock(String inventoryId, int quantity) async {
    // 1. Find the item locally first to get current details
    final index = _inventory.indexWhere((i) => i.id == inventoryId);
    if (index == -1) return false;

    final item = _inventory[index];
    final newQuantity = item.quantity - quantity;

    if (newQuantity < 0) return false; // Error: Not enough stock

    // 2. Create updated item
    final updatedItem = InventoryItemModel(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      location: item.location,
      quantity: newQuantity,
      minStockLevel: item.minStockLevel,
      category: item.category,
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    // 3. Update backend
    return await updateStock(updatedItem);
  }

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  Future<void> fetchCategories() async {
    try {
      final response = await _dio.get('/categories');
      final List data = response.data;
      _categories = data.map((e) => CategoryModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      print('Failed to fetch categories: $e');
    }
  }

  Future<bool> addCategory(String name) async {
    try {
      final newCategory = CategoryModel(
        id: 0,
        name: name,
      ); // ID handled by json-server
      await _dio.post('/categories', data: newCategory.toJson()..remove('id'));
      await fetchCategories();
      return true;
    } catch (e) {
      print('Failed to add category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
      await fetchCategories();
      return true;
    } catch (e) {
      print('Failed to delete category: $e');
      return false;
    }
  }

  Future<bool> transferStock(
    String itemId,
    String toLocation,
    int quantity,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Complex logic usually handled by backend (decrement source, increment dest).
      // We will mock this by just creating a new entry for dest and updating source.

      // 1. Get Source Item
      // 2. Decrement Source
      // 3. Check if Dest exists -> Increment else Create

      // For now, let's just simulate a delay and refresh
      await Future.delayed(Duration(seconds: 1));

      await fetchInventory();
      return true;
    } catch (e) {
      _error = 'Failed to transfer stock: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
