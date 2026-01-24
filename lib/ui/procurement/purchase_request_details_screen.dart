import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/purchase_request_model.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/auth_provider.dart';

class PurchaseRequestDetailsScreen extends StatelessWidget {
  final PurchaseRequestModel request;

  const PurchaseRequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final isSupervisor = user?.role == 'supervisor' || user?.role == 'foreman';

    final canApprove = isSupervisor && request.status == 'pending';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Request #${request.id}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            _buildStatusBanner(request.status),
            const SizedBox(height: 24),

            // Main Content Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REQUEST DETAILS',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormatter.format(request.date),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'REQUESTER',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'User ${request.requesterId}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 48),

                    // Items List
                    Text(
                      'ITEMS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildItemsTable(request.items),

                    if (request.rejectionReason != null &&
                        request.rejectionReason!.isNotEmpty) ...[
                      const Divider(height: 48),
                      Text(
                        'REJECTION REASON',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.rejectionReason!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],

                    if (request.approvedBy != null &&
                        request.approvedBy!.isNotEmpty) ...[
                      const Divider(height: 48),
                      Text(
                        'ACTION BY',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.approvedBy!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            if (canApprove)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showApprovalDialog(context, request.id, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showApprovalDialog(context, request.id, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color;
    Color bgColor;
    IconData icon;
    String message;

    switch (status.toLowerCase()) {
      case 'approved':
        color = const Color(0xFF2E7D32);
        bgColor = const Color(0xFFE8F5E9);
        icon = Icons.check_circle;
        message = 'This request has been approved.';
        break;
      case 'rejected':
        color = const Color(0xFFC62828);
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.cancel;
        message = 'This request has been rejected.';
        break;
      case 'pending':
      default:
        color = const Color(0xFFF9A825);
        bgColor = const Color(0xFFFFFDE7);
        icon = Icons.hourglass_top;
        message = 'This request is pending approval.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<PurchaseRequestItem> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            children: [
              _buildTableHeader('PRODUCT'),
              _buildTableHeader('QTY'),
              _buildTableHeader('EST. PRICE'),
            ],
          ),
          // Rows
          ...items.map(
            (item) => TableRow(
              children: [
                _buildTableCell(item.productName),
                _buildTableCell(item.quantity.toString()),
                _buildTableCell('\$${item.estimatedPrice.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: GoogleFonts.inter(fontSize: 14)),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    String requestId,
    bool approve,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Use ctx to avoid confusion with parent context
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Close dialog first
              Navigator.pop(ctx);

              // Show loading or perform action
              final provider = context.read<PurchaseProvider>();
              final success = await provider.updateStatus(
                requestId,
                approve ? 'approved' : 'rejected',
                reason: approve ? null : reasonController.text,
                approvedBy: 'Supervisor',
              );

              if (success && context.mounted) {
                Navigator.pop(context); // Go back to list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Request ${approve ? 'Approved' : 'Rejected'} Successfully',
                    ),
                  ),
                );
              }
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
