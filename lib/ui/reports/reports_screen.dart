import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/billing_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BillingProvider>().fetchInvoices());
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final invoices = billing.invoices;

    final paidInvoices = invoices.where((i) => i.status == 'paid').length;
    final unpaidInvoices = invoices.where((i) => i.status == 'unpaid').length;
    final partialInvoices = invoices.where((i) => i.status == 'partial').length;
    final totalInvoices = invoices.length;

    // Calculate collection rate (mock logic: paid / total count)
    final collectionRate = totalInvoices > 0
        ? (paidInvoices / totalInvoices * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Reports',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 32),

            // KPI Grid
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Revenue',
                      '\$${billing.totalInvoiced.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKpiCard(
                      'Collections',
                      '\$${billing.totalPaid.toStringAsFixed(2)}',
                      Icons.savings,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKpiCard(
                      'Outstanding',
                      '\$${billing.totalPending.toStringAsFixed(2)}',
                      Icons.money_off,
                      AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKpiCard(
                      'Collection Rate',
                      '$collectionRate%',
                      Icons.percent,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Status Breakdown
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice Status Breakdown',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          _buildProgressBar(
                            'Paid Invoices (\$${_calculateSumStatus(invoices, 'paid')})',
                            paidInvoices,
                            totalInvoices,
                            AppColors.success,
                          ),
                          const SizedBox(height: 16),
                          _buildProgressBar(
                            'Unpaid Invoices (\$${_calculateSumStatus(invoices, 'unpaid')})',
                            unpaidInvoices,
                            totalInvoices,
                            AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          _buildProgressBar(
                            'Partial Invoices (\$${_calculateSumStatus(invoices, 'partial')})',
                            partialInvoices,
                            totalInvoices,
                            AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Report Actions
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Data',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildReportAction(
                            'Invoice Summary .PDF',
                            Icons.picture_as_pdf,
                          ),
                          _buildReportAction(
                            'Aged Receivables .CSV',
                            Icons.table_chart,
                          ),
                          _buildReportAction(
                            'Tax Report .XLS',
                            Icons.analytics,
                          ),
                          _buildReportAction(
                            'Customer Statement .PDF',
                            Icons.perm_contact_calendar,
                          ),
                        ],
                      ),
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

  String _calculateSumStatus(List<dynamic> list, String status) {
    final sum = list
        .where((i) => i.status == status)
        .fold(0.0, (val, i) => val + i.totalAmount);
    return sum.toStringAsFixed(2);
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    if (total == 0) total = 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$count / $total',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: count / total,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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

  Widget _buildReportAction(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.download, size: 20),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading Report... (Mock)')),
        );
      },
    );
  }
}
