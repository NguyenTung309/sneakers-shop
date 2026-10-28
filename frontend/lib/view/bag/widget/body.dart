import 'package:flutter/material.dart';

import '../../../models/order_model.dart';
import '../../../services/api_service.dart';
import '../../auth/login_screen.dart';
import '../../checkout_screen.dart';

class BodyBagView extends StatefulWidget {
  const BodyBagView({super.key});

  @override
  State<BodyBagView> createState() => _BodyBagViewState();
}

class _BodyBagViewState extends State<BodyBagView> {
  List<CartItem> _items = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!mounted) {
      return;
    }

    if (!loggedIn) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
        _items = [];
      });
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _isLoading = true;
    });

    try {
      final cart = await ApiService.getCart();
      if (!mounted) {
        return;
      }
      setState(() => _items = cart);
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

  double get _totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.shoe.price * item.quantity));
  }

  Future<void> _removeItem(int cartItemId) async {
    try {
      await ApiService.removeFromCart(cartItemId);
      await _loadCart();
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
      return const _AuthPrompt(
        title: 'Login to access your cart',
        description: 'You can browse products freely, but cart and checkout require authentication.',
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('Your cart is empty.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: Image.network(
                        item.shoe.imgAddress,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
                      ),
                    ),
                    title: Text(item.shoe.name),
                    subtitle: Text(
                      'Code: SNK-${item.shoe.id ?? 0}\n${item.variant.size} / ${item.variant.color}  x${item.quantity}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('\$${(item.shoe.price * item.quantity).toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () => _removeItem(item.id),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CheckoutScreen(cartItems: _items)),
                        ).then((_) => _loadCart());
                      },
                      child: const Text('Proceed to checkout'),
                    ),
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

class _AuthPrompt extends StatelessWidget {
  const _AuthPrompt({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

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
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
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
