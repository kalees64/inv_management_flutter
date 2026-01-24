import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../data/models/attendance_model.dart';
import '../data/models/payroll_model.dart';
import '../data/models/user_model.dart';

class StaffProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  List<UserModel> _staff = []; // Users with role != admin
  List<AttendanceModel> _attendanceRecords = [];
  List<PayrollModel> _payrolls = [];

  bool _isLoading = false;
  String? _error;

  List<UserModel> get staff => _staff;
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<PayrollModel> get payrolls => _payrolls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStaff() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/users');
      final List data = response.data;
      // Filter out admins or maybe show all? Let's show all for now or filter
      _staff = data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load staff: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendance() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/attendance');
      final List data = response.data;
      _attendanceRecords = data
          .map((e) => AttendanceModel.fromJson(e))
          .toList();
    } catch (e) {
      _error = 'Failed to load attendance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAttendance(AttendanceModel record) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dio.post('/attendance', data: record.toJson()..remove('id'));
      await fetchAttendance();
    } catch (e) {
      _error = 'Failed to mark attendance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayroll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/payroll');
      final List data = response.data;
      _payrolls = data.map((e) => PayrollModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load payroll: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Feature: Generate Payroll for a user (Mock)
  Future<bool> generatePayroll(int userId, String month) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Logic to calc salary based on attendance would go here.
      // Mocking a fixed payroll entry
      final payroll = PayrollModel(
        id: 0,
        userId: userId,
        month: month,
        baseSalary: 1000.0,
        allowances: 200.0,
        deductions: 50.0,
        incentives: 100.0,
        netSalary: 1250.0,
        status: 'pending',
      );

      await _dio.post('/payroll', data: payroll.toJson()..remove('id'));
      await fetchPayroll();
      return true;
    } catch (e) {
      _error = 'Failed to generate payroll: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addStaff(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      // In a real app, password should be hashed or handled by a secure auth endpoint
      await _dio.post('/users', data: user.toJson()..remove('id'));
      await fetchStaff();
      return true;
    } catch (e) {
      _error = 'Failed to add staff: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
