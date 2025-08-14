// // lib/pages/cart_page.dart
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';

// class CartPage extends StatefulWidget {
//   const CartPage({super.key});

//   @override
//   State<CartPage> createState() => _CartPageState();
// }

// class _CartPageState extends State<CartPage> {
//   final _spb = Supabase.instance.client;

//   List<Map<String, dynamic>> _items = [];
//   bool _loading = true;
//   String? _error;

//   /* ───────────────── helpers ───────────────── */

//   Future<void> _load() async {
//     final session = context.read<AppState>().session;
//     if (session == null) return context.go('/auth');

//     setState(() {
//       _loading = true;
//       _error   = null;
//     });

//     try {
//       final rows = await _spb
//           .from('cart')
//           .select('''
//             id,
//             quantity,
//             products!cart_product_id_fkey (
//               id, title, price, images
//             )
//           ''')
//           .eq('user_id', session.user.id)
//           .order('id');

//       _items = (rows as List).cast<Map<String, dynamic>>();
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _updateQty(int cartId, int newQty) async {
//     await _spb.from('cart').update({'quantity': newQty}).eq('id', cartId);
//     await _load();
//     context.read<AppState>().refreshCartCount();
//   }

//   Future<void> _deleteItem(int cartId) async {
//     await _spb.from('cart').delete().eq('id', cartId);
//     await _load();
//     context.read<AppState>().refreshCartCount();
//   }

//   /* ───────────── lifecycle ───────────── */

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   /* ─────────────── UI ─────────────── */

//   @override
//   Widget build(BuildContext context) {
//     /* LOADING */
//     if (_loading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Cart')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     /* ERROR */
//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Cart')),
//         body: Center(child: Text('Error loading cart:\n$_error')),
//       );
//     }

//     /* EMPTY */
//     if (_items.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Cart')),
//         body: const Center(child: Text('Your cart is empty')),
//       );
//     }

//     /* CONTENT */
//     final total = _items.fold<num>(
//       0,
//       (sum, e) =>
//           sum + (e['products']['price'] as num) * (e['quantity'] as num),
//     );

//     return Scaffold(
//       appBar: AppBar(title: const Text('Cart')),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             ..._items.map((e) {
//               final prod = e['products'];
//               final img  = (prod['images'] as List).isNotEmpty
//                   ? prod['images'][0]
//                   : 'https://dummyimage.com/100';
//               final qty  = e['quantity'] as int;

//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   leading: Image.network(img,
//                       width: 56, height: 56, fit: BoxFit.cover),
//                   title: Text(prod['title'] ?? 'Unnamed'),
//                   subtitle: Text('₹${prod['price']}'),
//                   trailing: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.remove),
//                             onPressed:
//                                 qty == 1 ? null : () => _updateQty(e['id'], qty - 1),
//                           ),
//                           Text('$qty'),
//                           IconButton(
//                             icon: const Icon(Icons.add),
//                             onPressed: () => _updateQty(e['id'], qty + 1),
//                           ),
//                         ],
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.delete_outline),
//                         onPressed: () => _deleteItem(e['id']),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//             const SizedBox(height: 12),
//             Text('Total: ₹$total',
//                 style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => context.push('/checkout'),
//               child: const Text('Proceed to checkout'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _spb = Supabase.instance.client;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  /* ───────────────── Helpers ───────────────── */

  Future<void> _load() async {
    final session = context.read<AppState>().session;
    if (session == null) {
      context.go('/auth');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await retry(() => _spb.from('cart').select('''
          id,
          quantity,
          products!cart_product_id_fkey (
            id, title, price, original_price, images, stock, seller_id,
            sellers (store_name)
          )
        ''').eq('user_id', session.user.id).order('id'));

      setState(() {
        _items = List<Map<String, dynamic>>.from(rows);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cart: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateQty(int cartId, int newQty) async {
    final item = _items.firstWhere((e) => e['id'] == cartId);
    final product = item['products'];
    final stock = product['stock'] as int? ?? 0;

    if (newQty <= 0) {
      _showSnackBar('Quantity must be at least 1.');
      return;
    }
    if (newQty > stock) {
      _showSnackBar('Cannot add more items. Only $stock left in stock.');
      return;
    }

    try {
      await retry(() => _spb.from('cart').update({'quantity': newQty}).eq('id', cartId));
      await _load();
      context.read<AppState>().refreshCartCount();
      _showSnackBar('Quantity updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to update quantity: $e');
    }
  }

  Future<void> _deleteItem(int cartId) async {
    final confirm = await _showConfirmationDialog(
      title: 'Remove Item',
      message: 'Are you sure you want to remove this item from your cart?',
    );
    if (!confirm) return;

    try {
      await retry(() => _spb.from('cart').delete().eq('id', cartId));
      await _load();
      context.read<AppState>().refreshCartCount();
      _showSnackBar('Item removed from cart.');
    } catch (e) {
      _showSnackBar('Failed to remove item: $e');
    }
  }

  Future<void> _clearCart() async {
    final confirm = await _showConfirmationDialog(
      title: 'Clear Cart',
      message: 'Are you sure you want to remove all items from your cart?',
    );
    if (!confirm) return;

    try {
      final session = context.read<AppState>().session;
      if (session == null) throw Exception('User not logged in.');
      await retry(() => _spb.from('cart').delete().eq('user_id', session.user.id));
      await _load();
      context.read<AppState>().refreshCartCount();
      _showSnackBar('Cart cleared successfully.');
    } catch (e) {
      _showSnackBar('Failed to clear cart: $e');
    }
  }

  void _proceedToCheckout() {
    final buyerLoc = context.read<AppState>().buyerLocation;
    if (buyerLoc == null) {
      _showSnackBar('Please set your location in the Account page before proceeding.');
      context.push('/account');
      return;
    }
    context.push('/checkout');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: message.contains('Failed') ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmationDialog({required String title, required String message}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 56,
            height: 56,
            color: Colors.white,
          ),
          title: Container(
            width: 100,
            height: 16,
            color: Colors.white,
          ),
          subtitle: Container(
            width: 50,
            height: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /* ───────────── Lifecycle ───────────── */

  @override
  void initState() {
    super.initState();
    _load();
  }

  /* ─────────────── UI ─────────────── */

  @override
  Widget build(BuildContext context) {
    /* LOADING */
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(3, (_) => _buildShimmer()),
        ),
      );
    }

    /* ERROR */
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading cart',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    /* EMPTY */
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 64),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text('Add some items to get started!'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    /* CONTENT */
    final total = _items.fold<double>(
      0,
      (sum, e) => sum + (e['products']['price'] as num) * (e['quantity'] as num),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._items.map((e) {
              final prod = e['products'];
              final img = (prod['images'] as List?)?.isNotEmpty == true
                  ? prod['images'][0]
                  : 'https://dummyimage.com/100';
              final qty = e['quantity'] as int;
              final price = (prod['price'] as num?)?.toDouble() ?? 0.0;
              final originalPrice = (prod['original_price'] as num?)?.toDouble() ?? price;
              final subtotal = price * qty;
              final stock = prod['stock'] as int? ?? 0;
              final storeName = prod['sellers']?['store_name'] ?? 'Unknown Store';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: img,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 72,
                              height: 72,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_not_supported,
                            size: 72,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod['title'] ?? 'Unnamed Product',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                if (price != originalPrice) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${originalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subtotal: ₹${subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: stock > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.blueAccent),
                                onPressed: qty == 1 ? null : () => _updateQty(e['id'], qty - 1),
                                tooltip: 'Decrease Quantity',
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                                onPressed: () => _updateQty(e['id'], qty + 1),
                                tooltip: 'Increase Quantity',
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(e['id']),
                            tooltip: 'Remove Item',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _items.isEmpty ? null : _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                shadowColor: Colors.blueAccent.withOpacity(0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Proceed to Checkout',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}