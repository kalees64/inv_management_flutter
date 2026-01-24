import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/sales_provider.dart';
import '../../data/models/customer_model.dart';
import 'sales_entry_screen.dart';
import 'customers_screen.dart';
import 'sales_details_screen.dart';
import 'sales_history_screen.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  // State for search/filter/pagination
  // String _searchQuery = ''; // Moved to History Screen
  // bool _sortAscending = false; // Moved to History Screen
  // int _currentPage = 1;
  // static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SalesProvider>().fetchSales();
      context.read<SalesProvider>().fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final sales = salesProvider.sales;
    final customers = salesProvider.customers;

    // Simple calculations for demo
    final double totalSales = sales.fold(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final int totalTransactions = sales.length;

    // Filter Logic Removed (Moved to SalesHistoryScreen)
    // We just show raw recent items here.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),

            // Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Revenue',
                    '\$${totalSales.toStringAsFixed(2)}',
                    Icons.attach_money,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Transactions',
                    '$totalTransactions',
                    Icons.receipt_long,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Active Customers',
                    '${salesProvider.customers.length}',
                    Icons.people,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionCard(
                  context,
                  'New Sale',
                  'Record a new transaction',
                  Icons.point_of_sale,
                  AppColors.primary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesEntryScreen()),
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  context,
                  'Customers',
                  'Manage customer database',
                  Icons.people_outline,
                  AppColors.secondary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  context,
                  'Sales History',
                  'View past transactions',
                  Icons.history,
                  AppColors.textSecondary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Recent Transactions Table (Top 5 only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: salesProvider.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.grey.withOpacity(0.2),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              horizontalMargin: 24,
                              columnSpacing: 30,
                              headingRowHeight: 56,
                              dataRowMinHeight: 64,
                              dataRowMaxHeight: 64,
                              columns: [
                                DataColumn(label: Text('SALE ID')),
                                DataColumn(label: Text('DATE')),
                                DataColumn(label: Text('CUSTOMER')),
                                DataColumn(label: Text('ITEMS')),
                                DataColumn(label: Text('AMOUNT')),
                                DataColumn(label: Text('PAYMENT')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              // Show only first 5 items, sorted by newest
                              rows: sales.take(5).map((sale) {
                                final customerName = customers
                                    .firstWhere(
                                      (c) => c.id == sale.customerId,
                                      orElse: () => CustomerModel(
                                        id: '0',
                                        name: 'Unknown',
                                        email: '',
                                        phone: '',
                                        address: '',
                                        creditLimit: 0,
                                        currentDebt: 0,
                                      ),
                                    )
                                    .name;
                                return DataRow(
                                  cells: [
                                    DataCell(Text('#${sale.id}')),
                                    DataCell(
                                      Text(
                                        DateFormatter.formatWithTime(sale.date),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        customerName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text('${sale.items.length} items'),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${sale.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          sale.paymentMode.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_red_eye,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'View Details',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SalesDetailsScreen(
                                                    sale: sale,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+2.5%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
