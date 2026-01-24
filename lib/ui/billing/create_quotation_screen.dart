import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/sales_provider.dart'; // To fetch customers
import '../../providers/inventory_provider.dart'; // To fetch items (if we use inventory items)
import '../../data/models/billing_models.dart';
import '../../data/models/customer_model.dart';
import '../../core/constants/app_theme.dart';
import '../sales/widgets/add_customer_dialog.dart';

class CreateQuotationScreen extends StatefulWidget {
  final QuotationModel? sourceQuote;
  final bool isRevision;

  const CreateQuotationScreen({
    super.key,
    this.sourceQuote,
    this.isRevision = false,
  });

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerModel? _selectedCustomer;
  // Initialize list from source if available
  late List<BillingItem> _items;

  // Controllers for adding items
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.sourceQuote != null
        ? List.from(widget.sourceQuote!.items)
        : [];

    Future.microtask(() {
      context.read<SalesProvider>().fetchCustomers().then((_) {
        // If editing/revision, pre-select customer
        if (widget.sourceQuote != null) {
          final customers = context.read<SalesProvider>().customers;
          try {
            final customer = customers.firstWhere(
              (c) => c.id == widget.sourceQuote!.customerId,
            );
            setState(() {
              _selectedCustomer = customer;
            });
          } catch (e) {
            // Customer might be deleted or ID mismatch
          }
        }
      });
      context.read<InventoryProvider>().fetchInventory();
    });
  }

  void _addItem() {
    final name = _productNameController.text;
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (name.isNotEmpty && price > 0) {
      setState(() {
        _items.add(
          BillingItem(
            productId: 0, // Mock ID or create ad-hoc
            productName: name,
            quantity: qty,
            unitPrice: price,
            total: qty * price,
          ),
        );
      });
      _productNameController.clear();
      _quantityController.clear();
      _priceController.clear();
    }
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<SalesProvider>().customers;
    final isLoading = context.watch<BillingProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRevision ? 'Create Revision' : 'Create Quotation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Customer Dropdown
              // If revision, maybe lock customer? Or allow change? Usually revision is for same customer.
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CustomerModel>(
                      decoration: const InputDecoration(
                        labelText: 'Select Customer',
                      ),
                      value: _selectedCustomer,
                      items: customers
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCustomer = val),
                      validator: (val) =>
                          val == null ? 'Please select a customer' : null,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddCustomerDialog(
                          onCustomerAdded: (newCustomer) {
                            setState(() {
                              _selectedCustomer = newCustomer;
                            });
                          },
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_add,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Add New Customer',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Item Entry
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            // Get unique product names from inventory
                            final inventory = context
                                .read<InventoryProvider>()
                                .inventory;
                            final uniqueNames = inventory
                                .map((e) => e.productName)
                                .toSet()
                                .toList();

                            return uniqueNames.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          onSelected: (String selection) {
                            _productNameController.text = selection;
                          },
                          fieldViewBuilder:
                              (
                                BuildContext context,
                                TextEditingController
                                fieldTextEditingController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                // If user types manually, update controller
                                fieldTextEditingController.text =
                                    _productNameController.text;
                                // This sync might be tricky if _productNameController changes externally
                                // But mainly we want to capture edits:
                                return TextFormField(
                                  controller: fieldTextEditingController,
                                  focusNode: fieldFocusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Item Name',
                                  ),
                                  onChanged: (val) {
                                    _productNameController.text = val;
                                  },
                                );
                              },
                          optionsViewBuilder:
                              (
                                BuildContext context,
                                AutocompleteOnSelected<String> onSelected,
                                Iterable<String> options,
                              ) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      height: 200.0,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8.0),
                                        itemCount: options.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final String option = options
                                                  .elementAt(index);
                                              return GestureDetector(
                                                onTap: () {
                                                  onSelected(option);
                                                },
                                                child: ListTile(
                                                  title: Text(option),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                );
                              },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _addItem();
                      // Clear autocomplete controller?
                    },
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),

              // Items List
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item.productName),
                      subtitle: Text('${item.quantity} x \$${item.unitPrice}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          (_items.isEmpty ||
                              _selectedCustomer == null ||
                              isLoading)
                          ? null
                          : _submitQuotation,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.isRevision
                                  ? 'Create Revision'
                                  : 'Create Quotation',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuotation() async {
    if (_formKey.currentState!.validate()) {
      bool success = false;
      if (widget.isRevision && widget.sourceQuote != null) {
        // Create Revision Logic
        final newRevisionNumber = widget.sourceQuote!.revisionNumber + 1;
        final newQuote = QuotationModel(
          id: '0',
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          date: DateTime.now().toString().split(' ')[0],
          items: _items,
          totalAmount: _totalAmount,
          status: 'draft',
          revisionNumber: newRevisionNumber,
          originalQuoteId:
              widget.sourceQuote!.originalQuoteId ?? widget.sourceQuote!.id,
        );
        success = await context.read<BillingProvider>().createRevision(
          newQuote,
        );
      } else {
        // Create New Quote Logic
        success = await context.read<BillingProvider>().createQuotation(
          QuotationModel(
            id: '0',
            customerId: _selectedCustomer!.id,
            customerName: _selectedCustomer!.name,
            date: DateTime.now().toString().split(' ')[0],
            items: _items,
            totalAmount: _totalAmount,
            status: 'draft',
          ),
        );
      }

      if (success && mounted) {
        Navigator.pop(context); // Close create screen
        // If it was revision, we are back at details screen usually?
        // Or if opened from list, back to list.
        // If opened from details screen, we might need to pop twice or just pop once
        // and let user navigate to new revision from list.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isRevision ? 'Revision Created!' : 'Quotation Created!',
            ),
          ),
        );
      }
    }
  }
}
