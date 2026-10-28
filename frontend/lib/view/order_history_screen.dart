import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _productFilterController = TextEditingController();

  List<Order> _orders = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _filterStatus = '';
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _productFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!mounted) {
      return;
    }

    if (!loggedIn) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
        _orders = [];
      });
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _isLoading = true;
    });

    try {
      final orders = await ApiService.getOrders();
      if (!mounted) {
        return;
      }
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Order> get _filteredOrders {
    final productKeyword = _productFilterController.text.trim().toLowerCase();
    return _orders.where((order) {
      if (_filterStatus.isNotEmpty && order.status != _filterStatus) {
        return false;
      }

      if (_filterDate != null) {
        final orderDate = order.orderDate;
        if (orderDate.year != _filterDate!.year ||
            orderDate.month != _filterDate!.month ||
            orderDate.day != _filterDate!.day) {
          return false;
        }
      }

      if (productKeyword.isNotEmpty) {
        final matchesProduct = order.items.any(
          (item) => item.shoe.name.toLowerCase().contains(productKeyword),
        );
        if (!matchesProduct) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _reorder(Order order) async {
    try {
      final orderId = await ApiService.createOrder(
        order.items
            .map(
              (item) => {
                'shoeId': item.shoe.id,
                'productVariantId': item.variant.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reorder created successfully (#$orderId).')),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isLoggedIn) {
      return _OrdersAuthPrompt(
        onLogin: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ).then((_) => _loadOrders());
        },
      );
    }

    final orders = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No orders match your filters.'),
              ),
            )
          else
            ...orders.map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _productFilterController,
                decoration: const InputDecoration(
                  labelText: 'Filter by product',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: _filterStatus.isEmpty ? null : _filterStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  'Pending',
                  'Confirmed',
                  'Preparing',
                  'Shipping',
                  'Completed',
                ]
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _filterStatus = value ?? ''),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _filterDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() => _filterDate = pickedDate);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _filterDate == null
                    ? 'Select purchase date'
                    : '${_filterDate!.year}-${_filterDate!.month.toString().padLeft(2, '0')}-${_filterDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _productFilterController.clear();
                  _filterStatus = '';
                  _filterDate = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text('Order #${order.id}'),
        subtitle: Text(
          '${order.status} • ${order.orderDate.toLocal().toString().split('.').first} • \$${order.totalAmount.toStringAsFixed(2)}',
        ),
        children: [
          ...order.items.map(
            (item) => ListTile(
              leading: SizedBox(
                width: 56,
                height: 56,
                child: Image.network(
                  item.shoe.imgAddress,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
                ),
              ),
              title: Text(item.shoe.name),
              subtitle: Text(
                'Code: SNK-${item.shoe.id ?? 0}\n${item.variant.size} / ${item.variant.color}',
              ),
              isThreeLine: true,
              trailing: Text('x${item.quantity}\n\$${item.price.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _reorder(order),
                icon: const Icon(Icons.replay),
                label: const Text('Buy again'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersAuthPrompt extends StatelessWidget {
  const _OrdersAuthPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Login to view your order history',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You can filter by product, purchase date and order status after logging in.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onLogin,
                    child: const Text('Login / Register'),
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
