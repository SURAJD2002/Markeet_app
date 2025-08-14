// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:dio/dio.dart'; // ← Added Dio import

// import '../state/app_state.dart';

// const _defaultLocation = {'lat': 12.9753, 'lon': 77.591};

// class SellerPage extends StatefulWidget {
//   const SellerPage({super.key});

//   @override
//   State<SellerPage> createState() => _SellerPageState();
// }

// class _SellerPageState extends State<SellerPage> {
//   final _spb = Supabase.instance.client;

//   // Core models
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];
//   List<Map<String, dynamic>> _emiOrders = [];

//   // UI helpers
//   bool _loading = true;
//   String? _error;
//   String _locationMessage = '';
//   String _address = 'Not set';
//   Map<String, double>? _sellerLocation;

//   // Pagination
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // Distance calculation
//   double _distKm(Map<String, double> a, Map<String, double> b) {
//     const R = 6371.0;
//     final dLat = (b['lat']! - a['lat']!) * math.pi / 180;
//     final dLon = (b['lon']! - a['lon']!) * math.pi / 180;
//     final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['lat']! * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
//   }

//   // Retry logic for network calls
//   Future<T> _retry<T>(Future<T> Function() fn, {int n = 3}) async {
//     for (var i = 0; i < n; i++) {
//       try {
//         return await fn();
//       } catch (_) {
//         if (i == n - 1) rethrow;
//         await Future.delayed(Duration(milliseconds: 800 * (i + 1)));
//       }
//     }
//     throw Exception('unreachable');
//   }

//   // Fetch address using Nominatim (open-source geocoding)
//   Future<String> _fetchAddress(double? lat, double? lon) async {
//     if (lat == null || lon == null) return 'Coordinates unavailable';
//     try {
//       final dio = Dio(); // ← Create Dio instance
//       final response = await dio.get(
//         'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
//       );
//       if (response.statusCode == 200 && response.data['display_name'] != null) {
//         return response.data['display_name'];
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Error fetching address: $e';
//     }
//   }

//   // Load seller data
//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       // Profile
//       _profile = await _spb
//           .from('profiles')
//           .select('is_seller, email, full_name, phone_number')
//           .eq('id', _session!.user.id)
//           .single();
//       if (_profile?['is_seller'] != true) {
//         _error = 'You do not have permission to access seller functions.';
//         context.go('/account');
//         return;
//       }

//       // Seller
//       _seller = await _spb
//           .from('sellers')
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single();
//       if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//         _sellerLocation = {
//           'lat': _seller!['latitude'],
//           'lon': _seller!['longitude']
//         };
//         _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
//       }

//       // Products
//       _products = await _spb
//           .from('products')
//           .select('id, title, price, images, stock, product_variants(id, attributes, price, stock, images)')
//           .eq('seller_id', _session!.user.id)
//           .eq('is_approved', true)
//           .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1);

//       // Non-EMI Orders
//       _orders = await _spb
//           .from('orders')
//           .select('*, order_items(product_id, quantity, price, products(title, images))')
//           .eq('seller_id', _session!.user.id)
//           .neq('payment_method', 'emi')
//           .range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1);

//       // EMI Orders
//       _emiOrders = await _spb
//           .from('orders')
//           .select('''
//             *, 
//             emi_applications!orders_emi_application_uuid_fkey(product_name, product_price, full_name, mobile_number, status),
//             profiles!orders_user_id_fkey(email)
//           ''')
//           .eq('seller_id', _session!.user.id)
//           .eq('payment_method', 'emi')
//           .range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1);
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Detect location
//   Future<void> _detectLocation() async {
//     setState(() => _locationMessage = 'Detecting…');
//     try {
//       await Geolocator.requestPermission();
//       final position = await Geolocator.getCurrentPosition();
//       await _setSellerLocation(position.latitude, position.longitude);
//     } catch (e) {
//       setState(() => _locationMessage = 'Failed: $e');
//     }
//   }

//   // Set seller location
//   Future<void> _setSellerLocation(double lat, double lon) async {
//     try {
//       final storeName = _seller?['store_name'] ?? 'Default Store';
//       await _retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': storeName,
//           }));
//       _sellerLocation = {'lat': lat, 'lon': lon};
//       _address = await _fetchAddress(lat, lon);
//       setState(() => _locationMessage = 'Location updated: $_address');
//       await _load();
//     } catch (e) {
//       setState(() => _locationMessage = 'Error: $e');
//     }
//   }

//   // Delete product
//   Future<void> _deleteProduct(String productId) async {
//     if (!await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Delete Product'),
//         content: const Text('Are you sure you want to delete this product?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     )) return;

