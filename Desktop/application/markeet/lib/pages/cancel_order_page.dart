import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Added provider import
import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

class CancelOrderPage extends StatefulWidget {
  final String id;
  const CancelOrderPage({super.key, required this.id});

  @override
  State<CancelOrderPage> createState() => _CancelOrderPageState();
}

class _CancelOrderPageState extends State<CancelOrderPage> {
  final _spb = Supabase.instance.client;
  bool _loading = false;
  String? _error;
  String? _message;
  String _cancelReason = '';
  bool _isCustomReason = false;
  final _buyerReasons = [
    'Changed my mind',
    'Found a better price',
    'No longer needed',
    'Other (please specify)',
  ];

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = Provider.of<AppState>(context, listen: false).session;
    if (session == null) {
      context.go('/auth');
    }
  }

  Future<void> _cancelOrder(String reason) async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final session = Provider.of<AppState>(context, listen: false).session;
      if (session == null) {
        setState(() => _error = 'Authentication required. Please log in.');
        context.go('/auth');
        return;
      }

      final userId = session.user.id;
      // Fetch order with order_items and related products
      final orderData = await retry(() => _spb
          .from('orders')
          .select('user_id, seller_id, order_items(*, products(id))')
          .eq('id', widget.id)
          .single());

      final isBuyer = orderData['user_id'] == userId;
      final isSeller = orderData['seller_id'] == userId;

      if (!isBuyer && !isSeller) {
        setState(() => _error = 'You are not authorized to cancel this order.');
        return;
      }

      // Update order status and reason
      await retry(() => _spb
          .from('orders')
          .update({'order_status': 'Cancelled', 'cancellation_reason': reason})
          .eq('id', widget.id));

      // Update related products
      final orderItems = orderData['order_items'] as List<dynamic>? ?? [];
      for (var item in orderItems) {
        if (item != null && item['products'] != null && item['products']['id'] != null) {
          await retry(() => _spb
              .from('products')
              .update({'status': 'cancelled', 'cancel_reason': reason})
              .eq('id', item['products']['id']));
        }
      }

      setState(() => _message = 'Order cancelled successfully!');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/orders');
      });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cancel Order #${widget.id}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 16),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Why do you want to cancel this order?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _cancelReason.isEmpty ? null : _cancelReason,
                      hint: const Text('Select a Reason'),
                      isExpanded: true,
                      items: _buyerReasons
                          .map((reason) => DropdownMenuItem(
                                value: reason,
                                child: Text(reason),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _cancelReason = value ?? '';
                          _isCustomReason = value == 'Other (please specify)';
                        });
                      },
                    ),
                    if (_isCustomReason)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextField(
                          onChanged: (value) => setState(() => _cancelReason = value),
                          decoration: const InputDecoration(
                            labelText: 'Enter your reason',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _cancelReason.isEmpty || _loading
                              ? null
                              : () => _cancelOrder(_cancelReason),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            _loading ? 'Cancelling...' : 'Confirm Cancel',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _loading ? null : () => context.go('/orders'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.home, color: Colors.blueAccent),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => context.go('/cart'),
                        icon: const Icon(Icons.shopping_cart, color: Colors.blueAccent),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/categories'),
                    child: const Text(
                      'Categories',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
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