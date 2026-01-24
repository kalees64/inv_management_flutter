import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/billing_provider.dart';
import '../../data/models/billing_models.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import 'receipt_details_screen.dart';

class ReceiptsListScreen extends StatefulWidget {
  const ReceiptsListScreen({super.key});

  @override
  State<ReceiptsListScreen> createState() => _ReceiptsListScreenState();
}

class _ReceiptsListScreenState extends State<ReceiptsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Date (Newest)';
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BillingProvider>().fetchReceipts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillingProvider>();
    List<ReceiptModel> filteredReceipts = _filterAndSortReceipts(
      provider.receipts,
    );

    // Pagination
    final totalPages = (filteredReceipts.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0)
      _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredReceipts.length)
        ? startIndex + _itemsPerPage
        : filteredReceipts.length;
    final currentReceipts = filteredReceipts.isEmpty
        ? <ReceiptModel>[]
        : filteredReceipts.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header & Controls (Similar to Invoices)
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receipts',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.fetchReceipts(),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by Invoice ID or Transaction ID...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        onChanged: (val) => setState(() {
                          _currentPage = 0;
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortOption,
                          icon: const Icon(Icons.sort),
                          borderRadius: BorderRadius.circular(12),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortOption = val;
                                _currentPage = 0;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'Date (Newest)',
                              child: Text('Date (Newest)'),
                            ),
                            DropdownMenuItem(
                              value: 'Date (Oldest)',
                              child: Text('Date (Oldest)'),
                            ),
                            DropdownMenuItem(
                              value: 'Amount (High-Low)',
                              child: Text('Amount (High-Low)'),
                            ),
                            DropdownMenuItem(
                              value: 'Amount (Low-High)',
                              child: Text('Amount (Low-High)'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReceipts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No receipts found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
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
                            columnSpacing: 24,
                            headingRowHeight: 56,
                            dataRowMinHeight: 64,
                            dataRowMaxHeight: 64,
                            headingRowColor: MaterialStateProperty.all(
                              AppColors.primary.withOpacity(0.05),
                            ),
                            columns: [
                              DataColumn(
                                label: Text('RECEIPT ID', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('DATE', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('INVOICE REF', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text(
                                  'PAYMENT MODE',
                                  style: _headerStyle,
                                ),
                              ),
                              DataColumn(
                                label: Text('AMOUNT', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('ACTION', style: _headerStyle),
                              ),
                            ],
                            rows: currentReceipts.map((receipt) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '#${receipt.id}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateFormatter.format(receipt.date),
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '#${receipt.invoiceId}',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Chip(
                                      label: Text(
                                        receipt.paymentMethod,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.grey[100],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '\$${receipt.amount.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiptDetailsScreen(
                                                  receipt: receipt,
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
          ),

          // Pagination
          if (filteredReceipts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<ReceiptModel> _filterAndSortReceipts(List<ReceiptModel> receipts) {
    List<ReceiptModel> filtered = receipts.where((rec) {
      final query = _searchController.text.toLowerCase();
      final matchesInv = rec.invoiceId.toLowerCase().contains(query);
      final matchesTxn =
          rec.transactionId?.toLowerCase().contains(query) ?? false;
      return matchesInv || matchesTxn;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Date (Newest)':
          return b.date.compareTo(a.date);
        case 'Date (Oldest)':
          return a.date.compareTo(b.date);
        case 'Amount (High-Low)':
          return b.amount.compareTo(a.amount);
        case 'Amount (Low-High)':
          return a.amount.compareTo(b.amount);
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
