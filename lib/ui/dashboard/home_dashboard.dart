import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_home.dart';
import 'supervisor_dashboard.dart';
import '../../core/constants/app_theme.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const SizedBox.shrink();

    // Route to specific role dashboard
    switch (user.role) {
      case 'admin':
        return const AdminDashboardHome();
      case 'supervisor':
      case 'foreman':
        return const SupervisorDashboard();
      case 'sales':
        // Reuse Sales Dashboard view or specialized view
        return _buildGenericWelcome(
          context,
          'Sales Dashboard',
          Icons.point_of_sale,
        );
      case 'driver':
        return _buildGenericWelcome(
          context,
          'Driver Dashboard',
          Icons.local_shipping,
        );
      default:
        return _buildGenericWelcome(context, 'Welcome', Icons.home);
    }
  }

  Widget _buildGenericWelcome(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'Select an option from the sidebar to get started.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
