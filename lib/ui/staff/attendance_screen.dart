import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/staff_provider.dart';
import '../../data/models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StaffProvider>().fetchStaff();
      context.read<StaffProvider>().fetchAttendance();
    });
  }

  void _markAttendance(int userId, String status) {
    final record = AttendanceModel(
      id: 0,
      userId: userId,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      checkInTime: status == 'present'
          ? DateFormat('HH:mm').format(DateTime.now())
          : null,
      status: status,
    );
    context.read<StaffProvider>().markAttendance(record);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: provider.staff.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final staff = provider.staff[index];
                // Check if already marked for today
                final attendance = provider.attendanceRecords.firstWhere(
                  (a) => a.userId == staff.id && a.date == today,
                  orElse: () =>
                      AttendanceModel(id: -1, userId: -1, date: '', status: ''),
                );

                final isMarked = attendance.id != -1;

                return ListTile(
                  leading: CircleAvatar(child: Text(staff.name[0])),
                  title: Text(staff.name),
                  subtitle: Text(staff.role.toUpperCase()),
                  trailing: isMarked
                      ? Chip(
                          label: Text(attendance.status.toUpperCase()),
                          backgroundColor: attendance.status == 'present'
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.error.withOpacity(0.2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _markAttendance(staff.id, 'present'),
                              child: const Text(
                                'Present',
                                style: TextStyle(color: AppColors.success),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _markAttendance(staff.id, 'absent'),
                              child: const Text(
                                'Absent',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
