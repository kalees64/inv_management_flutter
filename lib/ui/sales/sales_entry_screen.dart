import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/sales_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/sales_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/inventory_item_model.dart';
import 'widgets/add_customer_dialog.dart';

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({super.key});

  @override
  State<SalesEntryScreen> createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  CustomerModel? _selectedCustomer;
  List<SalesItem> _cart = [];
  String _paymentMode = 'cash'; // cash, credit, bank

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SalesProvider>().fetchCustomers();
      context.read<InventoryProvider>().fetchInventory();
    });
  }

  void _addToCart(InventoryItemModel product) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (item) => item.productId == product.productId,
      ); // Assuming productId matches
      // Note: InventoryItemModel has productId, SalesItem needs productId.

      if (existingIndex >= 0) {
        // Update quantity
        final existing = _cart[existingIndex];
        _cart[existingIndex] = SalesItem(
          productId: existing.productId,
          productName: existing.productName,
          quantity: existing.quantity + 1,
          unitPrice: existing.unitPrice,
          total: (existing.quantity + 1) * existing.unitPrice,
        );
      } else {
        // Add new
        // Use sellingPrice from product or default to 0.0 if not set
        double price = product.sellingPrice ?? 0.0;

        _cart.add(
          SalesItem(
            productId: product.productId,
            productName: product.productName,
            quantity: 1,
            unitPrice: price,
            total: price,
          ),
        );
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _updateCartQty(int index, int change) {
    setState(() {
      final item = _cart[index];
      final newQty = item.quantity + change;
      if (newQty > 0) {
        _cart[index] = SalesItem(
          productId: item.productId,
          productName: item.productName,
          quantity: newQty,
          unitPrice: item.unitPrice,
          total: newQty * item.unitPrice,
        );
      } else {
        _cart.removeAt(index);
      }
    });
  }

  double get _totalAmount => _cart.fold(0, (sum, item) => sum + item.total);

  void _processSale() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cart is empty')));
      return;
    }

    final sale = SalesModel(
      id: '0', // String ID for new sale
      customerId: _selectedCustomer!.id,
      date: DateTime.now().toIso8601String(),
      totalAmount: _totalAmount,
      paidAmount: _paymentMode == 'credit'
          ? 0
          : _totalAmount, // Simple credit logic
      paymentMode: _paymentMode,
      items: _cart,
    );

    final success = await context.read<SalesProvider>().createSale(sale);

    if (success && mounted) {
      // Deduct Stock from Inventory
      final inventoryProvider = context.read<InventoryProvider>();
      final shopInventory = inventoryProvider.shopInventory;

      for (final item in _cart) {
        try {
          // Use stored inventory ID if available
          if (item.inventoryItemId != null) {
            await inventoryProvider.deductStock(
              item.inventoryItemId!,
              item.quantity,
            );
          } else {
            // Fallback: Find the specific inventory item (Shop Location)
            final inventoryItem = shopInventory.firstWhere(
              (i) => i.productId == item.productId,
            );
            await inventoryProvider.deductStock(
              inventoryItem.id,
              item.quantity,
            );
          }
        } catch (e) {
          print('Stock deduction failed for ${item.productName}: $e');
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sale Recorded Successfully')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to record sale')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<SalesProvider>().customers;
    // Show only Shop inventory for POS
    final shopProducts = context.watch<InventoryProvider>().shopInventory;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale (POS)')),
      body: Row(
        children: [
          // Left: Product Catalog
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Products (Shop)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: shopProducts.isEmpty
                        ? Center(child: Text('No products in Shop Inventory'))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: shopProducts.length,
                            itemBuilder: (context, index) {
                              final product = shopProducts[index];
                              return Card(
                                elevation: 2,
                                child: InkWell(
                                  onTap: () => _addToCart(product),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inventory_2,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.productName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${product.quantity}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '\$${(product.sellingPrice ?? 0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Vertical Divider
          VerticalDivider(width: 1, color: AppColors.border),

          // Right: Cart & Checkout
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer Selection
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CustomerModel>(
                          decoration: const InputDecoration(
                            labelText: 'Select Customer',
                            prefixIcon: Icon(Icons.person),
                          ),
                          value: _selectedCustomer,
                          items: customers
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCustomer = val),
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
                  const SizedBox(height: 16),

                  // Cart Items
                  Expanded(
                    child: _cart.isEmpty
                        ? Center(
                            child: Text(
                              'Cart is empty',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return ListTile(
                                title: Text(item.productName),
                                subtitle: Text(
                                  '\$${item.unitPrice} x ${item.quantity}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${item.total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      onPressed: () =>
                                          _updateCartQty(index, -1),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline),
                                      onPressed: () => _updateCartQty(index, 1),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () => _removeFromCart(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(),

                  // Payment & Totals
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '\$${_totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        value: _paymentMode,
                        items: ['cash', 'credit', 'bank']
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _paymentMode = val!),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: context.watch<SalesProvider>().isLoading
                            ? null
                            : _processSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: context.watch<SalesProvider>().isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'COMPLETE SALE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
