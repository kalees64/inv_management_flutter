import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/inventory_item_model.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();
  String _selectedLocation = 'godown';
  String? _selectedCategory; // New

  final List<String> _locations = ['godown', 'shop', 'van', 'transit'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().fetchCategories());
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final newItem = InventoryItemModel(
        id: '0',
        productId: 0,
        productName: _productNameController.text,
        location: _selectedLocation,
        quantity: int.parse(_qtyController.text),
        minStockLevel: 10,
        category: _selectedCategory, // Pass category
      );

      final success = await context.read<InventoryProvider>().addStock(newItem);

      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Stock Added Successfully')));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add stock')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<InventoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Stock Entry',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'Enter product name',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(labelText: 'Location'),
                    items: _locations
                        .map(
                          (loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(loc.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedLocation = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: context.watch<InventoryProvider>().isLoading
                        ? null
                        : _submit,
                    child: context.watch<InventoryProvider>().isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Stock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
