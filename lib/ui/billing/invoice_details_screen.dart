import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/billing_models.dart';
import '../../providers/billing_provider.dart';
import '../../core/constants/app_theme.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    // Listen for updates (e.g. after payment)
    final invoice =
        context.select<BillingProvider, InvoiceModel?>(
          (p) => p.invoices.any((i) => i.id == widget.invoice.id)
              ? p.invoices.firstWhere((i) => i.id == widget.invoice.id)
              : null,
        ) ??
        widget.invoice;

    final dueAmount = invoice.totalAmount - invoice.paidAmount;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Professional gray background
      appBar: AppBar(
        title: Text(
          'Invoice Preview',
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
            _buildStatusBanner(invoice),
            const SizedBox(height: 24),

            // Invoice Paper Card
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
                children: [
                  _buildHeader(invoice),
                  const Divider(height: 1),
                  _buildItemsTable(invoice),
                  const Divider(height: 1),
                  _buildSummarySection(invoice, dueAmount),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            if (invoice.status != 'paid')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () =>
                      _showPaymentDialog(context, invoice, dueAmount),
                  icon: const Icon(Icons.payment),
                  label: const Text(
                    'Record Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(InvoiceModel invoice) {
    Color color = _getStatusColor(invoice.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Text(
            'Status: ${invoice.status.toUpperCase()}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: color),
          ),
          const Spacer(),
          Text(
            'Due: ${invoice.dueDate}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(InvoiceModel invoice) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BILLED TO', style: _labelStyle),
              const SizedBox(height: 8),
              Text(
                invoice.customerName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'ID: #${invoice.customerId}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('INVOICE NO', style: _labelStyle),
              const SizedBox(height: 8),
              Text(
                '#${invoice.id}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.date,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(InvoiceModel invoice) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: [
          DataColumn(label: Text('ITEM', style: _labelStyle)),
          DataColumn(label: Text('QTY', style: _labelStyle)),
          DataColumn(label: Text('PRICE', style: _labelStyle)),
          DataColumn(label: Text('TOTAL', style: _labelStyle)),
        ],
        rows: invoice.items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.productName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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

  Widget _buildSummarySection(InvoiceModel invoice, double dueAmount) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.primary.withOpacity(0.02),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Amount',
            '\$${invoice.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Paid Amount',
            '\$${invoice.paidAmount.toStringAsFixed(2)}',
            color: Colors.green,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Balance Due',
            '\$${dueAmount.toStringAsFixed(2)}',
            color: dueAmount > 0 ? Colors.red : Colors.grey,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  TextStyle get _labelStyle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  Color _getStatusColor(String status) {
    switch (status) {
      case 'unpaid':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showPaymentDialog(
    BuildContext context,
    InvoiceModel invoice,
    double dueAmount,
  ) {
    final amountController = TextEditingController(text: dueAmount.toString());
    final txnIdController = TextEditingController();
    String selectedMode = 'UPI';
    final modes = ['UPI', 'Card', 'Bank Transfer', 'Cash'];

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Record Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                    ),
                    items: modes
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedMode = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: txnIdController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID (Optional)',
                      hintText: 'e.g. UPI Ref or Auth Code',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount > 0 && amount <= dueAmount + 0.01) {
                    await context.read<BillingProvider>().recordPayment(
                      invoice,
                      amount,
                      selectedMode,
                      transactionId: txnIdController.text.isEmpty
                          ? null
                          : txnIdController.text,
                    );
                    if (mounted) {
                      Navigator.pop(c);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment Recorded Successfully'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Amount')),
                    );
                  }
                },
                child: const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );
  }
}
