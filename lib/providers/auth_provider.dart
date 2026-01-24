import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../core/network/dio_client.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _token;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  final Dio _dio = DioClient().dio;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock Login: Fetch users from json-server and find match
      // In real backend, this would be a POST /login request
      final response = await _dio.get('/users');
      final List users = response.data;

      final userMap = users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => null,
      );

      if (userMap != null) {
        _user = UserModel.fromJson(userMap);
        // Mock Token
        _token = 'mock_jwt_token_${_user!.id}';

        await _saveUserSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsAdmin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get('/users');
      final List users = response.data;

      // Find first admin
      final adminMap = users.firstWhere(
        (u) => u['role'] == 'admin',
        orElse: () => null,
      );

      if (adminMap != null) {
        _user = UserModel.fromJson(adminMap);
        _token = 'mock_jwt_token_${_user!.id}_admin';
        await _saveUserSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Fallback: Just login as the first user if no admin found (for safety in dev)
        if (users.isNotEmpty) {
          _user = UserModel.fromJson(users.first);
          _token = 'mock_jwt_token_${_user!.id}_fallback';
          await _saveUserSession();
          _isLoading = false;
          notifyListeners();
          return true;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Admin Login Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsSupervisor() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get('/users');
      final List users = response.data;

      // Find first supervisor (assuming role 'supervisor' or 'foreman' who acts as supervisor)
      // Based on previous context, 'foreman' might trigger Inventory, but let's check if we have 'supervisor' role.
      // If not, we might need to add it or use 'foreman' if that's the intended supervisor.
      // The user request says "Supervisor approve", so let's look for 'supervisor' first, else 'foreman'.

      final supervisorMap = users.firstWhere(
        (u) => u['role'] == 'supervisor',
        orElse: () =>
            users.firstWhere((u) => u['role'] == 'foreman', orElse: () => null),
      );

      if (supervisorMap != null) {
        _user = UserModel.fromJson(supervisorMap);
        _token = 'mock_jwt_token_${_user!.id}_supervisor';
        await _saveUserSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Supervisor Login Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);
    final userJson = prefs.getString(AppConstants.keyUser);

    if (token != null && userJson != null) {
      _token = token;
      _user = UserModel.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<void> _saveUserSession() async {
    if (_user == null || _token == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUser, jsonEncode(_user!.toJson()));
  }

  Future<bool> updateProfile(String name, String? password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mock Update: In real app, this would be a PUT /users/:id request
      if (_user != null) {
        // Update local object
        // Note: Password handling should be secure in real app
        final updatedUser = UserModel(
          id: _user!.id,
          name: name,
          email: _user!.email,
          role: _user!.role,
          avatar: _user!.avatar,
          password: password ?? _user!.password, // Keep old password if null
        );

        _user = updatedUser;
        await _saveUserSession();

        // Simulate API delay
        await Future.delayed(const Duration(milliseconds: 500));

        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
