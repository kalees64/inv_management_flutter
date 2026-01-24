import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/purchase_request_model.dart'; // Ensure model is imported for typing
import 'create_purchase_request_screen.dart';
import 'purchase_request_details_screen.dart';

class PurchaseRequestsScreen extends StatefulWidget {
  const PurchaseRequestsScreen({super.key});

  @override
  State<PurchaseRequestsScreen> createState() => _PurchaseRequestsScreenState();
}

class _PurchaseRequestsScreenState extends State<PurchaseRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Date (Newest)';
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PurchaseProvider>().fetchRequests());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final user = context.read<AuthProvider>().user;
    final isAdmin = user?.role == 'admin';
    final isSupervisor = user?.role == 'supervisor' || user?.role == 'foreman';

    List<PurchaseRequestModel> filteredRequests = _filterAndSortRequests(
      purchaseProvider.requests,
    );

    // Pagination
    final totalPages = (filteredRequests.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0)
      _currentPage = totalPages - 1;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredRequests.length)
        ? startIndex + _itemsPerPage
        : filteredRequests.length;
    final currentRequests = filteredRequests.isEmpty
        ? <PurchaseRequestModel>[]
        : filteredRequests.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Elegant background
      appBar: Navigator.canPop(context)
          ? AppBar(
              title: const Text(
                'Purchase Requests',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              iconTheme: const IconThemeData(color: Colors.black),
            )
          : null,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePurchaseRequestScreen(),
                  ),
                );
              },
              label: const Text('New Request'),
              icon: const Icon(Icons.add),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: purchaseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchaseProvider.error != null
          ? Center(child: Text(purchaseProvider.error!))
          : Column(
              children: [
                // Header & Controls
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by ID or Requester...',
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
                                    value: 'Status',
                                    child: Text('Status'),
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
                  child: filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No purchase requests found',
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
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.grey.withOpacity(0.1),
                              ),
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
                                      label: Text('ID', style: _headerStyle),
                                    ),
                                    DataColumn(
                                      label: Text('DATE', style: _headerStyle),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'REQUESTER',
                                        style: _headerStyle,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'SUMMARY',
                                        style: _headerStyle,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'STATUS',
                                        style: _headerStyle,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'ACTION',
                                        style: _headerStyle,
                                      ),
                                    ),
                                  ],
                                  rows: currentRequests.map((request) {
                                    final totalItems = request.items.length;
                                    final firstItem = request.items.isNotEmpty
                                        ? request.items.first.productName
                                        : 'No items';
                                    final summary = totalItems > 1
                                        ? '$firstItem + ${totalItems - 1} others'
                                        : firstItem;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            '#${request.id}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            DateFormatter.format(request.date),
                                            style: GoogleFonts.inter(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'User ${request.requesterId}',
                                            style: GoogleFonts.inter(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            summary,
                                            style: GoogleFonts.inter(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          _buildStatusChip(request.status),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // View Action (Placeholder)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PurchaseRequestDetailsScreen(
                                                            request: request,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                tooltip: 'View Details',
                                              ),
                                              // Approval Actions
                                              if (isSupervisor &&
                                                  request.status ==
                                                      'pending') ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () =>
                                                      _showApprovalDialog(
                                                        context,
                                                        request.id,
                                                        true,
                                                      ),
                                                  tooltip: 'Approve',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.cancel_outlined,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _showApprovalDialog(
                                                        context,
                                                        request.id,
                                                        false,
                                                      ),
                                                  tooltip: 'Reject',
                                                ),
                                              ],
                                            ],
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
                if (filteredRequests.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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

  List<PurchaseRequestModel> _filterAndSortRequests(
    List<PurchaseRequestModel> requests,
  ) {
    List<PurchaseRequestModel> filtered = requests.where((req) {
      final query = _searchController.text.toLowerCase();
      final matchesId = req.id.toString().toLowerCase().contains(query);
      final matchesUser = 'user ${req.requesterId}'.contains(
        query,
      ); // Simple match
      return matchesId || matchesUser;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Date (Newest)':
          return b.date.compareTo(a.date);
        case 'Date (Oldest)':
          return a.date.compareTo(b.date);
        case 'Status':
          return a.status.compareTo(b.status);
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filtered;
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;
    switch (status.toLowerCase()) {
      case 'approved':
        color = const Color(0xFF2E7D32); // Green 800
        bgColor = const Color(0xFFE8F5E9); // Green 50
        break;
      case 'rejected':
        color = const Color(0xFFC62828); // Red 800
        bgColor = const Color(0xFFFFEBEE); // Red 50
        break;
      case 'pending':
      default:
        color = const Color(0xFFF9A825); // Yellow 800
        bgColor = const Color(0xFFFFFDE7); // Yellow 50
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.5,
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

  void _showApprovalDialog(
    BuildContext context,
    String requestId,
    bool approve,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Request?' : 'Reject Request?'),
        content: approve
            ? const Text(
                'Are you sure you want to approve this purchase request?',
              )
            : TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final provider = context.read<PurchaseProvider>();
              await provider.updateStatus(
                requestId,
                approve ? 'approved' : 'rejected',
                reason: approve ? null : reasonController.text,
                approvedBy: 'Supervisor',
              );
              if (mounted) Navigator.pop(context);
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
