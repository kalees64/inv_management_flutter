import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/sales_provider.dart';
import '../../../data/models/customer_model.dart';

class AddCustomerDialog extends StatefulWidget {
  final Function(CustomerModel) onCustomerAdded;

  const AddCustomerDialog({super.key, required this.onCustomerAdded});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(labelText: 'Credit Limit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final newCustomer = CustomerModel(
                id: '0',
                name: _nameController.text,
                phone: _phoneController.text,
                email: _emailController.text,
                address: _addressController.text,
                creditLimit:
                    double.tryParse(_creditLimitController.text) ?? 0.0,
                currentDebt: 0.0,
              );

              final provider = context.read<SalesProvider>();
              final createdCustomer = await provider.addCustomer(newCustomer);

              if (createdCustomer != null && mounted) {
                widget.onCustomerAdded(createdCustomer);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer Added Successfully')),
                );
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
