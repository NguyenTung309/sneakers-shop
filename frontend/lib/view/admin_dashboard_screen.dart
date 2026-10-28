import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Statistics'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StatsTab(),
          _OrdersTab(),
          _ProductsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await ApiService.getStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = _stats!;
    final bestSelling =
        (stats['bestSellingProducts'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth >= 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  label: 'Revenue',
                  value:
                      '\$${(stats['totalRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                _StatCard(
                  label: 'Orders',
                  value: '${stats['totalOrders'] ?? 0}',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
                _StatCard(
                  label: 'Users',
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.people,
                  color: Colors.purple,
                ),
                _StatCard(
                  label: 'Products',
                  value: '${stats['totalProducts'] ?? 0}',
                  icon: Icons.inventory_2,
                  color: Colors.orange,
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Best selling
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Selling Products',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (bestSelling.isEmpty)
                    const Text('No sales data yet.')
                  else
                    ...bestSelling.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${index + 1}'),
                        ),
                        title: Text('${item['name'] ?? ''}'),
                        subtitle: Text('${item['brand'] ?? ''}'),
                        trailing: Chip(
                          label: Text('${item['totalSold'] ?? 0} sold'),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filterStatus = '';

  static const _statusFlow = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Shipping',
    'Completed',
  ];

  static const _nextStatus = {
    'Pending': 'Confirmed',
    'Confirmed': 'Preparing',
    'Preparing': 'Shipping',
    'Shipping': 'Completed',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiService.getAllOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Order order) async {
    final next = _nextStatus[order.status];
    if (next == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Text(
            'Change Order #${order.id} from "${order.status}" → "$next"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.updateOrderStatus(order.id, next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated.')));
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  List<Order> get _filtered {
    if (_filterStatus.isEmpty) return _orders;
    return _orders.where((o) => o.status == _filterStatus).toList();
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Pending' => Colors.orange,
      'Confirmed' => Colors.blue,
      'Preparing' => Colors.indigo,
      'Shipping' => Colors.cyan,
      'Completed' => Colors.green,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final orders = _filtered;

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus.isEmpty,
                  onSelected: (_) => setState(() => _filterStatus = ''),
                ),
                const SizedBox(width: 8),
                ..._statusFlow.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s),
                        selected: _filterStatus == s,
                        onSelected: (_) =>
                            setState(() => _filterStatus = s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No orders found.'),
              ),
            )
          else
            ...orders.map((order) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(order.status).withValues(alpha: 0.15),
                      child: Icon(Icons.receipt,
                          color: _statusColor(order.status), size: 20),
                    ),
                    title: Text('Order #${order.id}'),
                    subtitle: Text(
                      '${order.status} • ${order.orderDate.toLocal().toString().split('.').first} • \$${order.totalAmount.toStringAsFixed(2)}',
                    ),
                    trailing: _nextStatus.containsKey(order.status)
                        ? FilledButton.tonal(
                            onPressed: () => _updateStatus(order),
                            child: Text(
                                '→ ${_nextStatus[order.status]}',
                                style: const TextStyle(fontSize: 12)),
                          )
                        : Chip(
                            backgroundColor:
                                _statusColor(order.status).withValues(alpha: 0.15),
                            label: Text(order.status,
                                style: TextStyle(
                                    color: _statusColor(order.status),
                                    fontSize: 12)),
                          ),
                    children: order.items.map((item) {
                      return ListTile(
                        dense: true,
                        leading: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            item.shoe.imgAddress,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_outlined),
                          ),
                        ),
                        title: Text(item.shoe.name),
                        subtitle: Text(
                            '${item.variant.size} / ${item.variant.color}'),
                        trailing: Text(
                            'x${item.quantity}  \$${item.price.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<ShoeModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.getShoes();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(ShoeModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteProduct(product.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted.')));
      _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _openForm({ShoeModel? product}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => _ProductFormScreen(product: product)),
    );
    if (result == true) _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _products.isEmpty
            ? const Center(child: Text('No products found.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imgAddress,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_outlined),
                          ),
                        ),
                      ),
                      title: Text(p.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${p.brand} • \$${p.price.toStringAsFixed(2)}\n${p.variants?.length ?? 0} variants'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openForm(product: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteProduct(p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT FORM SCREEN (Create / Edit)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductFormScreen extends StatefulWidget {
  const _ProductFormScreen({this.product});

  final ShoeModel? product;

  @override
  State<_ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<_ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;

  // Variants
  List<_VariantRow> _variants = [];
  bool _isSaving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _imageCtrl = TextEditingController(text: p?.imgAddress ?? '');

    _variants = (p?.variants ?? [])
        .map((v) => _VariantRow(
              sizeCtrl: TextEditingController(text: v.size),
              colorCtrl: TextEditingController(text: v.color),
              stockCtrl: TextEditingController(text: '${v.stock}'),
            ))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() => _variants.add(_VariantRow(
          sizeCtrl: TextEditingController(),
          colorCtrl: TextEditingController(),
          stockCtrl: TextEditingController(),
        )));
  }

  void _removeVariant(int index) {
    setState(() {
      _variants[index].dispose();
      _variants.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'imageUrl': _imageCtrl.text.trim(),
        'variants': _variants
            .map((v) => {
                  'size': v.sizeCtrl.text.trim(),
                  'color': v.colorCtrl.text.trim(),
                  'stock': int.tryParse(v.stockCtrl.text.trim()) ?? 0,
                })
            .toList(),
      };

      if (_isEdit) {
        await ApiService.updateProduct(widget.product!.id!, payload);
      } else {
        await ApiService.createProduct(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'New Product'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Info',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _field(_nameCtrl, 'Product Name'),
                    const SizedBox(height: 12),
                    _field(_brandCtrl, 'Brand'),
                    const SizedBox(height: 12),
                    _field(_priceCtrl, 'Price',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        }),
                    const SizedBox(height: 12),
                    _field(_imageCtrl, 'Image URL'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Variants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Variants',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addVariant,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_variants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No variants. Tap Add to create one.'),
                      )
                    else
                      ..._variants.asMap().entries.map((entry) {
                        final i = entry.key;
                        final v = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _field(v.sizeCtrl, 'Size'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _field(v.colorCtrl, 'Color'),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: _field(v.stockCtrl, 'Stock',
                                    keyboardType: TextInputType.number),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _removeVariant(i),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}

class _VariantRow {
  final TextEditingController sizeCtrl;
  final TextEditingController colorCtrl;
  final TextEditingController stockCtrl;

  _VariantRow({
    required this.sizeCtrl,
    required this.colorCtrl,
    required this.stockCtrl,
  });

  void dispose() {
    sizeCtrl.dispose();
    colorCtrl.dispose();
    stockCtrl.dispose();
  }
}