import 'package:flutter/material.dart';

import '../../../models/shoe_model.dart';
import '../../../services/api_service.dart';
import '../../auth/login_screen.dart';

class DetailsBody extends StatefulWidget {
  const DetailsBody({super.key, required this.shoe});

  final ShoeModel shoe;

  @override
  State<DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends State<DetailsBody> {
  final _reviewController = TextEditingController();

  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isBusy = false;
  bool _isSubmittingReview = false;
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    final variants = widget.shoe.variants;
    if (variants != null && variants.isNotEmpty) {
      _selectedVariant = variants.first;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<bool> _ensureLoggedIn() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (loggedIn) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login before continuing.')),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return ApiService.isLoggedIn();
  }

  Future<void> _addToCart() async {
    final variant = _selectedVariant;
    if (variant == null) {
      return;
    }
    if (!await _ensureLoggedIn()) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ApiService.addToCart(widget.shoe.id!, variant.id, _quantity);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _buyNow() async {
    final variant = _selectedVariant;
    if (variant == null) {
      return;
    }
    if (!await _ensureLoggedIn()) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final orderId = await ApiService.createOrder([
        {
          'shoeId': widget.shoe.id,
          'productVariantId': variant.id,
          'quantity': _quantity,
        }
      ]);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId created successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      return;
    }
    if (!await _ensureLoggedIn()) {
      return;
    }

    setState(() => _isSubmittingReview = true);
    try {
      await ApiService.addReview(widget.shoe.id!, _rating, _reviewController.text);
      final refreshedProduct = await ApiService.getShoe(widget.shoe.id!);

      if (!mounted) {
        return;
      }

      _reviewController.clear();
      setState(() {
        widget.shoe.reviews = refreshedProduct.reviews;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.shoe.reviews ?? <Review>[];
    final variants = widget.shoe.variants ?? <ProductVariant>[];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _imageSection()),
                  const SizedBox(width: 24),
                  Expanded(child: _summarySection(variants)),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _imageSection(),
                const SizedBox(height: 20),
                _summarySection(variants),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _reviewComposer(),
        const SizedBox(height: 24),
        _reviewsSection(reviews),
      ],
    );
  }

  Widget _imageSection() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Container(
          color: widget.shoe.modelColor.withValues(alpha: 0.14),
          child: Image.network(
            widget.shoe.imgAddress,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.image_outlined, size: 72),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summarySection(List<ProductVariant> variants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.shoe.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(widget.shoe.brand, style: const TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          '\$${widget.shoe.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('Product code: SNK-${widget.shoe.id ?? 0}'),
        const SizedBox(height: 8),
        Text(
          widget.shoe.description.isEmpty ? 'No description available.' : widget.shoe.description,
        ),
        const SizedBox(height: 20),
        const Text('Available variants', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (variants.isEmpty)
          const Text('No variants available.')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: variants.map((variant) {
              final selected = _selectedVariant?.id == variant.id;
              return ChoiceChip(
                selected: selected,
                label: Text('${variant.size} / ${variant.color} (${variant.stock})'),
                onSelected: (_) {
                  setState(() => _selectedVariant = variant);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_quantity'),
            IconButton(
              onPressed: () => setState(() => _quantity++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _isBusy ? null : _addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to cart'),
            ),
            OutlinedButton.icon(
              onPressed: _isBusy ? null : _buyNow,
              icon: const Icon(Icons.flash_on_outlined),
              label: const Text('Buy now'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _rating,
              decoration: const InputDecoration(
                labelText: 'Rating',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1} star'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _rating = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmittingReview ? null : _submitReview,
              child: _isSubmittingReview
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewsSection(List<Review> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews (${reviews.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No reviews yet.'),
            ),
          )
        else
          ...reviews.map((review) {
            return Card(
              child: ListTile(
                title: Text(review.userName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(review.comment),
                    const SizedBox(height: 6),
                    Text(
                      review.createdAt.toLocal().toString().split('.').first,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
