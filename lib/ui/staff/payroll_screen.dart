import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/staff_provider.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<StaffProvider>().fetchPayroll());
  }

  void _generatePayroll() async {
    // Mock generation for user ID 2 (just for demo)
    final success = await context.read<StaffProvider>().generatePayroll(
      2,
      '2023-11',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Payroll Generated' : 'Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePayroll,
        tooltip: 'Generate Demo Payroll',
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.payrolls.length,
              itemBuilder: (context, index) {
                final payroll = provider.payrolls[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('User #${payroll.userId} - ${payroll.month}'),
                    subtitle: Text('Net Salary: \$${payroll.netSalary}'),
                    trailing: Chip(label: Text(payroll.status.toUpperCase())),
                  ),
                );
              },
            ),
    );
  }
}
