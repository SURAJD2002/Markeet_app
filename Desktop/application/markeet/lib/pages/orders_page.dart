import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

// Define the premium color palette for consistency
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _spb = Supabase.instance.client;

  /* ─── core models ─────────────────────────────────────────────── */
  Session? _session;
  List<Map<String, dynamic>> _orders = [];

  /* ─── ui helpers ──────────────────────────────────────────────── */
  bool _loading = true;
  String? _err;
  int _orderPage = 1;
  final int _perPage = 5;

  /* ─── data load ──────────────────────────────────────────────── */
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _session = Provider.of<AppState>(context, listen: false).session;
      if (_session == null) {
        context.go('/auth');
        return;
      }

      // Fetch orders for the buyer
      final base = _spb.from('orders').select('''
        id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
        order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
        profiles!orders_user_id_fkey(email),
        emi_applications(id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at)
      ''').eq('user_id', _session!.user.id).order('created_at', ascending: false);

      // Execute the query and get the result as List<Map<String, dynamic>>
      _orders = await base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1);

      // Fetch store_name for all orders in one query (optimized)
      final sellerIds = _orders.map((order) => order['seller_id']).toSet().toList();
      if (sellerIds.isNotEmpty) {
        final sellers = await retry(() => _spb
            .from('sellers')
            .select('id, store_name')
            .inFilter('id', sellerIds));
        for (var order in _orders) {
          final seller = sellers.firstWhere(
            (s) => s['id'] == order['seller_id'],
            orElse: () => {'store_name': 'Unknown'},
          );
          order['sellers'] = seller;
        }
      } else {
        for (var order in _orders) {
          order['sellers'] = {'store_name': 'Unknown'};
        }
      }
    } catch (e) {
      _err = e.toString();
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        _err = 'Network error: Unable to connect to the server. Please check your internet connection and try again.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ─── lifecycle ──────────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _load();
  }

  /* ─── UI helpers ─────────────────────────────────────────────── */
  Widget _ordersList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'My Orders',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: premiumTextColor,
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      if (_orders.isEmpty)
        const Text(
          'No orders',
          style: TextStyle(color: premiumSecondaryTextColor),
        ),
      ..._orders.map((o) {
        final orderItems = o['order_items'] as List?;
        final firstItem = orderItems != null && orderItems.isNotEmpty ? orderItems[0] : null;
        final productTitle = firstItem != null
            ? (firstItem['products'] != null ? firstItem['products']['title'] ?? 'Unknown Product' : 'Unknown Product')
            : 'N/A';
        final imageUrl = firstItem != null && firstItem['products'] != null
            ? (firstItem['products']['images'] as List?)?.isNotEmpty == true
                ? firstItem['products']['images'][0]
                : 'https://dummyimage.com/150'
            : 'https://dummyimage.com/150';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          color: premiumCardColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 72,
                          color: premiumSecondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${o['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: premiumTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₹${(o['total'] as num?)?.toStringAsFixed(2) ?? '0.00'} • ${o['order_status']}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          if (o['order_status'] == 'Cancelled')
                            Text(
                              'Reason: ${o['cancellation_reason'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          if (o['payment_method'] == 'emi' && o['order_status'] == 'pending')
                            const Text(
                              '(Waiting for EMI Approval)',
                              style: TextStyle(color: Colors.orange, fontSize: 14),
                            ),
                          if (o['estimated_delivery'] != null)
                            Text(
                              'Est. Delivery: ${DateTime.parse(o['estimated_delivery']).toLocal().toString().substring(0, 16)}',
                              style: const TextStyle(fontSize: 14, color: premiumSecondaryTextColor),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Product: $productTitle',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (o['sellers'] != null)
                            Text(
                              'Seller: ${o['sellers']['store_name'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 14, color: premiumSecondaryTextColor),
                            ),
                          if (o['shipping_address'] != null)
                            Text(
                              'Shipping: ${o['shipping_address']}',
                              style: const TextStyle(fontSize: 14, color: premiumSecondaryTextColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered')
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () {
                              // Implement cancellation dialog
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/order-details/${o['id']}'),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(
          onPressed: _orderPage == 1
              ? null
              : () async {
                  _orderPage--;
                  await _load();
                },
          child: const Text('Prev', style: TextStyle(color: premiumPrimaryColor)),
        ),
        Text('Page $_orderPage', style: const TextStyle(color: premiumTextColor)),
        TextButton(
          onPressed: _orders.length < _perPage
              ? null
              : () async {
                  _orderPage++;
                  await _load();
                },
          child: const Text('Next', style: TextStyle(color: premiumPrimaryColor)),
        ),
      ])
    ]);
  }

  /* ─── build ──────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_err != null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error: $_err',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
        backgroundColor: premiumCardColor,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ordersList(),
            ],
          ),
        ),
      ),
    );
  }
}