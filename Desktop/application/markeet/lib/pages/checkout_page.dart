

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../state/app_state.dart';

/* ────────────────────────────────────────────────────────── */

const _blrCoords = {'lat': 12.9753, 'lon': 77.591};
const _blrAddr = 'Bangalore, Karnataka 560001, India';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _spb = Supabase.instance.client;

  /* ────── cart / product data ────── */
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _prods = [];

  /* ────── UI state ────── */
  bool _loading = true;
  String? _err;
  bool _detecting = false;
  bool _orderConfirmed = false;
  String _locationMessage = '';
  bool _showManualLocation = false;
  String? _addressError;

  /* ────── shipping info ────── */
  Map<String, double>? _loc;
  final _addrCtrl = TextEditingController(text: _blrAddr);
  final _manualLatCtrl = TextEditingController();
  final _manualLonCtrl = TextEditingController();

  /* ────── payment ────── */
  String _payMethod = 'credit_card';

  /* ════════════════════════════════════════════════════════ */
  /// Simple haversine distance
  double _distanceKm(Map<String, double> a, Map<String, double> b) {
    const R = 6371.0;
    final dLat = (b['lat']! - a['lat']!) * math.pi / 180;
    final dLon = (b['lon']! - a['lon']!) * math.pi / 180;
    final lat1 = a['lat']! * math.pi / 180;
    final lat2 = b['lat']! * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  /// Tiny retry helper for flaky networks
  Future<T> _retry<T>(Future<T> Function() fn,
      {int times = 3, Duration delay = const Duration(seconds: 1)}) async {
    for (var i = 0; i < times; i++) {
      try {
        return await fn();
      } catch (_) {
        if (i == times - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    throw Exception('retry failed');
  }

  /// Fetch address from coordinates using Nominatim API
  Future<void> _fetchAddress(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'Markeet/1.0'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch address');
      }
      final data = jsonDecode(response.body);
      final newAddress = data['display_name'] ?? _blrAddr;
      _addrCtrl.text = newAddress;
      setState(() => _locationMessage = 'Address fetched successfully.');
    } catch (e) {
      _addrCtrl.text = _blrAddr;
      setState(() {
        _locationMessage = 'Error fetching address. Please enter manually.';
      });
    }
  }

  /// Validate shipping address
  String? _validateAddress(String address) {
    if (address.trim().length < 5) {
      return 'Please provide a valid shipping address (minimum 5 characters).';
    }
    final components = address.split(RegExp(r',\s*|\s+')).where((c) => c.isNotEmpty).toList();
    if (components.isEmpty) {
      return 'Shipping address must include at least one component (e.g., city).';
    }
    final hasCity = components.any((comp) => RegExp(r'^[A-Za-z\s-]+$').hasMatch(comp));
    if (!hasCity) {
      return 'Shipping address must include a city (e.g., Bangalore).';
    }
    return null;
  }

  /* ───────────────────────── load cart/products ─────────── */
  Future<void> _load() async {
    final session = context.read<AppState>().session;
    if (session == null) return context.go('/auth');

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final rawCart = await _spb
          .from('cart')
          .select('product_id, quantity, variant_id')
          .eq('user_id', session.user.id);

      _cart = (rawCart as List<dynamic>).cast<Map<String, dynamic>>();
      if (_cart.isEmpty) throw 'Cart empty';

      final ids = _cart.map((e) => e['product_id']).toList();
      final rawProds = await _spb
          .from('products')
          .select('id, seller_id, title, price, images')
          .inFilter('id', ids)
          .eq('is_approved', true);

      _prods = (rawProds as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      _err = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ───────────────────────── detect GPS ─────────────────── */
Future<void> _detectLoc() async {
  if (_detecting) return;
  setState(() {
    _detecting = true;
    _locationMessage = 'Detecting location...';
  });

  try {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw 'Location denied';
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _loc = {'lat': pos.latitude, 'lon': pos.longitude};
      if (_loc != null && _loc!['lat'] != null && _loc!['lon'] != null) {
        context.read<AppState>().setBuyerLocation(_loc!['lat']!, _loc!['lon']!);
      }
    });
    await _fetchAddress(pos.latitude, pos.longitude);
    setState(() => _locationMessage = 'Location detected successfully.');
  } catch (e) {
    if (mounted) {
      setState(() {
        _loc = _blrCoords;
        _locationMessage =
            'Location permission denied or timed out. Please enter manually.';
        _showManualLocation = true;
      });
      if (_loc != null && _loc!['lat'] != null && _loc!['lon'] != null) {
        context.read<AppState>().setBuyerLocation(_loc!['lat']!, _loc!['lon']!);
      }
    }
  } finally {
    if (mounted) setState(() => _detecting = false);
  }
}

/* ───────────────────────── manual location update ─────── */
Future<void> _handleManualLocationUpdate() async {
  final lat = double.tryParse(_manualLatCtrl.text);
  final lon = double.tryParse(_manualLonCtrl.text);

  if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    setState(() => _locationMessage = 'Invalid latitude or longitude values.');
    return;
  }

  setState(() {
    _loc = {'lat': lat, 'lon': lon};
    context.read<AppState>().setBuyerLocation(lat, lon);
    _showManualLocation = false;
    _manualLatCtrl.clear();
    _manualLonCtrl.clear();
    _locationMessage = 'Manual location set successfully.';
  });

  await _fetchAddress(lat, lon);
}
  /* ───────────────────────── group cart by seller ─────────── */
  Map<String, List<Map<String, dynamic>>> _groupCartItemsBySeller() {
    final bySeller = <String, List<Map<String, dynamic>>>{};
    for (final row in _cart) {
      final prod = _prods.firstWhere((p) => p['id'] == row['product_id']);
      final sid = prod['seller_id'] as String;
      bySeller.putIfAbsent(sid, () => []).add({
        ...row,
        'price': prod['price'],
      });
    }
    return bySeller;
  }

  /* ───────────────────────── apply EMI ─────────────────── */
  void _handleApplyEMI() {
    final itemsBySeller = _groupCartItemsBySeller();
    if (itemsBySeller.keys.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'EMI can only be applied for products from a single seller. Please adjust your cart.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_prods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products in cart to apply for EMI.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use the first product for EMI application
    final firstProduct = _prods.first;
    final productId = firstProduct['id'] as String;
    final productName = firstProduct['title'] as String? ?? 'Unnamed Product';
    final productPrice = (firstProduct['price'] as num).toDouble();
    final sellerId = firstProduct['seller_id'] as String;

    context.push(
      '/apply-emi/$productId/${Uri.encodeComponent(productName)}/$productPrice/$sellerId',
    );
  }

  /* ───────────────────────── place orders ───────────────── */
  Future<void> _placeOrders() async {
    final session = context.read<AppState>().session!;
    final loc = _loc ?? _blrCoords;
    final address = _addrCtrl.text.trim();

    final addressValidationError = _validateAddress(address);
    if (addressValidationError != null) {
      setState(() => _addressError = addressValidationError);
      return;
    }

    setState(() {
      _loading = true;
      _addressError = null;
    });

    try {
      final bySeller = _groupCartItemsBySeller();
      final newOrderIds = <int>[];

      for (final sid in bySeller.keys) {
        final items = bySeller[sid]!;
        final subTotal = items.fold<num>(0, (s, e) => s + e['price'] * e['quantity']);

        final sellerData = await _retry(() => _spb
            .from('sellers')
            .select('latitude, longitude')
            .eq('id', sid)
            .single());

        final sellerLoc = sellerData != null
            ? {
                'lat': (sellerData['latitude'] as num?)?.toDouble() ?? 0.0,
                'lon': (sellerData['longitude'] as num?)?.toDouble() ?? 0.0,
              }
            : null;
        final distance = sellerLoc != null ? _distanceKm(loc, sellerLoc) : 40;
        final baseHours = distance <= 40 ? 3 : 24;
        final deliveryOffset = baseHours + math.Random().nextInt(12);
        final eta = DateTime.now().add(Duration(hours: deliveryOffset));

        final order = await _retry(() => _spb.from('orders').insert({
              'user_id': session.user.id,
              'seller_id': sid,
              'total': subTotal,
              'order_status': 'pending',
              'payment_method': _payMethod,
              'shipping_location': 'POINT(${loc['lon']} ${loc['lat']})',
              'shipping_address': address,
              'estimated_delivery': eta.toIso8601String(),
            }).select().single());

        await _retry(() => _spb.from('order_items').insert(items.map((i) => {
              'order_id': order['id'],
              'product_id': i['product_id'],
              'variant_id': i['variant_id'],
              'quantity': i['quantity'],
              'price': i['price'],
            }).toList()));

        newOrderIds.add(order['id']);
      }

      await _spb.from('cart').delete().eq('user_id', session.user.id);
      context.read<AppState>().refreshCartCount();

      setState(() => _orderConfirmed = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/account', extra: {'newOrderIds': newOrderIds});
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ───────────────────────── lifecycle ─────────────────── */
  @override
  void initState() {
    super.initState();
    _loc = context.read<AppState>().buyerLocation ?? _blrCoords;
    if (_loc != _blrCoords) {
      _fetchAddress(_loc!['lat']!, _loc!['lon']!);
    }
    _load();
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _manualLatCtrl.dispose();
    _manualLonCtrl.dispose();
    super.dispose();
  }

  /* ───────────────────────── UI ─────────────────────────── */
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_err != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(child: Text('Error: $_err')),
      );
    }

    if (_orderConfirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Order Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Your orders have been placed successfully.'),
              Text('Redirecting to your account...'),
            ],
          ),
        ),
      );
    }

    final total = _cart.fold<num>(
      0,
      (sum, row) =>
          sum +
          (_prods.firstWhere((p) => p['id'] == row['product_id'])['price']
              as num) *
          (row['quantity'] as num),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Markeet Checkout',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
          ),
          const SizedBox(height: 16),
          if (_cart.isEmpty) ...[
            const Text('Your cart is empty'),
          ] else ...[
            ..._cart.map((row) {
              final prod =
                  _prods.firstWhere((p) => p['id'] == row['product_id']);
              final img = (prod['images'] as List).isNotEmpty
                  ? prod['images'][0]
                  : 'https://dummyimage.com/100';
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      img,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported,
                              size: 56, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    prod['title'] ?? 'Unnamed Product',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Qty ${row['quantity']} • ₹${prod['price']}'),
                ),
              );
            }),
            const Divider(),
            Text(
              'Order Summary (All Sellers)',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            /* Address */
            Text(
              'Shipping Address',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addrCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Shipping address',
                hintText:
                    'Enter your address (e.g., 123 Main St, Bangalore, Karnataka, India)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final error = _validateAddress(value);
                setState(() => _addressError = error);
              },
            ),
            if (_addressError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _addressError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: _detecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: const Text('Detect my location'),
              onPressed: _detecting ? null : _detectLoc,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            if (_locationMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _locationMessage,
                  style: TextStyle(
                      color: _locationMessage.contains('Error')
                          ? Colors.red
                          : Colors.green),
                ),
              ),
            if (_loc != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Location: Lat ${_loc!['lat']?.toStringAsFixed(4)}, Lon ${_loc!['lon']?.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            if (_showManualLocation) ...[
              const SizedBox(height: 12),
              const Text(
                'Enter location manually:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _manualLatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Latitude (-90 to 90)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _manualLonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Longitude (-180 to 180)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _handleManualLocationUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit Manual Location'),
              ),
            ],
            const SizedBox(height: 24),

            /* Payment */
            Text(
              'Payment Method',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _payMethod,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'cod', child: Text('Cash on Delivery')),
              ],
              onChanged: (v) => setState(() => _payMethod = v!),
            ),
            const SizedBox(height: 16),

            /* EMI Option */
            ElevatedButton(
              onPressed: _handleApplyEMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Text(
                'Apply for EMI (No Credit Card Needed)',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),

            /* Place Orders */
            ElevatedButton(
              onPressed: _loading ? null : _placeOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text(
                _loading ? 'Processing...' : 'Place Orders',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}