//     setState(() => _loading = true);
//     try {
//       await _spb
//           .from('products')
//           .delete()
//           .eq('id', productId)
//           .eq('seller_id', _session!.user.id);
//       setState(() => _locationMessage = 'Product deleted successfully!');
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error deleting product: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   // UI Components
//   Widget _storeDetails() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Store Details', style: Theme.of(context).textTheme.headlineSmall),
//             const SizedBox(height: 8),
//             Text('Store: ${_seller?['store_name'] ?? 'Unnamed Store'}'),
//             Text('Email: ${_profile?['email'] ?? 'N/A'}'),
//             Text('Name: ${_profile?['full_name'] ?? 'Not set'}'),
//             Text('Phone: ${_profile?['phone_number'] ?? 'Not set'}'),
//             Text('Location: $_address'),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _detectLocation,
//               child: const Text('Detect Current Location'),
//             ),
//             if (_locationMessage.isNotEmpty)
//               Text(
//                 _locationMessage,
//                 style: TextStyle(
//                   color: _locationMessage.contains('Error') ? Colors.red : Colors.green,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _productsList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('My Products', style: Theme.of(context).textTheme.headlineSmall),
//             ElevatedButton(
//               onPressed: _sellerLocation == null
//                   ? null
//                   : () => context.push('/seller/add-product'),
//               child: const Text('Add Product'),
//             ),
//           ],
//         ),
//         if (_products.isEmpty) const Text('No products found.'),
//         ..._products.map((prod) => Card(
//               child: ListTile(
//                 leading: prod['images'].isNotEmpty
//                     ? Image.network(prod['images'][0], width: 50, height: 50, fit: BoxFit.cover)
//                     : const Icon(Icons.image),
//                 title: Text(prod['title'] ?? 'Unnamed Product'),
//                 subtitle: Text('Price: ₹${prod['price']?.toStringAsFixed(2) ?? '0'} | Stock: ${prod['stock'] ?? 0}'),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => _deleteProduct(prod['id']),
//                 ),
//               ),
//             )),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             TextButton(
//               onPressed: _prodPage == 1
//                   ? null
//                   : () async {
//                       setState(() => _prodPage--);
//                       await _load();
//                     },
//               child: const Text('Prev'),
//             ),
//             Text('Page $_prodPage'),
//             TextButton(
//               onPressed: _products.length < _perPage
//                   ? null
//                   : () async {
//                       setState(() => _prodPage++);
//                       await _load();
//                     },
//               child: const Text('Next'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _ordersList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Buyer Orders', style: Theme.of(context).textTheme.headlineSmall),
//         if (_orders.isEmpty) const Text('No non-EMI orders found.'),
//         ..._orders.map((order) => Card(
//               child: ListTile(
//                 title: Text('Order #${order['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Total: ₹${order['total']?.toStringAsFixed(2) ?? '0'}'),
//                     Text('Status: ${order['order_status'] ?? 'N/A'}'),
//                     if (order['order_items'].isNotEmpty)
//                       Text('Item: ${order['order_items'][0]['products']['title'] ?? 'Unnamed'}'),
//                   ],
//                 ),
//                 onTap: () => context.push('/order-details/${order['id']}'),
//               ),
//             )),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             TextButton(
//               onPressed: _orderPage == 1
//                   ? null
//                   : () async {
//                       setState(() => _orderPage--);
//                       await _load();
//                     },
//               child: const Text('Prev'),
//             ),
//             Text('Page $_orderPage'),
//             TextButton(
//               onPressed: _orders.length < _perPage
//                   ? null
//                   : () async {
//                       setState(() => _orderPage++);
//                       await _load();
//                     },
//               child: const Text('Next'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _emiOrdersList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Pending EMI Orders', style: Theme.of(context).textTheme.headlineSmall),
//         if (_emiOrders.isEmpty) const Text('No pending EMI orders found.'),
//         ..._emiOrders.map((order) => Card(
//               child: ListTile(
//                 title: Text('Order #${order['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Buyer: ${order['emi_applications']['full_name'] ?? 'Unknown'}'),
//                     Text('Total: ₹${order['total']?.toStringAsFixed(2) ?? '0'}'),
//                     Text('EMI Status: ${order['emi_applications']['status'] ?? 'N/A'}'),
//                     Text('Product: ${order['emi_applications']['product_name'] ?? 'N/A'}'),
//                   ],
//                 ),
//                 onTap: () => context.push('/order-details/${order['id']}'),
//               ),
//             )),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_error != null) {
//       return Scaffold(body: Center(child: Text('Error: $_error')));
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text('Seller Dashboard - ${_seller?['store_name'] ?? 'Unnamed Store'}')),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _storeDetails(),
//               const SizedBox(height: 16),
//               _productsList(),
//               const SizedBox(height: 16),
//               _ordersList(),
//               const SizedBox(height: 16),
//               _emiOrdersList(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:dio/dio.dart';

// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// const _defaultLocation = {'lat': 12.9753, 'lon': 77.591};

