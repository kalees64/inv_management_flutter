import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/sales_provider.dart';
import '../../data/models/sales_model.dart';
import '../../data/models/customer_model.dart';
import 'sales_details_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _searchQuery = '';
  bool _sortAscending = false;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

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

    // Filter
    var filteredList = sales.where((s) {
      final query = _searchQuery.toLowerCase();
      final customerName = customers
          .firstWhere(
            (c) => c.id == s.customerId,
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
          .name
          .toLowerCase();

      return s.id.toLowerCase().contains(query) ||
          customerName.contains(query) ||
          s.date.contains(query);
    }).toList();

    // Sort
    filteredList.sort((a, b) {
      int result = a.date.compareTo(b.date);
      if (result == 0) result = a.id.compareTo(b.id);
      return _sortAscending ? result : -result;
    });

    // Pagination
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < totalItems)
        ? startIndex + _itemsPerPage
        : totalItems;

    final currentItems = totalItems > 0
        ? filteredList.sublist(startIndex, endIndex)
        : <SalesModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sales History')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Sort Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search sales by ID, Customer or Date...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: ToggleButtons(
                    isSelected: [_sortAscending, !_sortAscending],
                    onPressed: (index) {
                      setState(() {
                        _sortAscending = index == 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.textSecondary,
                    selectedColor: AppColors.primary,
                    fillColor: AppColors.primary.withOpacity(0.1),
                    renderBorder: false,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, size: 16),
                            Text(' Oldest', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, size: 16),
                            Text(' Newest', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                                DataColumn(
                                  label: Text('ITEMS'),
                                ), // Simplified column for history
                                DataColumn(label: Text('AMOUNT')),
                                DataColumn(label: Text('PAYMENT')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: currentItems.map((sale) {
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
                        if (filteredList.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${startIndex + 1}-${endIndex} of $totalItems',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _currentPage > 1
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Container(
                                      width: 80,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Page $_currentPage of ${totalPages > 0 ? totalPages : 1}',
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _currentPage < totalPages
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
