import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/billing_models.dart';
import '../../providers/billing_provider.dart';
import '../../core/constants/app_theme.dart';
import 'create_quotation_screen.dart';

class QuotationDetailsScreen extends StatefulWidget {
  final QuotationModel quotation;

  const QuotationDetailsScreen({super.key, required this.quotation});

  @override
  State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Listen to provider updates to catch status changes/revisions
    final quotation = context.select<BillingProvider, QuotationModel?>(
      (p) => p.quotations.any((q) => q.id == widget.quotation.id)
          ? p.quotations.firstWhere((q) => q.id == widget.quotation.id)
          : null, // If deleted or not found, return null
    );

    // If quotation was deleted, pop back
    if (quotation == null) {
      // Use a post-frame callback to pop safely if we are still here
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Quote Preview',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Banner
            _buildStatusBanner(quotation),
            const SizedBox(height: 24),

            // Main Invoice Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildInvoiceHeader(quotation),
                  const Divider(height: 1),
                  // Items Table
                  _buildElegantItemsTable(quotation),
                  const Divider(height: 1),
                  // Totals
                  _buildTotalsSection(quotation),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            if (quotation.status != 'converted')
              _buildActionsBar(context, quotation),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(QuotationModel quote) {
    final color = _getStatusColor(quote.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ${quote.status.toUpperCase()}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (quote.revisionNumber > 0)
                Text(
                  'Revision #${quote.revisionNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (quote.originalQuoteId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'REV from #${quote.originalQuoteId}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(QuotationModel quote) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUSTOMER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quote.customerName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'ID: #${quote.customerId}',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'QUOTATION DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '#${quote.id}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                quote.date,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantItemsTable(QuotationModel quote) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: [
          DataColumn(label: Text('ITEM', style: _headerStyle)),
          DataColumn(label: Text('QTY', style: _headerStyle)),
          DataColumn(label: Text('UNIT PRICE', style: _headerStyle)),
          DataColumn(label: Text('TOTAL', style: _headerStyle)),
        ],
        rows: quote.items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              DataCell(Text('${item.quantity}', style: GoogleFonts.inter())),
              DataCell(Text('\$${item.unitPrice}', style: GoogleFonts.inter())),
              DataCell(
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalsSection(QuotationModel quote) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.primary.withOpacity(0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${quote.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context, QuotationModel quote) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sendEmail(context, quote),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Send Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openRevisionMode(context, quote),
                icon: const Icon(Icons.edit_note),
                label: const Text('Create Revision'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _confirmAndInvoice(context, quote),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Confirm & Create Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _deleteWithTwoStep(context, quote),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // LOGIC

  void _openRevisionMode(BuildContext context, QuotationModel quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateQuotationScreen(sourceQuote: quote, isRevision: true),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, QuotationModel quote) async {
    setState(() => _isLoading = true);
    await context.read<BillingProvider>().sendQuotationEmail(quote.id);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Email Sent!')));
  }

  Future<void> _confirmAndInvoice(
    BuildContext context,
    QuotationModel quote,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Generate Invoice?'),
        content: const Text(
          'This will finalize the quotation and create a pending invoice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await context
          .read<BillingProvider>()
          .convertQuoteToInvoice(quote);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice Created!')));
      }
    }
  }

  Future<void> _deleteWithTwoStep(
    BuildContext context,
    QuotationModel quote,
  ) async {
    // Step 1
    final step1 = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Quotation?'),
        content: const Text('Are you sure you want to delete this quotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (step1 != true) return;

    // Step 2
    if (!mounted) return;
    final step2 = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('This action cannot be undone. Confirm deletion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'Confirm Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (step2 == true) {
      setState(() => _isLoading = true);
      final success = await context.read<BillingProvider>().deleteQuotation(
        quote.id,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context); // Exit details
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quotation Deleted')));
      }
    }
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'revised':
        return Colors.orange;
      case 'converted':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }
}