// class SellerPage extends StatefulWidget {
//   const SellerPage({super.key});

//   @override
//   State<SellerPage> createState() => _SellerPageState();
// }

// class _SellerPageState extends State<SellerPage> {
//   final _spb = Supabase.instance.client;

//   // Core models
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];

//   // UI helpers
//   bool _loading = true;
//   String? _error;
//   String _locationMessage = '';
//   String _address = 'Not set';
//   Map<String, double>? _sellerLocation;
//   bool _showManualLoc = false;
//   final _latC = TextEditingController();
//   final _lonC = TextEditingController();

//   // Pagination
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // EMI status updates
//   Map<int, String> _emiStatusUpdates = {};

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   @override
//   void dispose() {
//     _latC.dispose();
//     _lonC.dispose();
//     super.dispose();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       // Profile
//       _profile = await retry(() => _spb
//           .from('profiles')
//           .select('is_seller, email, full_name, phone_number')
//           .eq('id', _session!.user.id)
//           .single());
//       if (_profile?['is_seller'] != true) {
//         _error = 'You do not have permission to access seller functions.';
//         context.go('/account');
//         return;
//       }

//       // Seller
//       _seller = await retry(() => _spb
//           .from('sellers')
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single());
//       if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//         _sellerLocation = {
//           'lat': _seller!['latitude'],
//           'lon': _seller!['longitude']
//         };
//         _address = await fetchAddress(_seller!['latitude'], _seller!['longitude']);
//         _checkDistance();
//       }

//       // Products
//       _products = await retry(() => _spb
//           .from('products')
//           .select('id, title, price, images, stock, product_variants(id, attributes, price, stock, images)')
//           .eq('seller_id', _session!.user.id)
//           .eq('is_approved', true)
//           .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));

//       // Orders (including EMI)
//       _orders = await retry(() => _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(status, product_name, product_price, full_name, mobile_number, uuid),
//         profiles!orders_user_id_fkey(email)
//       ''').eq('seller_id', _session!.user.id).range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

