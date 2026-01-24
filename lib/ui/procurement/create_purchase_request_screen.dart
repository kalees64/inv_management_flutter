import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/purchase_request_model.dart';
// removed unused user_model import

class CreatePurchaseRequestScreen extends StatefulWidget {
  const CreatePurchaseRequestScreen({super.key});

  @override
  State<CreatePurchaseRequestScreen> createState() =>
      _CreatePurchaseRequestScreenState();
}

class _CreatePurchaseRequestScreenState
    extends State<CreatePurchaseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<PurchaseRequestItem> _items = [];

  // Controllers for the current item being added
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _items.add(
          PurchaseRequestItem(
            productName: _productNameController.text,
            quantity: int.tryParse(_qtyController.text) ?? 1,
            estimatedPrice: double.tryParse(_priceController.text) ?? 0.0,
          ),
        );

        _productNameController.clear();
        _qtyController.clear();
        _priceController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please add at least one item')));
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final request = PurchaseRequestModel(
      id: '0',
      requesterId: user.id,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      status: 'pending',
      items: _items,
    );

    final success = await context.read<PurchaseProvider>().createRequest(
      request,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request Created Successfully')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Entry Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _productNameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Est. Price',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            if (_items.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Items List',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      trailing: Text('Total Items: ${_items.length}'),
                    ),
                    const Divider(),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                            'Qty: ${item.quantity} | Est. Price: ${item.estimatedPrice}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            onPressed: () => _removeItem(index),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: context.watch<PurchaseProvider>().isLoading
                  ? null
                  : _submit,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: context.watch<PurchaseProvider>().isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
