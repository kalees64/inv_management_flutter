import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../procurement/purchase_requests_screen.dart';
import '../inventory/inventory_screen.dart';
import '../sales/sales_dashboard_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../reports/reports_screen.dart';
import 'home_dashboard.dart';
import '../sales/customers_screen.dart';
import '../procurement/suppliers_screen.dart';
import '../auth/profile_screen.dart';
import '../billing/quotations_list_screen.dart';
import '../billing/invoices_list_screen.dart';
import '../inventory/categories_screen.dart';
import '../billing/receipts_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // This would typically come from a role-based structure
  final List<String> _titles = [
    'Dashboard',
    'Inventory',
    'Sales',
    'Quotations',
    'Invoices',
    'Purchases',
    'Customers',
    'Suppliers',
    'Reports',
    'Staff',
    'Categories',
    'Settings',
    'Receipts',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(_titles[_selectedIndex]),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
      drawer: !isDesktop ? _buildSidebar(context) : null,
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 250, child: _buildSidebar(context)),
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _titles[_selectedIndex],
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        // Header Actions (User Profile & Logout)
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                backgroundImage: user.avatar != null
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                child: user.avatar == null
                                    ? Text(
                                        user.name[0],
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: AppColors.error,
                              ),
                              tooltip: 'Logout',
                              onPressed: () {
                                _confirmLogout(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Content Area
                  Expanded(
                    child: _selectedIndex == 0
                        ? const HomeDashboard()
                        : _selectedIndex == 1
                        ? const InventoryScreen()
                        : _selectedIndex == 2
                        ? const SalesDashboardScreen()
                        : _selectedIndex == 3
                        ? const QuotationsListScreen() // New
                        : _selectedIndex == 4
                        ? const InvoicesListScreen() // New
                        : _selectedIndex == 5
                        ? const PurchaseRequestsScreen()
                        : _selectedIndex == 6
                        ? const CustomersScreen()
                        : _selectedIndex == 7
                        ? const SuppliersScreen()
                        : _selectedIndex == 8
                        ? const ReportsScreen()
                        : _selectedIndex == 9
                        ? const StaffDashboardScreen()
                        : _selectedIndex == 10
                        ? const CategoriesScreen()
                        : _selectedIndex == 12
                        ? const ReceiptsListScreen()
                        : Center(
                            child: Text(
                              'Content for ${_titles[_selectedIndex]}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Container(
      color: AppColors.sidebarBackground, // Updated Color
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.sidebarMenuHighlight),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Custom ERP',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // User Info Removed from Sidebar as per request
          const SizedBox(height: 20),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(0, 'Dashboard', Icons.dashboard_outlined),
                if (user?.role == 'admin' || user?.role == 'foreman')
                  _buildMenuItem(1, 'Inventory', Icons.inventory_2_outlined),
                if (user?.role == 'admin' || user?.role == 'sales') ...[
                  _buildMenuItem(2, 'Sales', Icons.point_of_sale_outlined),
                  _buildMenuItem(
                    3,
                    'Quotations',
                    Icons.description_outlined,
                  ), // New
                  _buildMenuItem(
                    4,
                    'Invoices',
                    Icons.receipt_long_outlined,
                  ), // New
                ],
                if (user?.role == 'admin' ||
                    user?.role == 'supervisor' ||
                    user?.role == 'foreman')
                  _buildMenuItem(5, 'Purchases', Icons.shopping_bag_outlined),
                _buildMenuItem(6, 'Customers', Icons.people_outline),
                _buildMenuItem(7, 'Suppliers', Icons.local_shipping_outlined),
                _buildMenuItem(8, 'Reports', Icons.bar_chart_outlined),
                if (user?.role == 'admin')
                  _buildMenuItem(9, 'Staff', Icons.badge_outlined),
                _buildMenuItem(10, 'Categories', Icons.category_outlined),
                if (user?.role == 'admin' || user?.role == 'sales')
                  _buildMenuItem(12, 'Receipts', Icons.receipt_outlined),
                const Divider(color: AppColors.sidebarMenuHighlight),
                _buildMenuItem(11, 'Settings', Icons.settings_outlined),
                const Divider(color: AppColors.sidebarMenuHighlight),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.poppins(color: AppColors.error),
                  ),
                  onTap: () {
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.sidebarMenuColor,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.white : AppColors.sidebarMenuColor,
        ),
      ),
      selected: isSelected,
      tileColor: isSelected
          ? AppColors.sidebarMenuHighlight
          : null, // Highlight background
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (!MediaQuery.of(
          context,
        ).size.width.clamp(800, double.infinity).isFinite) {
          // Close drawer on mobile
          Navigator.pop(context);
        }
      },
    );
  }
}
