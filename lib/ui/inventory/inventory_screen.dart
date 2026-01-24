import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/inventory_item_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State for search/filter/pagination
  String _searchQuery = '';
  bool _sortAscending = true;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabSelection);
    Future.microtask(() {
      context.read<InventoryProvider>().fetchInventory();
      context.read<InventoryProvider>().fetchCategories();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditStockDialog({InventoryItemModel? item}) {
    // Re-use AddInventoryScreen logic or basic dialog?
    // User asked "when I edit am able to update product details".
    // For simplicity and consistency with other screens, I'll use a dialog here.
    // However, AddInventoryScreen is a full screen.
    // To properly support "Update", I should probably refactor AddInventoryScreen to support editing
    // OR create a dialog here. Given "Same like customer screen", a dialog is preferred.
    // BUT AddInventoryScreen handles categories etc.
    // Let's bring up a dialog similar to Suppliers/Customers for editing/adding.

    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.productName);
    final qtyController = TextEditingController(
      text: item?.quantity.toString(),
    );
    final costController = TextEditingController(
      text: item?.costPrice?.toString(),
    );
    final sellingController = TextEditingController(
      text: item?.sellingPrice?.toString(),
    );
    String selectedLocation = item?.location ?? 'godown';
    String? selectedCategory = item?.category; // Use category from item

    // We need categories for the dropdown
    final categories = context.read<InventoryProvider>().categories;
    if (categories.isEmpty) {
      context.read<InventoryProvider>().fetchCategories();
    }

    final _formKey = GlobalKey<FormState>();
    final locations = ['godown', 'shop', 'van', 'transit', 'customer'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to update dropdowns in Dialog
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Stock' : 'Add New Stock'),
            content: Container(
              width: 600, // Increase width to accommodate fields comfortably
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value:
                            selectedCategory, // This might be null for new items or items without category
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: (v) => v == null ? 'Required' : null,
                        items: context
                            .read<InventoryProvider>()
                            .categories // Access provider directly
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedCategory = val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedLocation,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                        items: locations
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(l.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedLocation = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: qtyController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: costController,
                              decoration: const InputDecoration(
                                labelText: 'Cost Price',
                                prefixText: '\$',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: sellingController,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price',
                                prefixText: '\$',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    // Correctly handling ID: 0 for new, existing ID for update
                    final newItem = InventoryItemModel(
                      id: isEdit ? item.id : '0', // Use String '0' for new
                      productId: isEdit
                          ? item.productId
                          : 0, // Preserve product ID if needed
                      productName: nameController.text,
                      location: selectedLocation,
                      quantity: int.parse(qtyController.text),
                      minStockLevel: isEdit ? item.minStockLevel : 10,
                      category: selectedCategory,
                      costPrice: double.tryParse(costController.text),
                      sellingPrice: double.tryParse(sellingController.text),
                    );

                    final provider = context.read<InventoryProvider>();
                    final success = isEdit
                        ? await provider.updateStock(newItem)
                        : await provider.addStock(newItem);

                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit ? 'Stock Updated' : 'Stock Added',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock?'),
        content: Text('Are you sure you want to delete "${item.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _secondVerification(item);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _secondVerification(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This action cannot be undone. Do you really want to delete this stock?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await context.read<InventoryProvider>().deleteStock(item.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Stock Deleted')));
              }
            },
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final user = context.read<AuthProvider>().user;
    final isForeman = user?.role == 'foreman' || user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isForeman
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditStockDialog(),
              label: const Text('Add Stock'),
              icon: const Icon(Icons.add),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'All Stock'),
                Tab(text: 'Shop'),
                Tab(text: 'Godown'),
                Tab(text: 'Van'),
                Tab(text: 'Transit'),
                Tab(text: 'Customer Loc.'),
              ],
            ),
          ),

          // Search & Sort Bar (Global for the screen, applies to current tab view effectively)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ToggleButtons(
                  isSelected: [_sortAscending, !_sortAscending],
                  onPressed: (index) {
                    setState(() {
                      _sortAscending = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 16),
                          Text(' AZ'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 16),
                          Text(' ZA'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: inventoryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInventoryTable(
                        context,
                        inventoryProvider.inventory,
                      ),
                      _buildInventoryTable(
                        context,
                        inventoryProvider.shopInventory,
                      ),
                      _buildInventoryTable(
                        context,
                        inventoryProvider.godownInventory,
                      ),
                      _buildInventoryTable(
                        context,
                        inventoryProvider.vanInventory,
                      ),
                      _buildInventoryTable(
                        context,
                        inventoryProvider.transitInventory,
                      ),
                      _buildInventoryTable(
                        context,
                        inventoryProvider.customerInventory,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(
    BuildContext context,
    List<InventoryItemModel> items,
  ) {
    // 1. Filter
    var filteredList = items.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.productName.toLowerCase().contains(query) ||
          (item.category?.toLowerCase().contains(query) ?? false);
    }).toList();

    // 2. Sort
    filteredList.sort(
      (a, b) => _sortAscending
          ? a.productName.compareTo(b.productName)
          : b.productName.compareTo(a.productName),
    );

    // 3. Paginate
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    int effectivePage = _currentPage;
    if (effectivePage > totalPages)
      effectivePage = totalPages > 0 ? totalPages : 1;

    final startIndex = (effectivePage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < totalItems)
        ? startIndex + _itemsPerPage
        : totalItems;

    final currentItems = totalItems > 0
        ? filteredList.sublist(startIndex, endIndex)
        : <InventoryItemModel>[];

    if (currentItems.isEmpty && totalItems == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No items found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.grey.withOpacity(0.1)),
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    headingRowHeight: 60,
                    dataRowMinHeight: 70,
                    dataRowMaxHeight: 70,
                    // Header color applied via theme or override here
                    headingRowColor: MaterialStateProperty.all(
                      AppColors.primary.withOpacity(0.05),
                    ),
                    columns: [
                      DataColumn(label: Text('PRODUCT', style: _headerStyle)),
                      DataColumn(label: Text('CATEGORY', style: _headerStyle)),
                      DataColumn(label: Text('LOCATION', style: _headerStyle)),
                      DataColumn(label: Text('QUANTITY', style: _headerStyle)),
                      DataColumn(label: Text('STATUS', style: _headerStyle)),
                      DataColumn(label: Text('ACTIONS', style: _headerStyle)),
                    ],
                    rows: currentItems.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.productName.isEmpty
                                          ? '?'
                                          : item.productName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'ID: #${item.id}',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              item.category ?? '-',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.location.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            _buildStatusChip(
                              item.quantity,
                              item.minStockLevel ?? 10,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  color: AppColors.primary,
                                  splashRadius: 20,
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _showAddEditStockDialog(item: item),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: AppColors.error,
                                  splashRadius: 20,
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDelete(item),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Pagination Controls
          if (filteredList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1}-${endIndex} of $totalItems items',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: effectivePage > 1
                              ? () => setState(
                                  () => _currentPage = effectivePage - 1,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: AppColors.textSecondary,
                          splashRadius: 20,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Page $effectivePage of ${totalPages > 0 ? totalPages : 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: effectivePage < totalPages
                              ? () => setState(
                                  () => _currentPage = effectivePage + 1,
                                )
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: AppColors.textSecondary,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // Header Style Helper
  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  Widget _buildStatusChip(int quantity, int minLevel) {
    Color color;
    Color bgColor;
    String text;
    IconData icon;

    if (quantity == 0) {
      color = AppColors.error;
      bgColor = AppColors.error.withOpacity(0.1);
      text = 'Out of Stock';
      icon = Icons.error_outline;
    } else if (quantity < minLevel) {
      color = AppColors.warning;
      bgColor = AppColors.warning.withOpacity(0.1);
      text = 'Low Stock';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.1);
      text = 'In Stock';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
