import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/billing_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/billing_models.dart';
import 'create_quotation_screen.dart';
import 'quotation_details_screen.dart';

class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  // Search & Pagination State
  String _searchQuery = '';
  // 0: Date Desc, 1: Date Asc, 2: Amount High-Low, 3: Amount Low-High
  int _sortOption = 0;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BillingProvider>().fetchQuotations());
  }

  @override
  Widget build(BuildContext context) {
    final billingProvider = context.watch<BillingProvider>();
    final allQuotations = billingProvider.quotations;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          );
        },
        label: const Text('Create Quote'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter & Search Bar
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Quotations',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Refresh Button
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          context.read<BillingProvider>().fetchQuotations(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by Customer or ID...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _currentPage = 1; // Reset to page 1
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort Options
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _sortOption,
                          icon: const Icon(
                            Icons.sort,
                            color: AppColors.textSecondary,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text('Date: Newest'),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Date: Oldest'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Amount: High-Low'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Amount: Low-High'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _sortOption = val!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Content
          Expanded(
            child: billingProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildQuotationsTable(context, allQuotations),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsTable(
    BuildContext context,
    List<QuotationModel> items,
  ) {
    // 1. Filter
    var filteredList = items.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.customerName.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query);
    }).toList();

    // 2. Sort
    filteredList.sort((a, b) {
      switch (_sortOption) {
        case 0: // Date Desc
          return b.date.compareTo(a.date);
        case 1: // Date Asc
          return a.date.compareTo(b.date);
        case 2: // Amount Desc
          return b.totalAmount.compareTo(a.totalAmount);
        case 3: // Amount Asc
          return a.totalAmount.compareTo(b.totalAmount);
        default:
          return 0;
      }
    });

    // 3. Paginate
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    int effectivePage = _currentPage;
    if (effectivePage > totalPages)
      effectivePage = totalPages > 0 ? totalPages : 1;

    final startIndex = (effectivePage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < totalItems)
        ? startIndex + _itemsPerPage
        : totalItems;

    final currentItems = totalItems > 0
        ? filteredList.sublist(startIndex, endIndex)
        : <QuotationModel>[];

    if (currentItems.isEmpty && totalItems == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No quotations found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.grey.withOpacity(0.1)),
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    headingRowHeight: 60,
                    dataRowMinHeight: 70,
                    dataRowMaxHeight: 70,
                    headingRowColor: MaterialStateProperty.all(
                      AppColors.primary.withOpacity(0.05),
                    ),
                    columns: [
                      DataColumn(label: Text('ID', style: _headerStyle)),
                      DataColumn(label: Text('DATE', style: _headerStyle)),
                      DataColumn(label: Text('CUSTOMER', style: _headerStyle)),
                      DataColumn(label: Text('TOTAL', style: _headerStyle)),
                      DataColumn(label: Text('STATUS', style: _headerStyle)),
                      DataColumn(label: Text('ACTIONS', style: _headerStyle)),
                    ],
                    rows: currentItems.map((quote) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${quote.id.substring(0, quote.id.length > 6 ? 6 : quote.id.length)}...',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              quote.date,
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    quote.customerName.isNotEmpty
                                        ? quote.customerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  quote.customerName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '\$${quote.totalAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(_buildStatusChip(quote.status)),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuotationDetailsScreen(
                                      quotation: quote,
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
            ),
          ),

          // Pagination
          if (filteredList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1}-${endIndex} of $totalItems quotations',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: effectivePage > 1
                              ? () => setState(
                                  () => _currentPage = effectivePage - 1,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: AppColors.textSecondary,
                          splashRadius: 20,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Page $effectivePage of ${totalPages > 0 ? totalPages : 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: effectivePage < totalPages
                              ? () => setState(
                                  () => _currentPage = effectivePage + 1,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: AppColors.textSecondary,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        icon = Icons.edit_note;
        break;
      case 'sent':
        color = Colors.blue;
        bgColor = Colors.blue.withOpacity(0.1);
        icon = Icons.send;
        break;
      case 'confirmed':
        color = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        icon = Icons.check_circle_outline;
        break;
      case 'revised':
        color = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        icon = Icons.history;
        break;
      case 'converted':
        color = Colors.purple;
        bgColor = Colors.purple.withOpacity(0.1);
        icon = Icons.receipt_long;
        break;
      default:
        color = AppColors.primary;
        bgColor = AppColors.primary.withOpacity(0.1);
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