//       // Optimized: Fetch store_name for all orders in one query
//       final sellerIds = _orders.map((order) => order['seller_id']).toSet().toList();
//       if (sellerIds.isNotEmpty) {
//         final sellers = await retry(() => _spb
//             .from('sellers')
//             .select('id, store_name')
//             .inFilter('id', sellerIds));
//         for (var order in _orders) {
//           final seller = sellers.firstWhere(
//             (s) => s['id'] == order['seller_id'],
//             orElse: () => {'store_name': 'Unknown'},
//           );
//           order['sellers'] = seller;
//         }
//       } else {
//         for (var order in _orders) {
//           order['sellers'] = {'store_name': 'Unknown'};
//         }
//       }
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _detectLocation() async {
//     setState(() => _locationMessage = 'Detecting…');
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         setState(() => _locationMessage = 'Location permission denied. Enter manually.');
//         _showManualLoc = true;
//         return;
//       }
//       final position = await Geolocator.getCurrentPosition();
//       await _setSellerLocation(position.latitude, position.longitude);
//     } catch (e) {
//       setState(() => _locationMessage = 'Failed: $e');
//       _showManualLoc = true;
//     }
//   }

//   Future<void> _setSellerLocation(double lat, double lon) async {
//     try {
//       final storeName = _seller?['store_name'] ?? 'Default Store';
//       await retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': storeName,
//           }));
//       _sellerLocation = {'lat': lat, 'lon': lon};
//       context.read<AppState>().setSellerLocation(lat, lon);
//       _address = await fetchAddress(lat, lon);
//       _checkDistance();
//       setState(() => _locationMessage = 'Location updated: $_address');
//       await _load();
//     } catch (e) {
//       setState(() => _locationMessage = 'Error: $e');
//     }
//   }

//   void _checkDistance() {
//     final buyerLoc = context.read<AppState>().buyerLocation ?? _defaultLocation;
//     if (_sellerLocation == null) {
//       _locationMessage = 'Unable to calculate distance.';
//       return;
//     }
//     final d = distKm(buyerLoc, _sellerLocation!);
//     _locationMessage = d <= 40
//         ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
//         : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
//     setState(() {});
//   }

//   Future<void> _manualLocUpdate() async {
//     final lat = double.tryParse(_latC.text);
//     final lon = double.tryParse(_lonC.text);
//     if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
//       setState(() => _locationMessage = 'Invalid latitude or longitude.');
//       return;
//     }
//     await _setSellerLocation(lat, lon);
//     setState(() => _showManualLoc = false);
//     _latC.clear();
//     _lonC.clear();
//   }

//   Future<void> _deleteProduct(String productId) async {
//     if (!await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Delete Product'),
//         content: const Text('Are you sure you want to delete this product?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     )) return;

//     setState(() => _loading = true);
//     try {
//       await retry(() => _spb
//           .from('products')
//           .delete()
//           .eq('id', productId)
//           .eq('seller_id', _session!.user.id));
//       setState(() => _locationMessage = 'Product deleted successfully!');
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error deleting product: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _updateOrderStatus(int id, String status) async {
//     try {
//       const validTransitions = {
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _orders.firstWhere((o) => o['id'] == id)['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         setState(() => _locationMessage = 'Invalid status transition from $current to $status.');
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
//       setState(() => _locationMessage = 'Order #$id status updated to $status.');
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating status: $e');
//     }
//   }

//   Future<void> _updateEmiStatus(int orderId, String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('uuid', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         setState(() => _locationMessage = 'EMI approved successfully!');
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() => _locationMessage = 'EMI rejected. Buyer notified to retry payment.');
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', orderId));
//       setState(() => _emiStatusUpdates = {..._emiStatusUpdates, orderId: ''});
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating EMI status: $e');
//     }
//   }

//   Widget _storeDetails() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Store Details', style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 8),
//             Text('Store: ${_seller?['store_name'] ?? 'Unnamed Store'}'),
//             Text('Email: ${_profile?['email'] ?? 'N/A'}'),
//             Text('Name: ${_profile?['full_name'] ?? 'Not set'}'),
//             Text('Phone: ${_profile?['phone_number'] ?? 'Not set'}'),
//             Text('Location: $_address'),
//             Text(
//               _locationMessage,
//               style: TextStyle(
//                 color: _locationMessage.startsWith('Warning') ? Colors.red : Colors.green,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 ElevatedButton(
//                   onPressed: _detectLocation,
//                   child: const Text('Detect Current Location'),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: () => setState(() => _showManualLoc = true),
//                   child: const Text('Enter Manually'),
//                 ),
//               ],
//             ),
//             if (_showManualLoc) ...[
//               TextField(
//                 controller: _latC,
//                 decoration: const InputDecoration(labelText: 'Latitude (-90 to 90)'),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//               ),
//               TextField(
//                 controller: _lonC,
//                 decoration: const InputDecoration(labelText: 'Longitude (-180 to 180)'),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//               ),
//               Row(
//                 children: [
//                   TextButton(onPressed: _manualLocUpdate, child: const Text('Submit')),
//                   TextButton(
//                     onPressed: () => setState(() => _showManualLoc = false),
//                     child: const Text('Cancel'),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _productsList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('My Products', style: Theme.of(context).textTheme.titleLarge),
//             ElevatedButton(
//               onPressed: _sellerLocation == null
//                   ? null
//                   : () => context.push('/seller/add-product'),
//               child: const Text('Add Product'),
//             ),
//           ],
//         ),
//         if (_products.isEmpty) const Text('No products found.'),
//         ..._products.map((prod) => Card(
//               child: ListTile(
//                 leading: prod['images'].isNotEmpty
//                     ? Image.network(prod['images'][0], width: 50, height: 50, fit: BoxFit.cover)
//                     : const Icon(Icons.image),
//                 title: Text(prod['title'] ?? 'Unnamed Product'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Price: ₹${prod['price']?.toStringAsFixed(2) ?? '0'}'),
//                     Text('Stock: ${prod['stock'] ?? 0}'),
//                     if (prod['product_variants'].isNotEmpty)
//                       Text('Variants: ${prod['product_variants'].length}'),
//                   ],
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => _deleteProduct(prod['id'].toString()),
//                 ),
//                 onTap: () => context.push('/product/${prod['id']}'),
//               ),
//             )),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             TextButton(
//               onPressed: _prodPage == 1
//                   ? null
//                   : () async {
//                       setState(() => _prodPage--);
//                       await _load();
//                     },
//               child: const Text('Prev'),
//             ),
//             Text('Page $_prodPage'),
//             TextButton(
//               onPressed: _products.length < _perPage
//                   ? null
//                   : () async {
//                       setState(() => _prodPage++);
//                       await _load();
//                     },
//               child: const Text('Next'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _ordersList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Orders', style: Theme.of(context).textTheme.titleLarge),
//         if (_orders.isEmpty) const Text('No orders found.'),
//         ..._orders.map((order) => Card(
//               child: ListTile(
//                 title: Text('Order #${order['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Total: ₹${order['total']?.toStringAsFixed(2) ?? '0'}'),
//                     Text('Status: ${order['order_status'] ?? 'N/A'}'),
//                     if (order['order_status'] == 'Cancelled')
//                       Text('Reason: ${order['cancellation_reason'] ?? 'N/A'}'),
//                     if (order['order_items'].isNotEmpty)
//                       Text('Item: ${order['order_items'][0]['products']['title'] ?? 'Unnamed'}'),
//                     if (order['emi_applications'] != null)
//                       Text('Buyer: ${order['emi_applications']['full_name'] ?? 'Unknown'}'),
//                     Text('Store: ${order['sellers']['store_name'] ?? 'Unknown'}'),
//                     if (order['estimated_delivery'] != null)
//                       Text('Est. Delivery: ${order['estimated_delivery'].substring(0, 16)}'),
//                   ],
//                 ),
//                 trailing: order['emi_applications'] != null &&
//                         order['emi_applications']['status'] == 'pending'
//                     ? DropdownButton<String>(
//                         value: _emiStatusUpdates[order['id']] ??
//                             order['emi_applications']['status'],
//                         items: ['pending', 'approved', 'rejected']
//                             .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                             .toList(),
//                         onChanged: (v) =>
//                             _updateEmiStatus(order['id'], order['emi_applications']['uuid'], v!),
//                       )
//                     : (order['order_status'] != 'Cancelled' && order['order_status'] != 'Delivered'
//                         ? IconButton(
//                             icon: const Icon(Icons.edit),
//                             onPressed: () async {
//                               final next = await showDialog<String>(
//                                 context: context,
//                                 builder: (_) => StatefulBuilder(
//                                   builder: (_, setD) {
//                                     String? sel = order['order_status'];
//                                     return AlertDialog(
//                                       title: const Text('Update Status'),
//                                       content: DropdownButton<String>(
//                                         value: sel,
//                                         isExpanded: true,
//                                         items: [
//                                           'Order Placed',
//                                           'Shipped',
//                                           'Out for Delivery',
//                                           'Delivered',
//                                           'Cancelled'
//                                         ]
//                                             .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                             .toList(),
//                                         onChanged: (v) => setD(() => sel = v),
//                                       ),
//                                       actions: [
//                                         TextButton(
//                                           onPressed: () => Navigator.pop(context),
//                                           child: const Text('Cancel'),
//                                         ),
//                                         TextButton(
//                                           onPressed: () => Navigator.pop(context, sel),
//                                           child: const Text('Save'),
//                                         ),
//                                       ],
//                                     );
//                                   },
//                                 ),
//                               );
//                               if (next != null && next != order['order_status']) {
//                                 _updateOrderStatus(order['id'], next);
//                               }
//                             },
//                           )
//                         : null),
//                 onTap: () => context.push('/order-details/${order['id']}'),
//               ),
//             )),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             TextButton(
//               onPressed: _orderPage == 1
//                   ? null
//                   : () async {
//                       setState(() => _orderPage--);
//                       await _load();
//                     },
//               child: const Text('Prev'),
//             ),
//             Text('Page $_orderPage'),
//             TextButton(
//               onPressed: _orders.length < _perPage
//                   ? null
//                   : () async {
//                       setState(() => _orderPage++);
//                       await _load();
//                     },
//               child: const Text('Next'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_error != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text('Error: $_error'),
//               ElevatedButton(onPressed: _load, child: const Text('Retry')),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text('Seller Dashboard - ${_seller?['store_name'] ?? 'Unnamed Store'}')),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _storeDetails(),
//               const SizedBox(height: 16),
//               _productsList(),
//               const SizedBox(height: 16),
//               _ordersList(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart'; // For timestamp formatting
import 'package:share_plus/share_plus.dart';

import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

const _defaultLocation = {'lat': 12.9753, 'lon': 77.591};

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final _spb = Supabase.instance.client;

  // Core models
  Session? _session;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _seller;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _nonEmiOrders = [];
  List<Map<String, dynamic>> _emiOrders = [];

  // UI helpers
  bool _loading = true;
  String? _error;
  String _locationMessage = '';
  String _address = 'Not set';
  Map<String, double>? _sellerLocation;
  bool _showManualLoc = false;
  final _latC = TextEditingController();
  final _lonC = TextEditingController();

  // Pagination
  int _prodPage = 1;
  int _orderPage = 1;
  final int _perPage = 5;

  // Sorting
  String _sortOption = 'default';

  // EMI status updates
  Map<int, String> _emiStatusUpdates = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _latC.dispose();
    _lonC.dispose();
    super.dispose();
  }

  // ─── Helper Methods ───────────────────────────────────────────────────────
  double distKm(Map<String, double> a, Map<String, double> b) {
    const R = 6371.0;
    final dLat = (b['lat']! - a['lat']!) * math.pi / 180;
    final dLon = (b['lon']! - a['lon']!) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a['lat']! * math.pi / 180) *
            math.cos(b['lat']! * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  Future<String> fetchAddress(double? lat, double? lon) async {
    if (lat == null || lon == null) return 'Coordinates unavailable';
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
        options: Options(headers: {'User-Agent': 'Markeet/1.0'}),
      );
      if (response.statusCode == 200 && response.data['display_name'] != null) {
        return response.data['display_name'];
      }
      return 'Address not found';
    } catch (e) {
      debugPrint('Error fetching address: $e'); // Improved logging
      return 'Error fetching address: $e';
    }
  }

  String formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toUtc();
      final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30)); // Convert to IST
      return DateFormat('yyyy-MM-dd HH:mm').format(istDateTime);
    } catch (e) {
      debugPrint('Error formatting timestamp: $e');
      return timestamp;
    }
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _session = context.read<AppState>().session;
      if (_session == null) {
        context.go('/auth');
        return;
      }

      // Profile
      _profile = await retry(() => _spb
          .from('profiles')
          .select('is_seller, email, full_name, phone_number')
          .eq('id', _session!.user.id)
          .single());
      if (_profile?['is_seller'] != true) {
        _error = 'You do not have permission to access seller functions.';
        context.go('/account');
        return;
      }

      // Seller
      _seller = await retry(() => _spb
          .from('sellers')
          .select('*')
          .eq('id', _session!.user.id)
          .single());
      if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
        _sellerLocation = {
          'lat': _seller!['latitude'],
          'lon': _seller!['longitude']
        };
        _address = await fetchAddress(_seller!['latitude'], _seller!['longitude']);
        _checkDistance();
      }

      // Products
      _products = await retry(() => _spb
          .from('products')
          .select('id, title, price, images, stock, product_variants(id, attributes, price, stock, images)')
          .eq('seller_id', _session!.user.id)
          .eq('is_approved', true)
          .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));

      // Apply sorting
      if (_sortOption == 'price_low') {
        _products.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
      } else if (_sortOption == 'price_high') {
        _products.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      }

      // Non-EMI Orders
      _nonEmiOrders = await retry(() => _spb.from('orders').select('''
        id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
        order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
        profiles!orders_user_id_fkey(email)
      ''').eq('seller_id', _session!.user.id).neq('payment_method', 'emi').range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

      // EMI Orders
      _emiOrders = await retry(() => _spb.from('orders').select('''
        id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
        order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
        emi_applications(status, product_name, product_price, full_name, mobile_number, id),
        profiles!orders_user_id_fkey(email)
      ''').eq('seller_id', _session!.user.id).eq('payment_method', 'emi').range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

      // Fetch store_name for all orders in one query
      final allOrders = [..._nonEmiOrders, ..._emiOrders];
      final sellerIds = allOrders.map((order) => order['seller_id']).toSet().toList();
      if (sellerIds.isNotEmpty) {
        final sellers = await retry(() => _spb
            .from('sellers')
            .select('id, store_name')
            .inFilter('id', sellerIds));
        for (var order in allOrders) {
          final seller = sellers.firstWhere(
            (s) => s['id'] == order['seller_id'],
            orElse: () => {'store_name': 'Unknown'},
          );
          order['sellers'] = seller;
        }
      } else {
        for (var order in allOrders) {
          order['sellers'] = {'store_name': 'Unknown'};
        }
      }
    } catch (e) {
      _error = 'Failed to load data: $e';
      debugPrint(_error); // Improved logging
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Location Handling ────────────────────────────────────────────────────
  Future<void> _detectLocation() async {
    setState(() => _locationMessage = 'Detecting…');
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locationMessage = 'Location permission denied. Enter manually.');
        _showManualLoc = true;
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      await _setSellerLocation(position.latitude, position.longitude);
    } catch (e) {
      setState(() => _locationMessage = 'Failed to detect location: $e');
      _showManualLoc = true;
    }
  }

  Future<void> _setSellerLocation(double lat, double lon) async {
    try {
      final storeName = _seller?['store_name'] ?? 'Default Store';
      await retry(() => _spb.rpc('set_seller_location', params: {
            'seller_uuid': _session!.user.id,
            'user_lat': lat,
            'user_lon': lon,
            'store_name_input': storeName,
          }));
      _sellerLocation = {'lat': lat, 'lon': lon};
      context.read<AppState>().setSellerLocation(lat, lon);
      _address = await fetchAddress(lat, lon);
      _checkDistance();
      setState(() => _locationMessage = 'Location updated: $_address');
      await _load();
    } catch (e) {
      setState(() => _locationMessage = 'Error updating location: $e');
    }
  }

  void _checkDistance() {
    final buyerLoc = context.read<AppState>().buyerLocation ?? _defaultLocation;
    if (_sellerLocation == null) {
      _locationMessage = 'Unable to calculate distance.';
      return;
    }
    final d = distKm(buyerLoc, _sellerLocation!);
    _locationMessage = d <= 40
        ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
        : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
    setState(() {});
  }

  Future<void> _manualLocUpdate() async {
    final lat = double.tryParse(_latC.text);
    final lon = double.tryParse(_lonC.text);
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      setState(() => _locationMessage = 'Invalid latitude or longitude.');
      return;
    }
    await _setSellerLocation(lat, lon);
    setState(() => _showManualLoc = false);
    _latC.clear();
    _lonC.clear();
  }

  // ─── Product and Order Operations ─────────────────────────────────────────
  Future<void> _deleteProduct(String productId) async {
    if (!await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    )) return;

    setState(() => _loading = true);
    try {
      await retry(() => _spb
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('seller_id', _session!.user.id));
      setState(() => _locationMessage = 'Product deleted successfully!');
      await _load();
    } catch (e) {
      setState(() => _error = 'Error deleting product: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateOrderStatus(int id, String status) async {
    try {
      const validTransitions = {
        'Order Placed': ['Shipped', 'Cancelled'],
        'Shipped': ['Out for Delivery', 'Cancelled'],
        'Out for Delivery': ['Delivered', 'Cancelled'],
        'Delivered': [],
        'Cancelled': [],
      };
      final currentOrder = [..._nonEmiOrders, ..._emiOrders].firstWhere((o) => o['id'] == id);
      final currentStatus = currentOrder['order_status'];
      if (!validTransitions[currentStatus]!.contains(status)) {
        setState(() => _locationMessage = 'Invalid status transition from $currentStatus to $status.');
        return;
      }
      await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
      setState(() => _locationMessage = 'Order #$id status updated to $status.');
      await _load();
    } catch (e) {
      setState(() => _error = 'Error updating status: $e');
    }
  }

  Future<void> _updateEmiStatus(int orderId, String emiAppId, String newStatus) async {
    try {
      await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
      String orderStatus = 'pending';
      if (newStatus == 'approved') {
        orderStatus = 'Order Placed';
        setState(() => _locationMessage = 'EMI approved successfully!');
      } else if (newStatus == 'rejected') {
        orderStatus = 'Cancelled';
        setState(() => _locationMessage = 'EMI rejected. Buyer notified to retry payment.');
      }
      await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', orderId));
      setState(() => _emiStatusUpdates = {..._emiStatusUpdates, orderId: ''});
      await _load();
    } catch (e) {
      setState(() => _error = 'Error updating EMI status: $e');
    }
  }

  // ─── UI Components ────────────────────────────────────────────────────────
  Widget _buildShimmer({required double height, required double width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _storeDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text('Store Details', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Store', _seller?['store_name'] ?? 'Unnamed Store'),
            _buildDetailRow('Email', _profile?['email'] ?? 'N/A'),
            _buildDetailRow('Name', _profile?['full_name'] ?? 'Not set'),
            _buildDetailRow('Phone', _profile?['phone_number'] ?? 'Not set'),
            _buildDetailRow('Location', _address),
            Text(
              _locationMessage,
              style: TextStyle(
                color: _locationMessage.startsWith('Warning') || _locationMessage.startsWith('Error')
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            // Map Integration with flutter_map
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_sellerLocation?['lat'] ?? 12.9753, _sellerLocation?['lon'] ?? 77.591),
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) async {
                    await _setSellerLocation(point.latitude, point.longitude);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  if (_sellerLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_sellerLocation!['lat']!, _sellerLocation!['lon']!),
                          child: const Icon(Icons.location_pin, color: Colors.red),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Detect Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _showManualLoc = true),
                  child: const Text('Enter Manually'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            if (_showManualLoc) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _latC,
                decoration: const InputDecoration(
                  labelText: 'Latitude (-90 to 90)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lonC,
                decoration: const InputDecoration(
                  labelText: 'Longitude (-180 to 180)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(onPressed: _manualLocUpdate, child: const Text('Submit')),
                  TextButton(
                    onPressed: () => setState(() => _showManualLoc = false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: color != null ? TextStyle(color: color) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: _sortOption,
      items: [
        const DropdownMenuItem(value: 'default', child: Text('Sort by: Default')),
        const DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
        const DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
      ],
      onChanged: (value) {
        setState(() {
          _sortOption = value!;
          _load(); // Reload to apply sorting
        });
      },
    );
  }

  Widget _productsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text('My Products', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            Row(
              children: [
                _buildSortDropdown(),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _sellerLocation == null
                      ? null
                      : () => context.push('/seller/add-product'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmer(height: 80, width: double.infinity),
              ),
            ),
          )
        else if (_products.isEmpty)
          const Text('No products found.')
        else
          ..._products.map((prod) => Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          prod['images'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: prod['images'][0],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => _buildShimmer(height: 60, width: 60),
                                    errorWidget: (context, url, error) => const Icon(Icons.image),
                                  ),
                                )
                              : const Icon(Icons.image, size: 60),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod['title'] ?? 'Unnamed Product',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text('Price: ₹${prod['price']?.toStringAsFixed(2) ?? '0'}'),
                                Text('Stock: ${prod['stock'] ?? 0}'),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(prod['id'].toString()),
                          ),
                        ],
                      ),
                      if (prod['product_variants'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Variants:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...prod['product_variants'].map<Widget>((variant) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (variant['attributes'] as Map<String, dynamic>)
                                        .entries
                                        .where((entry) => entry.value != null)
                                        .map((entry) => '${entry.key}: ${entry.value}')
                                        .join(', '),
                                  ),
                                  Text('Price: ₹${variant['price']?.toStringAsFixed(2) ?? '0'}'),
                                  Text('Stock: ${variant['stock'] ?? 0}'),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/product/${prod['id']}'),
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _prodPage == 1
                  ? null
                  : () async {
                      setState(() => _prodPage--);
                      await _load();
                    },
              child: const Text('Prev'),
            ),
            Text('Page $_prodPage'),
            TextButton(
              onPressed: _products.length < _perPage
                  ? null
                  : () async {
                      setState(() => _prodPage++);
                      await _load();
                    },
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ordersList(String title, List<Map<String, dynamic>> orders, {bool isEmi = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmer(height: 80, width: double.infinity),
              ),
            ),
          )
        else if (orders.isEmpty)
          Text('No ${title.toLowerCase()} found.')
        else
          ...orders.map((order) => Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (isEmi && order['emi_applications'] != null && order['emi_applications']['status'] == 'pending')
                            DropdownButton<String>(
                              value: _emiStatusUpdates[order['id']] ?? order['emi_applications']['status'],
                              items: ['pending', 'approved', 'rejected']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) =>
                                  _updateEmiStatus(order['id'], order['emi_applications']['id'], v!),
                            )
                          else if (!isEmi && order['order_status'] != 'Cancelled' && order['order_status'] != 'Delivered')
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final next = await showDialog<String>(
                                  context: context,
                                  builder: (_) => StatefulBuilder(
                                    builder: (_, setD) {
                                      String? sel = order['order_status'];
                                      return AlertDialog(
                                        title: const Text('Update Status'),
                                        content: DropdownButton<String>(
                                          value: sel,
                                          isExpanded: true,
                                          items: [
                                            'Order Placed',
                                            'Shipped',
                                            'Out for Delivery',
                                            'Delivered',
                                            'Cancelled'
                                          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                          onChanged: (v) => setD(() => sel = v),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, sel),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                                if (next != null && next != order['order_status']) {
                                  _updateOrderStatus(order['id'], next);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Total', '₹${order['total']?.toStringAsFixed(2) ?? '0'}'),
                      _buildDetailRow('Status', order['order_status'] ?? 'N/A'),
                      if (order['order_status'] == 'Cancelled')
                        _buildDetailRow('Reason', order['cancellation_reason'] ?? 'N/A', color: Colors.red),
                      if (order['order_items'].isNotEmpty)
                        _buildDetailRow('Item', order['order_items'][0]['products']['title'] ?? 'Unnamed'),
                      if (isEmi && order['emi_applications'] != null) ...[
                        _buildDetailRow('Buyer', '${order['emi_applications']['full_name'] ?? 'Unknown'} (${order['profiles']['email'] ?? 'N/A'})'),
                        _buildDetailRow('EMI Status', order['emi_applications']['status'] ?? 'N/A'),
                        _buildDetailRow('Product', order['emi_applications']['product_name'] ?? 'N/A'),
                        _buildDetailRow('Price', '₹${order['emi_applications']['product_price']?.toStringAsFixed(2) ?? '0'}'),
                        _buildDetailRow('Buyer Contact', order['emi_applications']['mobile_number'] ?? 'N/A'),
                      ],
                      _buildDetailRow('Store', order['sellers']['store_name'] ?? 'Unknown'),
                      if (order['estimated_delivery'] != null)
                        _buildDetailRow('Est. Delivery', formatTimestamp(order['estimated_delivery'])),
                      if (order['shipping_address'] != null)
                        _buildDetailRow('Shipping Address', order['shipping_address']),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/order-details/${order['id']}'),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _orderPage == 1
                  ? null
                  : () async {
                      setState(() => _orderPage--);
                      await _load();
                    },
              child: const Text('Prev'),
            ),
            Text('Page $_orderPage'),
            TextButton(
              onPressed: orders.length < _perPage
                  ? null
                  : () async {
                      setState(() => _orderPage++);
                      await _load();
                    },
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Dashboard - ${_seller?['store_name'] ?? 'Unnamed Store'}'),
        actions: [
          IconButton(
            onPressed: () {
              Share.share('Check out my store on Markeet: https://www.markeet.com/seller/${_session?.user.id}');
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _storeDetails(),
              const SizedBox(height: 16),
              _productsList(),
              const SizedBox(height: 16),
              _ordersList('Buyer Orders', _nonEmiOrders),
              const SizedBox(height: 16),
              _ordersList('Pending EMI Orders', _emiOrders, isEmi: true),
            ],
          ),
        ),
      ),
    );
  }
}