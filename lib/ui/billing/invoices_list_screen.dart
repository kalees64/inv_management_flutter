import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/billing_provider.dart';
import '../../data/models/billing_models.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import 'invoice_details_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Date (Newest)';
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BillingProvider>().fetchInvoices());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillingProvider>();
    List<InvoiceModel> filteredInvoices = _filterAndSortInvoices(
      provider.invoices,
    );

    // Pagination Logic
    final totalPages = (filteredInvoices.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0)
      _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredInvoices.length)
        ? startIndex + _itemsPerPage
        : filteredInvoices.length;
    final currentInvoices = filteredInvoices.isEmpty
        ? <InvoiceModel>[]
        : filteredInvoices.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: Column(
        children: [
          // Header & Controls
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invoices',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.fetchInvoices(),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search & Sort Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by Customer or ID...',
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

          // Table Content
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInvoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No invoices found',
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
                                label: Text('INVOICE ID', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('DATE', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('CUSTOMER', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('AMOUNT', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('STATUS', style: _headerStyle),
                              ),
                              DataColumn(
                                label: Text('ACTION', style: _headerStyle),
                              ),
                            ],
                            rows: currentInvoices.map((invoice) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '#${invoice.id}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateFormatter.format(invoice.date),
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice.customerName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '\$${invoice.totalAmount.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(_buildStatusChip(invoice)),
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
                                                InvoiceDetailsScreen(
                                                  invoice: invoice,
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

          // Pagination Controls
          if (filteredInvoices.isNotEmpty)
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

  List<InvoiceModel> _filterAndSortInvoices(List<InvoiceModel> invoices) {
    List<InvoiceModel> filtered = invoices.where((inv) {
      final query = _searchController.text.toLowerCase();
      final matchesName = inv.customerName.toLowerCase().contains(query);
      final matchesId = inv.id.toLowerCase().contains(query);
      return matchesName || matchesId;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Date (Newest)':
          return b.date.compareTo(a.date);
        case 'Date (Oldest)':
          return a.date.compareTo(b.date);
        case 'Amount (High-Low)':
          return b.totalAmount.compareTo(a.totalAmount);
        case 'Amount (Low-High)':
          return a.totalAmount.compareTo(b.totalAmount);
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

  Widget _buildStatusChip(InvoiceModel invoice) {
    Color color;
    switch (invoice.status) {
      case 'paid':
        color = Colors.green;
        break;
      case 'partial':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        invoice.status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
