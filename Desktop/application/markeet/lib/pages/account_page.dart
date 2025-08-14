// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// import '../state/app_state.dart';

// const _blr = {'lat': 12.9753, 'lon': 77.591};

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _spb = Supabase.instance.client;

//   /* ─── core models ─────────────────────────────────────────────── */
//   Session? _session;
//   Map<String, dynamic>? _profile; // row in profiles
//   Map<String, dynamic>? _seller; // row in sellers
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];

//   /* ─── ui helpers ──────────────────────────────────────────────── */
//   bool _loading = true;
//   String? _err;

//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // profile edit
//   bool _edit = false;
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController();

//   // geo
//   Map<String, double>? _sellerLoc;
//   Map<String, double>? _buyerLoc;
//   String _locMsg = '';

//   // cancellation
//   int? _cancelId;
//   String _cancelReason = '';
//   final _buyerReasons = [
//     'Changed my mind',
//     'Found better price',
//     'Item no longer needed',
//     'Other'
//   ];
//   final _sellerReasons = [
//     'Out of stock',
//     'Unable to ship',
//     'Buyer request',
//     'Other'
//   ];

//   /* ─── math helpers ────────────────────────────────────────────── */
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

//   /* ─── data load ──────────────────────────────────────────────── */
//   Future<void> _load() async {
//     setState(() => _loading = true);

//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       /* profile */
//       _profile = await _spb
//           .from('profiles')
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single() as Map<String, dynamic>;
//       _nameC.text = _profile?['full_name'] ?? '';
//       _phoneC.text = _profile?['phone_number'] ?? '';

//       /* products & seller info (if seller) */
//       if (_profile?['is_seller'] == true) {
//         _seller = await _spb
//             .from('sellers')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single() as Map<String, dynamic>;

//         if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//           _sellerLoc = {'lat': _seller!['latitude'], 'lon': _seller!['longitude']};
//         }

//         _products = await _spb
//             .from('products')
//             .select('id,title,price,images')
//             .eq('seller_id', _session!.user.id)
//             .eq('is_approved', true)
//             .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1) as List<Map<String, dynamic>>;
//       }

//       /* orders (buyer or seller) */
//       final field = _profile?['is_seller'] == true ? 'seller_id' : 'user_id';
//       final base = _spb
//           .from('orders')
//           .select('''
//             id,total,order_status,cancellation_reason,payment_method,created_at,
//             order_items(quantity,price,products(id,title,images)),
//             emi_applications(status,product_name,product_price),
//             profiles!orders_user_id_fkey(email)
//           ''')
//           .eq(field, _session!.user.id)
//           .order('created_at', ascending: false);

//       _orders = await base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1) as List<Map<String, dynamic>>;
//     } catch (e) {
//       _err = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /* ─── seller-location helpers ────────────────────────────────── */
//   Future<void> _detectLocation() async {
//     setState(() => _locMsg = 'Detecting…');
//     try {
//       await Geolocator.requestPermission();
//       final p = await Geolocator.getCurrentPosition();
//       await _setSellerLoc(p.latitude, p.longitude);
//     } catch (e) {
//       setState(() => _locMsg = 'Failed: $e');
//     }
//   }

//   Future<void> _setSellerLoc(double lat, double lon) async {
//     await _retry(() => _spb.rpc('set_seller_location', params: {
//           'seller_uuid': _session!.user.id,
//           'user_lat': lat,
//           'user_lon': lon,
//           'store_name_input': _seller?['store_name'] ?? 'Store'
//         }));
//     _sellerLoc = {'lat': lat, 'lon': lon};
//     _checkDistance();
//     setState(() => _locMsg = 'Location updated');
//   }

//   void _checkDistance() {
//     if (_sellerLoc == null || _buyerLoc == null) return;
//     final d = _distKm(_buyerLoc!, _sellerLoc!);
//     _locMsg = d <= 40
//         ? 'Store is ${d.toStringAsFixed(1)} km away ✅'
//         : 'Warning: store ${d.toStringAsFixed(1)} km away (>40 km)';
//     setState(() => {});
//   }

//   /* ─── order ops ──────────────────────────────────────────────── */
//   Future<void> _cancel(int id) async {
//     if (_cancelReason.isEmpty) return;
//     await _spb
//         .from('orders')
//         .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//         .eq('id', id);
//     _cancelId = null;
//     _cancelReason = '';
//     await _load();
//   }

//   /* ─── lifecycle ──────────────────────────────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _buyerLoc = context.read<AppState>().buyerLocation ?? _blr;
//     _load();
//   }

//   /* ─── UI helpers ─────────────────────────────────────────────── */

//   Widget _profileCard() {
//     if (_profile == null) return const SizedBox();
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(_session!.user.email ?? 'No email', style: Theme.of(context).textTheme.titleMedium),
//           if (!_edit) ...[
//             Text('Name: ${_profile!['full_name'] ?? '-'}'),
//             Text('Phone: ${_profile!['phone_number'] ?? '-'}'),
//             Row(children: [
//               TextButton(onPressed: () => setState(() => _edit = true), child: const Text('Edit')),
//               TextButton(
//                   onPressed: () async {
//                     await _spb.auth.signOut();
//                     context.read<AppState>().signOut();
//                   },
//                   child: const Text('Logout')),
//             ])
//           ] else ...[
//             TextField(
//                 controller: _nameC, decoration: const InputDecoration(labelText: 'Full name')),
//             TextField(
//                 controller: _phoneC, decoration: const InputDecoration(labelText: 'Phone')),
//             Row(children: [
//               TextButton(
//                   onPressed: () async {
//                     await _spb.from('profiles').update({
//                       'full_name': _nameC.text.trim(),
//                       'phone_number': _phoneC.text.trim(),
//                     }).eq('id', _session!.user.id);
//                     setState(() => _edit = false);
//                     await _load();
//                   },
//                   child: const Text('Save')),
//               TextButton(
//                   onPressed: () => setState(() => _edit = false), child: const Text('Cancel')),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   Widget _sellerPanel() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text('Store location', style: Theme.of(context).textTheme.titleMedium),
//           Text(_sellerLoc == null
//               ? 'Not set'
//               : 'Lat ${_sellerLoc!['lat']!.toStringAsFixed(4)}, Lon ${_sellerLoc!['lon']!.toStringAsFixed(4)}'),
//           Text(_locMsg,
//               style: TextStyle(color: _locMsg.startsWith('Warning') ? Colors.red : null)),
//           const SizedBox(height: 8),
//           Row(children: [
//             ElevatedButton(onPressed: _detectLocation, child: const Text('Detect')),
//             const SizedBox(width: 12),
//             ElevatedButton(
//                 onPressed: () async {
//                   final lat = await _showInput('Latitude');
//                   final lon = await _showInput('Longitude');
//                   if (lat != null && lon != null) await _setSellerLoc(lat, lon);
//                 },
//                 child: const Text('Enter manually')),
//           ])
//         ]),
//       ),
//     );
//   }

//   Future<double?> _showInput(String label) async {
//     final c = TextEditingController();
//     final res = await showDialog<double>(
//         context: context,
//         builder: (_) => AlertDialog(
//               title: Text(label),
//               content: TextField(
//                   controller: c,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true)),
//               actions: [
//                 TextButton(
//                     onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                 TextButton(
//                     onPressed: () => Navigator.pop(context, double.tryParse(c.text)),
//                     child: const Text('OK')),
//               ],
//             ));
//     return res;
//   }

//   Widget _productsGrid() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text('My products', style: Theme.of(context).textTheme.titleMedium),
//       const SizedBox(height: 8),
//       if (_products.isEmpty) const Text('No products'),
//       if (_products.isNotEmpty)
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: .72,
//           children: _products.map((p) => Card(
//                 child: Column(children: [
//                   Expanded(
//                       child: Image.network(
//                           (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://dummyimage.com/150',
//                           fit: BoxFit.cover,
//                           width: double.infinity)),
//                   Padding(
//                       padding: const EdgeInsets.all(6),
//                       child: Text(p['title'], maxLines: 2, overflow: TextOverflow.ellipsis)),
//                   Text('₹${p['price']}'),
//                 ]),
//               )).toList(),
//         ),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//             onPressed: _prodPage == 1
//                 ? null
//                 : () async {
//                     _prodPage--;
//                     await _load();
//                   },
//             child: const Text('Prev')),
//         Text('Page $_prodPage'),
//         TextButton(
//             onPressed: _products.length < _perPage
//                 ? null
//                 : () async {
//                     _prodPage++;
//                     await _load();
//                   },
//             child: const Text('Next')),
//       ])
//     ]);
//   }

//   Widget _ordersList() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(_profile?['is_seller'] == true ? 'Orders received' : 'My orders',
//           style: Theme.of(context).textTheme.titleMedium),
//       const SizedBox(height: 8),
//       if (_orders.isEmpty) const Text('No orders'),
//       ..._orders.map((o) => Card(
//             margin: const EdgeInsets.only(bottom: 12),
//             child: ListTile(
//               title: Text('Order #${o['id']}'),
//               subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('Total ₹${o['total']} • ${o['order_status']}'),
//                 if (o['order_items'] != null && (o['order_items'] as List).isNotEmpty)
//                   Text(o['order_items'][0]['products']['title'] ?? '')
//               ]),
//               trailing: _profile?['is_seller'] == true
//                   ? IconButton(
//                       icon: const Icon(Icons.edit),
//                       onPressed: () async {
//                         final next = await _showStatus(o['order_status']);
//                         if (next != null) {
//                           await _spb
//                               .from('orders')
//                               .update({'order_status': next}).eq('id', o['id']);
//                           await _load();
//                         }
//                       })
//                   : (_cancelId == o['id']
//                       ? null
//                       : IconButton(
//                           icon: const Icon(Icons.cancel_outlined),
//                           onPressed: () => setState(() => _cancelId = o['id']),
//                         )),
//             ),
//           )),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//             onPressed: _orderPage == 1
//                 ? null
//                 : () async {
//                     _orderPage--;
//                     await _load();
//                   },
//             child: const Text('Prev')),
//         Text('Page $_orderPage'),
//         TextButton(
//             onPressed: _orders.length < _perPage
//                 ? null
//                 : () async {
//                     _orderPage++;
//                     await _load();
//                   },
//             child: const Text('Next')),
//       ])
//     ]);
//   }

//   Future<String?> _showStatus(String current) async {
//     const statuses = [
//       'Order Placed',
//       'Shipped',
//       'Out for Delivery',
//       'Delivered',
//       'Cancelled'
//     ];
//     String? sel = current;
//     final res = await showDialog<String>(
//         context: context,
//         builder: (_) => StatefulBuilder(
//               builder: (_, setD) => AlertDialog(
//                 title: const Text('Update status'),
//                 content: DropdownButton<String>(
//                   value: sel,
//                   isExpanded: true,
//                   items: statuses
//                       .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                       .toList(),
//                   onChanged: (v) => setD(() => sel = v),
//                 ),
//                 actions: [
//                   TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel')),
//                   TextButton(
//                       onPressed: () => Navigator.pop(context, sel),
//                       child: const Text('Save')),
//                 ],
//               ),
//             ));
//     return res == current ? null : res;
//   }

//   Widget _cancelDialog() {
//     final reasons = _profile?['is_seller'] == true ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel order #$_cancelId'),
//       content: DropdownButton<String>(
//         value: _cancelReason.isEmpty ? null : _cancelReason,
//         isExpanded: true,
//         items: reasons
//             .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//             .toList(),
//         onChanged: (v) => setState(() => _cancelReason = v ?? ''),
//       ),
//       actions: [
//         TextButton(
//             onPressed: () => setState(() => _cancelId = null), child: const Text('Back')),
//         TextButton(
//             onPressed: () async => await _cancel(_cancelId!), child: const Text('Confirm')),
//       ],
//     );
//   }

//   /* ─── build ──────────────────────────────────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_err != null) {
//       return Scaffold(body: Center(child: Text('Error:\n$_err')));
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Account')),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _profileCard(),
//               const SizedBox(height: 12),
//               _sellerPanel(),
//               const SizedBox(height: 12),
//               _productsGrid(),
//               const SizedBox(height: 12),
//               _ordersList(),
//               if (_cancelId != null) _cancelDialog(),
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

// const _blr = {'lat': 12.9753, 'lon': 77.591};

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _spb = Supabase.instance.client;

//   /* ─── core models ─────────────────────────────────────────────── */
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];

//   /* ─── ui helpers ──────────────────────────────────────────────── */
//   bool _loading = true;
//   String? _err;
//   String _locMsg = '';
//   String _address = 'Not set';
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // profile edit
//   bool _edit = false;
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController();

//   // geo
//   Map<String, double>? _sellerLoc;
//   Map<String, double>? _buyerLoc;
//   bool _showManualLoc = false;
//   final _latC = TextEditingController();
//   final _lonC = TextEditingController();

//   // cancellation
//   int? _cancelId;
//   String _cancelReason = '';
//   bool _isCustomReason = false;
//   final _buyerReasons = [
//     'Changed my mind',
//     'Found a better price elsewhere',
//     'Item no longer needed',
//     'Other (please specify)'
//   ];
//   final _sellerReasons = [
//     'Out of stock',
//     'Unable to ship',
//     'Buyer request',
//     'Other (please specify)'
//   ];

//   // emi & retry payment
//   Map<int, String> _emiStatusUpdates = {};
//   bool _showRetryPayment = false;
//   int? _retryOrderId;
//   String _newPaymentMethod = 'credit_card';
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   // support
//   String _supportMsg = '';
//   final _supportC = TextEditingController();

//   /* ─── math & network helpers ──────────────────────────────────── */
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

//   Future<String> _fetchAddress(double? lat, double? lon) async {
//     if (lat == null || lon == null) return 'Coordinates unavailable';
//     try {
//       final dio = Dio();
//       final response = await dio.get(
//         'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
//         options: Options(headers: {'User-Agent': 'Markeet/1.0'}),
//       );
//       if (response.statusCode == 200 && response.data['display_name'] != null) {
//         return response.data['display_name'];
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Error fetching address: $e';
//     }
//   }

//   /* ─── data load ──────────────────────────────────────────────── */
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
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single();
//       _nameC.text = _profile?['full_name'] ?? '';
//       _phoneC.text = _profile?['phone_number'] ?? '';

//       // Seller & Products
//       if (_profile?['is_seller'] == true) {
//         _seller = await _spb
//             .from('sellers')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single();
//         if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//           _sellerLoc = {'lat': _seller!['latitude'], 'lon': _seller!['longitude']};
//           _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
//           _checkDistance();
//         }

//         _products = await _spb
//             .from('products')
//             .select('id, title, price, images')
//             .eq('seller_id', _session!.user.id)
//             .eq('is_approved', true)
//             .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1);
//       }

//       // Orders
//       final field = _profile?['is_seller'] == true ? 'seller_id' : 'user_id';
//       final base = _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(status, product_name, product_price, full_name, mobile_number),
//         profiles!orders_user_id_fkey(email),
//         sellers!orders_seller_id_fkey(store_name)
//       ''').eq(field, _session!.user.id).order('created_at', ascending: false);

//       _orders = await base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1);
//     } catch (e) {
//       _err = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /* ─── seller-location helpers ────────────────────────────────── */
//   Future<void> _detectLocation() async {
//     setState(() => _locMsg = 'Detecting…');
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         setState(() => _locMsg = 'Location permission denied. Enter manually.');
//         _showManualLoc = true;
//         return;
//       }
//       final p = await Geolocator.getCurrentPosition();
//       await _setSellerLoc(p.latitude, p.longitude);
//     } catch (e) {
//       setState(() => _locMsg = 'Failed: $e');
//       _showManualLoc = true;
//     }
//   }

//   Future<void> _setSellerLoc(double lat, double lon) async {
//     try {
//       await _retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': _seller?['store_name'] ?? 'Store'
//           }));
//       _sellerLoc = {'lat': lat, 'lon': lon};
//       _address = await _fetchAddress(lat, lon);
//       _checkDistance();
//       setState(() => _locMsg = 'Location updated: $_address');
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating location: $e');
//     }
//   }

//   void _checkDistance() {
//     if (_sellerLoc == null || _buyerLoc == null) {
//       _locMsg = 'Unable to calculate distance.';
//       return;
//     }
//     final d = _distKm(_buyerLoc!, _sellerLoc!);
//     _locMsg = d <= 40
//         ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
//         : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
//     setState(() => {});
//   }

//   Future<void> _manualLocUpdate() async {
//     final lat = double.tryParse(_latC.text);
//     final lon = double.tryParse(_lonC.text);
//     if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
//       setState(() => _locMsg = 'Invalid latitude or longitude.');
//       return;
//     }
//     await _setSellerLoc(lat, lon);
//     setState(() => _showManualLoc = false);
//     _latC.clear();
//     _lonC.clear();
//   }

//   /* ─── order ops ──────────────────────────────────────────────── */
//   Future<void> _cancel(int id) async {
//     if (_cancelReason.isEmpty) {
//       setState(() => _locMsg = 'Please select a cancellation reason.');
//       return;
//     }
//     try {
//       await _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', id);
//       setState(() {
//         _cancelId = null;
//         _cancelReason = '';
//         _isCustomReason = false;
//         _locMsg = 'Order cancelled successfully.';
//       });
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error cancelling order: $e');
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
//         setState(() => _locMsg = 'Invalid status transition from $current to $status.');
//         return;
//       }
//       await _spb.from('orders').update({'order_status': status}).eq('id', id);
//       setState(() => _locMsg = 'Order #$id status updated to $status.');
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating status: $e');
//     }
//   }

//   Future<void> _updateEmiStatus(int orderId, String emiAppId, String newStatus) async {
//     try {
//       await _spb.from('emi_applications').update({'status': newStatus}).eq('uuid', emiAppId);
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         setState(() => _locMsg = 'EMI approved successfully!');
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() {
//           _locMsg = 'EMI rejected. Prompting buyer to retry payment.';
//           _retryOrderId = orderId;
//           _showRetryPayment = true;
//         });
//       }
//       await _spb.from('orders').update({'order_status': orderStatus}).eq('id', orderId);
//       setState(() => _emiStatusUpdates = {..._emiStatusUpdates, orderId: ''});
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating EMI status: $e');
//     }
//   }

// Future<void> _retryPayment() async {
//   if (_retryOrderId == null) {
//     setState(() => _locMsg = 'Error: No order selected for retry.');
//     return;
//   }
//   try {
//     await _spb.from('orders').update({
//       'payment_method': _newPaymentMethod,
//       'order_status': 'Order Placed',
//     }).eq('id', _retryOrderId!); // Use non-null assertion since we checked above
//     setState(() {
//       _showRetryPayment = false;
//       _retryOrderId = null;
//       _newPaymentMethod = 'credit_card';
//       _locMsg = 'Payment method updated successfully.';
//     });
//     await _load();
//   } catch (e) {
//     setState(() => _locMsg = 'Error updating payment: $e');
//   }
// }

//   Future<void> _submitSupport() async {
//     if (_supportMsg.trim().isEmpty) {
//       setState(() => _locMsg = 'Please enter a support message.');
//       return;
//     }
//     try {
//       await _spb.from('support_requests').insert({
//         'user_id': _session!.user.id,
//         'message': _supportMsg,
//         'created_at': DateTime.now().toIso8601String(),
//       });
//       setState(() {
//         _supportMsg = '';
//         _supportC.clear();
//         _locMsg = 'Support request submitted successfully.';
//       });
//     } catch (e) {
//       setState(() => _locMsg = 'Error submitting support request: $e');
//     }
//   }

//   /* ─── lifecycle ──────────────────────────────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _buyerLoc = context.read<AppState>().buyerLocation ?? _blr;
//     _load();
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _phoneC.dispose();
//     _latC.dispose();
//     _lonC.dispose();
//     _supportC.dispose();
//     super.dispose();
//   }

//   /* ─── UI helpers ─────────────────────────────────────────────── */
//   Widget _profileCard() {
//     if (_profile == null) return const SizedBox();
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(_session!.user.email ?? 'No email', style: Theme.of(context).textTheme.titleMedium),
//           if (!_edit) ...[
//             Text('Name: ${_profile!['full_name'] ?? '-'}'),
//             Text('Phone: ${_profile!['phone_number'] ?? '-'}'),
//             Row(children: [
//               TextButton(onPressed: () => setState(() => _edit = true), child: const Text('Edit')),
//               TextButton(
//                   onPressed: () async {
//                     await _spb.auth.signOut();
//                     context.read<AppState>().signOut();
//                     context.go('/');
//                   },
//                   child: const Text('Logout')),
//             ])
//           ] else ...[
//             TextField(
//                 controller: _nameC, decoration: const InputDecoration(labelText: 'Full name')),
//             TextField(
//                 controller: _phoneC, decoration: const InputDecoration(labelText: 'Phone')),
//             Row(children: [
//               TextButton(
//                   onPressed: () async {
//                     await _spb.from('profiles').update({
//                       'full_name': _nameC.text.trim(),
//                       'phone_number': _phoneC.text.trim(),
//                     }).eq('id', _session!.user.id);
//                     setState(() => _edit = false);
//                     await _load();
//                   },
//                   child: const Text('Save')),
//               TextButton(
//                   onPressed: () => setState(() => _edit = false), child: const Text('Cancel')),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   Widget _sellerPanel() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text('Store Location', style: Theme.of(context).textTheme.titleMedium),
//           Text('Address: $_address'),
//           Text(_locMsg,
//               style: TextStyle(color: _locMsg.startsWith('Warning') ? Colors.red : Colors.green)),
//           const SizedBox(height: 8),
//           Row(children: [
//             ElevatedButton(onPressed: _detectLocation, child: const Text('Detect Location')),
//             const SizedBox(width: 12),
//             ElevatedButton(
//                 onPressed: () => setState(() => _showManualLoc = true),
//                 child: const Text('Enter Manually')),
//           ]),
//           if (_showManualLoc) ...[
//             TextField(
//                 controller: _latC,
//                 decoration: const InputDecoration(labelText: 'Latitude (-90 to 90)'),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true)),
//             TextField(
//                 controller: _lonC,
//                 decoration: const InputDecoration(labelText: 'Longitude (-180 to 180)'),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true)),
//             Row(children: [
//               TextButton(onPressed: _manualLocUpdate, child: const Text('Submit')),
//               TextButton(
//                   onPressed: () => setState(() => _showManualLoc = false),
//                   child: const Text('Cancel')),
//             ]),
//           ],
//           TextButton(
//               onPressed: () => context.push('/seller'), child: const Text('Go to Seller Dashboard')),
//         ]),
//       ),
//     );
//   }

//   Widget _productsGrid() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text('My Products', style: Theme.of(context).textTheme.titleMedium),
//       const SizedBox(height: 8),
//       if (_products.isEmpty) const Text('No products'),
//       if (_products.isNotEmpty)
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.72,
//           children: _products.map((p) => Card(
//                 child: Column(children: [
//                   Expanded(
//                       child: Image.network(
//                           (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://dummyimage.com/150',
//                           fit: BoxFit.cover,
//                           width: double.infinity)),
//                   Padding(
//                       padding: const EdgeInsets.all(6),
//                       child: Text(p['title'], maxLines: 2, overflow: TextOverflow.ellipsis)),
//                   Text('₹${p['price'].toStringAsFixed(2)}'),
//                   TextButton(
//                       onPressed: () => context.push('/product/${p['id']}'),
//                       child: const Text('View')),
//                 ]),
//               )).toList(),
//         ),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//             onPressed: _prodPage == 1
//                 ? null
//                 : () async {
//                     _prodPage--;
//                     await _load();
//                   },
//             child: const Text('Prev')),
//         Text('Page $_prodPage'),
//         TextButton(
//             onPressed: _products.length < _perPage
//                 ? null
//                 : () async {
//                     _prodPage++;
//                     await _load();
//                   },
//             child: const Text('Next')),
//       ])
//     ]);
//   }

//   Widget _ordersList() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(_profile?['is_seller'] == true ? 'Orders Received' : 'My Orders',
//           style: Theme.of(context).textTheme.titleMedium),
//       const SizedBox(height: 8),
//       if (_orders.isEmpty) Text(_profile?['is_seller'] == true ? 'No orders received' : 'No orders'),
//       ..._orders.map((o) => Card(
//             margin: const EdgeInsets.only(bottom: 12),
//             child: ListTile(
//               title: Text('Order #${o['id']}'),
//               subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('Total: ₹${o['total'].toStringAsFixed(2)} • ${o['order_status']}'),
//                 if (o['order_status'] == 'Cancelled') Text('Reason: ${o['cancellation_reason']}'),
//                 if (o['payment_method'] == 'emi' && o['order_status'] == 'pending')
//                   Text('(Waiting for EMI Approval)'),
//                 if (o['estimated_delivery'] != null)
//                   Text('Est. Delivery: ${DateTime.parse(o['estimated_delivery']).toString().substring(0, 16)}'),
//                 if (o['order_items'] != null && (o['order_items'] as List).isNotEmpty)
//                   Text(o['order_items'][0]['products']['title'] ?? 'Unknown Product'),
//                 if (!_profile?['is_seller'] && o['sellers'] != null)
//                   Text('Seller: ${o['sellers']['store_name'] ?? 'Unknown'}'),
//                 if (_profile?['is_seller'] && o['payment_method'] == 'emi' && o['emi_applications'] != null) ...[
//                   Text('Buyer: ${o['emi_applications']['full_name'] ?? 'Unknown'}'),
//                   Text('Buyer Email: ${o['profiles']['email'] ?? 'N/A'}'),
//                 ],
//               ]),
//               trailing: _profile?['is_seller'] == true
//                   ? Column(children: [
//                       if (o['payment_method'] == 'emi' && o['emi_applications']['status'] == 'pending')
//                         DropdownButton<String>(
//                           value: _emiStatusUpdates[o['id']] ?? o['emi_applications']['status'],
//                           items: ['pending', 'approved', 'rejected']
//                               .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                               .toList(),
//                           onChanged: (v) =>
//                               _updateEmiStatus(o['id'], o['emi_applications']['uuid'], v!),
//                         ),
//                       if (o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered')
//                         IconButton(
//                             icon: const Icon(Icons.edit),
//                             onPressed: () async {
//                               final next = await _showStatus(o['order_status']);
//                               if (next != null) _updateOrderStatus(o['id'], next);
//                             }),
//                     ])
//                   : (_cancelId == o['id']
//                       ? null
//                       : o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered'
//                           ? IconButton(
//                               icon: const Icon(Icons.cancel_outlined),
//                               onPressed: () => setState(() => _cancelId = o['id']),
//                             )
//                           : null),
//               onTap: () => context.push('/order-details/${o['id']}'),
//             ),
//           )),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//             onPressed: _orderPage == 1
//                 ? null
//                 : () async {
//                     _orderPage--;
//                     await _load();
//                   },
//             child: const Text('Prev')),
//         Text('Page $_orderPage'),
//         TextButton(
//             onPressed: _orders.length < _perPage
//                 ? null
//                 : () async {
//                     _orderPage++;
//                     await _load();
//                   },
//             child: const Text('Next')),
//       ])
//     ]);
//   }

//   Future<String?> _showStatus(String current) async {
//     const statuses = ['Order Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
//     String? sel = current;
//     final res = await showDialog<String>(
//         context: context,
//         builder: (_) => StatefulBuilder(
//               builder: (_, setD) => AlertDialog(
//                 title: const Text('Update status'),
//                 content: DropdownButton<String>(
//                   value: sel,
//                   isExpanded: true,
//                   items: statuses
//                       .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                       .toList(),
//                   onChanged: (v) => setD(() => sel = v),
//                 ),
//                 actions: [
//                   TextButton(
//                       onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                   TextButton(
//                       onPressed: () => Navigator.pop(context, sel), child: const Text('Save')),
//                 ],
//               ),
//             ));
//     return res == current ? null : res;
//   }

//   Widget _cancelDialog() {
//     final reasons = _profile?['is_seller'] == true ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel order #$_cancelId'),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         DropdownButton<String>(
//           value: _cancelReason.isEmpty ? null : _cancelReason,
//           isExpanded: true,
//           items: reasons
//               .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//               .toList(),
//           onChanged: (v) => setState(() {
//             _cancelReason = v ?? '';
//             _isCustomReason = v == 'Other (please specify)';
//           }),
//         ),
//         if (_isCustomReason)
//           TextField(
//               onChanged: (v) => setState(() => _cancelReason = v),
//               decoration: const InputDecoration(labelText: 'Custom reason')),
//       ]),
//       actions: [
//         TextButton(
//             onPressed: () => setState(() {
//                   _cancelId = null;
//                   _cancelReason = '';
//                   _isCustomReason = false;
//                 }),
//             child: const Text('Back')),
//         TextButton(onPressed: () async => await _cancel(_cancelId!), child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #$_retryOrderId'),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Text('EMI application was rejected. Select a new payment method.'),
//         DropdownButton<String>(
//           value: _newPaymentMethod,
//           isExpanded: true,
//           items: _paymentMethods
//               .map((m) => DropdownMenuItem(
//                     value: m,
//                     child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                   ))
//               .toList(),
//           onChanged: (v) => setState(() => _newPaymentMethod = v!),
//         ),
//       ]),
//       actions: [
//         TextButton(
//             onPressed: () => setState(() => _showRetryPayment = false), child: const Text('Cancel')),
//         TextButton(onPressed: _retryPayment, child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _supportForm() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text('Support', style: Theme.of(context).textTheme.titleMedium),
//           TextField(
//               controller: _supportC,
//               decoration: const InputDecoration(labelText: 'Describe your issue'),
//               maxLines: 4,
//               onChanged: (v) => _supportMsg = v),
//           const SizedBox(height: 8),
//           ElevatedButton(onPressed: _submitSupport, child: const Text('Submit')),
//           const SizedBox(height: 8),
//           Text(
//               'Contact us at support@justorder.com or call 8825287284 (Sunil Rawani). WhatsApp: +918825287284.'),
//         ]),
//       ),
//     );
//   }

//   /* ─── build ──────────────────────────────────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_err != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             Text('Error: $_err'),
//             ElevatedButton(onPressed: _load, child: const Text('Retry')),
//           ]),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Account')),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _profileCard(),
//               const SizedBox(height: 12),
//               _sellerPanel(),
//               const SizedBox(height: 12),
//               _productsGrid(),
//               const SizedBox(height: 12),
//               _ordersList(),
//               const SizedBox(height: 12),
//               _supportForm(),
//               if (_cancelId != null) _cancelDialog(),
//               if (_showRetryPayment) _retryPaymentDialog(),
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
// import '../utils/supabase_utils.dart'; // Assuming this contains the retry function

// const _blr = {'lat': 12.9753, 'lon': 77.591};

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _spb = Supabase.instance.client;

//   /* ─── core models ─────────────────────────────────────────────── */
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];

//   /* ─── ui helpers ──────────────────────────────────────────────── */
//   bool _loading = true;
//   String? _err;
//   String _locMsg = '';
//   String _address = 'Not set';
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // profile edit
//   bool _edit = false;
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController();

//   // geo
//   Map<String, double>? _sellerLoc;
//   Map<String, double>? _buyerLoc;
//   bool _showManualLoc = false;
//   final _latC = TextEditingController();
//   final _lonC = TextEditingController();

//   // cancellation
//   int? _cancelId;
//   String _cancelReason = '';
//   bool _isCustomReason = false;
//   final _buyerReasons = [
//     'Changed my mind',
//     'Found a better price elsewhere',
//     'Item no longer needed',
//     'Other (please specify)'
//   ];
//   final _sellerReasons = [
//     'Out of stock',
//     'Unable to ship',
//     'Buyer request',
//     'Other (please specify)'
//   ];

//   // emi & retry payment
//   Map<int, String> _emiStatusUpdates = {};
//   bool _showRetryPayment = false;
//   int? _retryOrderId;
//   String _newPaymentMethod = 'credit_card';
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   // support
//   String _supportMsg = '';
//   final _supportC = TextEditingController();

//   /* ─── math & network helpers ──────────────────────────────────── */
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

//   Future<String> _fetchAddress(double? lat, double? lon) async {
//     if (lat == null || lon == null) return 'Coordinates unavailable';
//     try {
//       final dio = Dio();
//       final response = await dio.get(
//         'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
//         options: Options(headers: {'User-Agent': 'Markeet/1.0'}),
//       );
//       if (response.statusCode == 200 && response.data['display_name'] != null) {
//         return response.data['display_name'];
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Error fetching address: $e';
//     }
//   }

//   /* ─── data load ──────────────────────────────────────────────── */
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
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single());
//       _nameC.text = _profile?['full_name'] ?? '';
//       _phoneC.text = _profile?['phone_number'] ?? '';

//       // Seller & Products
//       if (_profile?['is_seller'] == true) {
//         _seller = await retry(() => _spb
//             .from('sellers')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single());
//         if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//           _sellerLoc = {'lat': _seller!['latitude'], 'lon': _seller!['longitude']};
//           _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
//           _checkDistance();
//         }

//         _products = await retry(() => _spb
//             .from('products')
//             .select('id, title, price, images')
//             .eq('seller_id', _session!.user.id)
//             .eq('is_approved', true)
//             .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));
//       }

//       // Orders
//       final field = _profile?['is_seller'] == true ? 'seller_id' : 'user_id';
//       final base = _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(status, product_name, product_price, full_name, mobile_number, id),
//         profiles!orders_user_id_fkey(email)
//       ''').eq(field, _session!.user.id).order('created_at', ascending: false);

//       _orders = await retry(() => base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

//       // Fetch store_name for all orders in one query (optimized)
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
//       _err = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /* ─── seller-location helpers ────────────────────────────────── */
//   Future<void> _detectLocation() async {
//     setState(() => _locMsg = 'Detecting…');
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         setState(() => _locMsg = 'Location permission denied. Enter manually.');
//         _showManualLoc = true;
//         return;
//       }
//       final p = await Geolocator.getCurrentPosition();
//       await _setSellerLoc(p.latitude, p.longitude);
//     } catch (e) {
//       setState(() => _locMsg = 'Failed: $e');
//       _showManualLoc = true;
//     }
//   }

//   Future<void> _setSellerLoc(double lat, double lon) async {
//     try {
//       await retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': _seller?['store_name'] ?? 'Store'
//           }));
//       _sellerLoc = {'lat': lat, 'lon': lon};
//       context.read<AppState>().setSellerLocation(lat, lon);
//       _address = await _fetchAddress(lat, lon);
//       _checkDistance();
//       setState(() => _locMsg = 'Location updated: $_address');
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating location: $e');
//     }
//   }

//   void _checkDistance() {
//     if (_sellerLoc == null || _buyerLoc == null) {
//       _locMsg = 'Unable to calculate distance.';
//       return;
//     }
//     final d = _distKm(_buyerLoc!, _sellerLoc!);
//     _locMsg = d <= 40
//         ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
//         : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
//     setState(() => {});
//   }

//   Future<void> _manualLocUpdate() async {
//     final lat = double.tryParse(_latC.text);
//     final lon = double.tryParse(_lonC.text);
//     if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
//       setState(() => _locMsg = 'Invalid latitude or longitude.');
//       return;
//     }
//     await _setSellerLoc(lat, lon);
//     setState(() => _showManualLoc = false);
//     _latC.clear();
//     _lonC.clear();
//   }

//   /* ─── order ops ──────────────────────────────────────────────── */
//   Future<void> _cancel(int id) async {
//     if (_cancelReason.isEmpty) {
//       setState(() => _locMsg = 'Please select a cancellation reason.');
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', id));
//       setState(() {
//         _cancelId = null;
//         _cancelReason = '';
//         _isCustomReason = false;
//         _locMsg = 'Order cancelled successfully.';
//       });
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error cancelling order: $e');
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
//         setState(() => _locMsg = 'Invalid status transition from $current to $status.');
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
//       setState(() => _locMsg = 'Order #$id status updated to $status.');
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating status: $e');
//     }
//   }

//   Future<void> _updateEmiStatus(int orderId, String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         setState(() => _locMsg = 'EMI approved successfully!');
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() {
//           _locMsg = 'EMI rejected. Prompting buyer to retry payment.';
//           _retryOrderId = orderId;
//           _showRetryPayment = true;
//         });
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', orderId));
//       setState(() => _emiStatusUpdates = {..._emiStatusUpdates, orderId: ''});
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating EMI status: $e');
//     }
//   }

//   Future<void> _retryPayment() async {
//     if (_retryOrderId == null) {
//       setState(() => _locMsg = 'Error: No order selected for retry.');
//       return;
//     }
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', _retryOrderId!));
//       setState(() {
//         _showRetryPayment = false;
//         _retryOrderId = null;
//         _newPaymentMethod = 'credit_card';
//         _locMsg = 'Payment method updated successfully.';
//       });
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating payment: $e');
//     }
//   }

//   Future<void> _submitSupport() async {
//     if (_supportMsg.trim().isEmpty) {
//       setState(() => _locMsg = 'Please enter a support message.');
//       return;
//     }
//     try {
//       await retry(() => _spb.from('support_requests').insert({
//         'user_id': _session!.user.id,
//         'message': _supportMsg,
//         'created_at': DateTime.now().toIso8601String(),
//       }));
//       setState(() {
//         _supportMsg = '';
//         _supportC.clear();
//         _locMsg = 'Support request submitted successfully.';
//       });
//     } catch (e) {
//       setState(() => _locMsg = 'Error submitting support request: $e');
//     }
//   }

//   /* ─── lifecycle ──────────────────────────────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _buyerLoc = context.read<AppState>().buyerLocation ?? _blr;
//     _load();
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _phoneC.dispose();
//     _latC.dispose();
//     _lonC.dispose();
//     _supportC.dispose();
//     super.dispose();
//   }

//   /* ─── UI helpers ─────────────────────────────────────────────── */
//   Widget _profileCard() {
//     if (_profile == null) return const SizedBox();
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(_session!.user.email ?? 'No email', style: Theme.of(context).textTheme.titleMedium),
//           if (!_edit) ...[
//             Text('Name: ${_profile!['full_name'] ?? '-'}'),
//             Text('Phone: ${_profile!['phone_number'] ?? '-'}'),
//             Row(children: [
//               TextButton(onPressed: () => setState(() => _edit = true), child: const Text('Edit')),
//               TextButton(
//                   onPressed: () async {
//                     await _spb.auth.signOut();
//                     context.read<AppState>().signOut();
//                     context.go('/');
//                   },
//                   child: const Text('Logout')),
//             ])
//           ] else ...[
//             TextField(
//                 controller: _nameC, decoration: const InputDecoration(labelText: 'Full name')),
//             TextField(
//                 controller: _phoneC, decoration: const InputDecoration(labelText: 'Phone')),
//             Row(children: [
//               TextButton(
//                   onPressed: () async {
//                     await retry(() => _spb.from('profiles').update({
//                       'full_name': _nameC.text.trim(),
//                       'phone_number': _phoneC.text.trim(),
//                     }).eq('id', _session!.user.id));
//                     setState(() => _edit = false);
//                     await _load();
//                   },
//                   child: const Text('Save')),
//               TextButton(
//                   onPressed: () => setState(() => _edit = false), child: const Text('Cancel')),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   Widget _sellerPanel() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text('Store Location', style: Theme.of(context).textTheme.titleMedium),
//           Text('Address: $_address'),
//           Text(_locMsg,
//               style: TextStyle(color: _locMsg.startsWith('Warning') ? Colors.red : Colors.green)),
//           const SizedBox(height: 8),
//           Row(children: [
//             ElevatedButton(onPressed: _detectLocation, child: const Text('Detect Location')),
//             const SizedBox(width: 12),
//             ElevatedButton(
//                 onPressed: () => setState(() => _showManualLoc = true),
//                 child: const Text('Enter Manually')),
//           ]),
//           if (_showManualLoc) ...[
//             TextField(
//                 controller: _latC,
//                 decoration: const InputDecoration(labelText: 'Latitude (-90 to 90)'),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true)),
//             TextField(
//                 controller: _lonC,
//                 decoration: const InputDecoration(labelText: 'Longitude (-180 to 180)'),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true)),
//             Row(children: [
//               TextButton(onPressed: _manualLocUpdate, child: const Text('Submit')),
//               TextButton(
//                   onPressed: () => setState(() => _showManualLoc = false),
//                   child: const Text('Cancel')),
//             ]),
//           ],
//           TextButton(
//               onPressed: () => context.push('/seller'), child: const Text('Go to Seller Dashboard')),
//         ]),
//       ),
//     );
//   }

//   Widget _productsGrid() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text('My Products', style: Theme.of(context).textTheme.titleMedium),
//       const SizedBox(height: 8),
//       if (_products.isEmpty) const Text('No products'),
//       if (_products.isNotEmpty)
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.72,
//           children: _products.map((p) => Card(
//                 child: Column(children: [
//                   Expanded(
//                       child: Image.network(
//                           (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://dummyimage.com/150',
//                           fit: BoxFit.cover,
//                           width: double.infinity)),
//                   Padding(
//                       padding: const EdgeInsets.all(6),
//                       child: Text(p['title'], maxLines: 2, overflow: TextOverflow.ellipsis)),
//                   Text('₹${p['price'].toStringAsFixed(2)}'),
//                   TextButton(
//                       onPressed: () => context.push('/product/${p['id']}'),
//                       child: const Text('View')),
//                 ]),
//               )).toList(),
//         ),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//             onPressed: _prodPage == 1
//                 ? null
//                 : () async {
//                     _prodPage--;
//                     await _load();
//                   },
//             child: const Text('Prev')),
//         Text('Page $_prodPage'),
//         TextButton(
//             onPressed: _products.length < _perPage
//                 ? null
//                 : () async {
//                     _prodPage++;
//                     await _load();
//                   },
//             child: const Text('Next')),
//       ])
//     ]);
//   }

//   Widget _ordersList() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(_profile?['is_seller'] == true ? 'Orders Received' : 'My Orders',
//           style: Theme.of(context).textTheme.titleMedium),
//       const SizedBox(height: 8),
//       if (_orders.isEmpty) Text(_profile?['is_seller'] == true ? 'No orders received' : 'No orders'),
//       ..._orders.map((o) => Card(
//             margin: const EdgeInsets.only(bottom: 12),
//             child: ListTile(
//               title: Text('Order #${o['id']}'),
//               subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('Total: ₹${o['total'].toStringAsFixed(2)} • ${o['order_status']}'),
//                 if (o['order_status'] == 'Cancelled') Text('Reason: ${o['cancellation_reason']}'),
//                 if (o['payment_method'] == 'emi' && o['order_status'] == 'pending')
//                   Text('(Waiting for EMI Approval)'),
//                 if (o['estimated_delivery'] != null)
//                   Text('Est. Delivery: ${o['estimated_delivery'].substring(0, 16)}'),
//                 if (o['order_items'] != null && (o['order_items'] as List).isNotEmpty)
//                   Text(o['order_items'][0]['products']['title'] ?? 'Unknown Product'),
//                 if (!_profile?['is_seller'] && o['sellers'] != null)
//                   Text('Seller: ${o['sellers']['store_name'] ?? 'Unknown'}'),
//                 if (_profile?['is_seller'] && o['payment_method'] == 'emi' && o['emi_applications'] != null) ...[
//                   Text('Buyer: ${o['emi_applications']['full_name'] ?? 'Unknown'}'),
//                   Text('Buyer Email: ${o['profiles']['email'] ?? 'N/A'}'),
//                 ],
//               ]),
//               trailing: _profile?['is_seller'] == true
//                   ? Column(children: [
//                       if (o['payment_method'] == 'emi' && o['emi_applications']['status'] == 'pending')
//                         DropdownButton<String>(
//                           value: _emiStatusUpdates[o['id']] ?? o['emi_applications']['status'],
//                           items: ['pending', 'approved', 'rejected']
//                               .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                               .toList(),
//                           onChanged: (v) =>
//                               _updateEmiStatus(o['id'], o['emi_applications']['id'], v!),
//                         ),
//                       if (o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered')
//                         IconButton(
//                             icon: const Icon(Icons.edit),
//                             onPressed: () async {
//                               final next = await _showStatus(o['order_status']);
//                               if (next != null) _updateOrderStatus(o['id'], next);
//                             }),
//                     ])
//                   : (_cancelId == o['id']
//                       ? null
//                       : o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered'
//                           ? IconButton(
//                               icon: const Icon(Icons.cancel_outlined),
//                               onPressed: () => setState(() => _cancelId = o['id']),
//                             )
//                           : null),
//               onTap: () => context.push('/order-details/${o['id']}'),
//             ),
//           )),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//             onPressed: _orderPage == 1
//                 ? null
//                 : () async {
//                     _orderPage--;
//                     await _load();
//                   },
//             child: const Text('Prev')),
//         Text('Page $_orderPage'),
//         TextButton(
//             onPressed: _orders.length < _perPage
//                 ? null
//                 : () async {
//                     _orderPage++;
//                     await _load();
//                   },
//             child: const Text('Next')),
//       ])
//     ]);
//   }

//   Future<String?> _showStatus(String current) async {
//     const statuses = ['Order Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
//     String? sel = current;
//     final res = await showDialog<String>(
//         context: context,
//         builder: (_) => StatefulBuilder(
//               builder: (_, setD) => AlertDialog(
//                 title: const Text('Update status'),
//                 content: DropdownButton<String>(
//                   value: sel,
//                   isExpanded: true,
//                   items: statuses
//                       .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                       .toList(),
//                   onChanged: (v) => setD(() => sel = v),
//                 ),
//                 actions: [
//                   TextButton(
//                       onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//                   TextButton(
//                       onPressed: () => Navigator.pop(context, sel), child: const Text('Save')),
//                 ],
//               ),
//             ));
//     return res == current ? null : res;
//   }

//   Widget _cancelDialog() {
//     final reasons = _profile?['is_seller'] == true ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel order #$_cancelId'),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         DropdownButton<String>(
//           value: _cancelReason.isEmpty ? null : _cancelReason,
//           isExpanded: true,
//           items: reasons
//               .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//               .toList(),
//           onChanged: (v) => setState(() {
//             _cancelReason = v ?? '';
//             _isCustomReason = v == 'Other (please specify)';
//           }),
//         ),
//         if (_isCustomReason)
//           TextField(
//               onChanged: (v) => setState(() => _cancelReason = v),
//               decoration: const InputDecoration(labelText: 'Custom reason')),
//       ]),
//       actions: [
//         TextButton(
//             onPressed: () => setState(() {
//                   _cancelId = null;
//                   _cancelReason = '';
//                   _isCustomReason = false;
//                 }),
//             child: const Text('Back')),
//         TextButton(onPressed: () async => await _cancel(_cancelId!), child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #$_retryOrderId'),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Text('EMI application was rejected. Select a new payment method.'),
//         DropdownButton<String>(
//           value: _newPaymentMethod,
//           isExpanded: true,
//           items: _paymentMethods
//               .map((m) => DropdownMenuItem(
//                     value: m,
//                     child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                   ))
//               .toList(),
//           onChanged: (v) => setState(() => _newPaymentMethod = v!),
//         ),
//       ]),
//       actions: [
//         TextButton(
//             onPressed: () => setState(() => _showRetryPayment = false), child: const Text('Cancel')),
//         TextButton(onPressed: _retryPayment, child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _supportForm() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text('Support', style: Theme.of(context).textTheme.titleMedium),
//           TextField(
//               controller: _supportC,
//               decoration: const InputDecoration(labelText: 'Describe your issue'),
//               maxLines: 4,
//               onChanged: (v) => _supportMsg = v),
//           const SizedBox(height: 8),
//           ElevatedButton(onPressed: _submitSupport, child: const Text('Submit')),
//           const SizedBox(height: 8),
//           Text(
//               'Contact us at support@justorder.com or call 8825287284 (Sunil Rawani). WhatsApp: +918825287284.'),
//         ]),
//       ),
//     );
//   }

//   /* ─── build ──────────────────────────────────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_err != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             Text('Error: $_err'),
//             ElevatedButton(onPressed: _load, child: const Text('Retry')),
//           ]),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Account')),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _profileCard(),
//               const SizedBox(height: 12),
//               _sellerPanel(),
//               const SizedBox(height: 12),
//               _productsGrid(),
//               const SizedBox(height: 12),
//               _ordersList(),
//               const SizedBox(height: 12),
//               _supportForm(),
//               if (_cancelId != null) _cancelDialog(),
//               if (_showRetryPayment) _retryPaymentDialog(),
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
// import '../utils/supabase_utils.dart'; // Assuming this contains the retry function

// const _blr = {'lat': 12.9753, 'lon': 77.591};

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _spb = Supabase.instance.client;

//   /* ─── core models ─────────────────────────────────────────────── */
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];

//   /* ─── ui helpers ──────────────────────────────────────────────── */
//   bool _loading = true;
//   String? _err;
//   String _locMsg = '';
//   String _address = 'Not set';
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // profile edit
//   bool _edit = false;
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController();

//   // geo
//   Map<String, double>? _sellerLoc;
//   Map<String, double>? _buyerLoc;
//   bool _showManualLoc = false;
//   final _latC = TextEditingController();
//   final _lonC = TextEditingController();

//   // cancellation
//   int? _cancelId;
//   String _cancelReason = '';
//   bool _isCustomReason = false;
//   final _buyerReasons = [
//     'Changed my mind',
//     'Found a better price elsewhere',
//     'Item no longer needed',
//     'Other (please specify)'
//   ];
//   final _sellerReasons = [
//     'Out of stock',
//     'Unable to ship',
//     'Buyer request',
//     'Other (please specify)'
//   ];

//   // emi & retry payment
//   Map<int, String> _emiStatusUpdates = {};
//   bool _showRetryPayment = false;
//   int? _retryOrderId;
//   String _newPaymentMethod = 'credit_card';
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   // support
//   String _supportMsg = '';
//   final _supportC = TextEditingController();

//   /* ─── math & network helpers ──────────────────────────────────── */
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

//   Future<String> _fetchAddress(double? lat, double? lon) async {
//     if (lat == null || lon == null) return 'Coordinates unavailable';
//     try {
//       final dio = Dio();
//       final response = await dio.get(
//         'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
//         options: Options(headers: {'User-Agent': 'Markeet/1.0'}),
//       );
//       if (response.statusCode == 200 && response.data['display_name'] != null) {
//         return response.data['display_name'];
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Error fetching address: $e';
//     }
//   }

//   /* ─── data load ──────────────────────────────────────────────── */
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
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single());
//       _nameC.text = _profile?['full_name'] ?? '';
//       _phoneC.text = _profile?['phone_number'] ?? '';

//       // Seller & Products
//       if (_profile?['is_seller'] == true) {
//         _seller = await retry(() => _spb
//             .from('sellers')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single());
//         if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//           _sellerLoc = {'lat': _seller!['latitude'], 'lon': _seller!['longitude']};
//           _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
//           _checkDistance();
//         }

//         _products = await retry(() => _spb
//             .from('products')
//             .select('id, title, price, images')
//             .eq('seller_id', _session!.user.id)
//             .eq('is_approved', true)
//             .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));
//       }

//       // Orders
//       final field = _profile?['is_seller'] == true ? 'seller_id' : 'user_id';
//       final base = _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications!orders_emi_application_uuid_fkey(status, product_name, product_price, full_name, mobile_number, seller_name, id),
//         profiles!orders_user_id_fkey(email)
//       ''').eq(field, _session!.user.id).order('created_at', ascending: false);

//       _orders = await retry(() => base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

//       // Fetch store_name for all orders in one query (optimized)
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
//       _err = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /* ─── seller-location helpers ────────────────────────────────── */
//   Future<void> _detectLocation() async {
//     setState(() => _locMsg = 'Detecting…');
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         setState(() => _locMsg = 'Location permission denied. Enter manually.');
//         _showManualLoc = true;
//         return;
//       }
//       final p = await Geolocator.getCurrentPosition();
//       await _setSellerLoc(p.latitude, p.longitude);
//     } catch (e) {
//       setState(() => _locMsg = 'Failed: $e');
//       _showManualLoc = true;
//     }
//   }

//   Future<void> _setSellerLoc(double lat, double lon) async {
//     try {
//       await retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': _seller?['store_name'] ?? 'Store'
//           }));
//       _sellerLoc = {'lat': lat, 'lon': lon};
//       context.read<AppState>().setSellerLocation(lat, lon);
//       _address = await _fetchAddress(lat, lon);
//       _checkDistance();
//       setState(() => _locMsg = 'Location updated: $_address');
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating location: $e');
//     }
//   }

//   void _checkDistance() {
//     if (_sellerLoc == null || _buyerLoc == null) {
//       _locMsg = 'Unable to calculate distance.';
//       return;
//     }
//     final d = _distKm(_buyerLoc!, _sellerLoc!);
//     _locMsg = d <= 40
//         ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
//         : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
//     setState(() => {});
//   }

//   Future<void> _manualLocUpdate() async {
//     final lat = double.tryParse(_latC.text);
//     final lon = double.tryParse(_lonC.text);
//     if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
//       setState(() => _locMsg = 'Invalid latitude or longitude.');
//       return;
//     }
//     await _setSellerLoc(lat, lon);
//     setState(() => _showManualLoc = false);
//     _latC.clear();
//     _lonC.clear();
//   }

//   /* ─── order ops ──────────────────────────────────────────────── */
//   Future<void> _cancel(int id) async {
//     if (_cancelReason.isEmpty) {
//       setState(() => _locMsg = 'Please select a cancellation reason.');
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', id));
//       setState(() {
//         _cancelId = null;
//         _cancelReason = '';
//         _isCustomReason = false;
//         _locMsg = 'Order cancelled successfully.';
//       });
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error cancelling order: $e');
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
//         setState(() => _locMsg = 'Invalid status transition from $current to $status.');
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
//       setState(() => _locMsg = 'Order #$id status updated to $status.');
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating status: $e');
//     }
//   }

//   Future<void> _updateEmiStatus(int orderId, String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         setState(() => _locMsg = 'EMI approved successfully!');
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() {
//           _locMsg = 'EMI rejected. Prompting buyer to retry payment.';
//           _retryOrderId = orderId;
//           _showRetryPayment = true;
//         });
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', orderId));
//       setState(() => _emiStatusUpdates = {..._emiStatusUpdates, orderId: ''});
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating EMI status: $e');
//     }
//   }

//   Future<void> _retryPayment() async {
//     if (_retryOrderId == null) {
//       setState(() => _locMsg = 'Error: No order selected for retry.');
//       return;
//     }
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', _retryOrderId!));
//       setState(() {
//         _showRetryPayment = false;
//         _retryOrderId = null;
//         _newPaymentMethod = 'credit_card';
//         _locMsg = 'Payment method updated successfully.';
//       });
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating payment: $e');
//     }
//   }

//   Future<void> _submitSupport() async {
//     if (_supportMsg.trim().isEmpty) {
//       setState(() => _locMsg = 'Please enter a support message.');
//       return;
//     }
//     try {
//       await retry(() => _spb.from('support_requests').insert({
//         'user_id': _session!.user.id,
//         'message': _supportMsg,
//         'created_at': DateTime.now().toIso8601String(),
//       }));
//       setState(() {
//         _supportMsg = '';
//         _supportC.clear();
//         _locMsg = 'Support request submitted successfully.';
//       });
//     } catch (e) {
//       setState(() => _locMsg = 'Error submitting support request: $e');
//     }
//   }

//   /* ─── lifecycle ──────────────────────────────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _buyerLoc = context.read<AppState>().buyerLocation ?? _blr;
//     _load();
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _phoneC.dispose();
//     _latC.dispose();
//     _lonC.dispose();
//     _supportC.dispose();
//     super.dispose();
//   }

//   /* ─── UI helpers ─────────────────────────────────────────────── */
//   Widget _profileCard() {
//     if (_profile == null) return const SizedBox();
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             _session!.user.email ?? 'No email',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           if (!_edit) ...[
//             Text('Name: ${_profile!['full_name'] ?? '-'}'),
//             Text('Phone: ${_profile!['phone_number'] ?? '-'}'),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: () => setState(() => _edit = true),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Edit'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () async {
//                   await _spb.auth.signOut();
//                   context.read<AppState>().signOut();
//                   context.go('/');
//                 },
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.red),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Logout', style: TextStyle(color: Colors.red)),
//               ),
//             ])
//           ] else ...[
//             TextField(
//               controller: _nameC,
//               decoration: const InputDecoration(
//                 labelText: 'Full name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _phoneC,
//               decoration: const InputDecoration(
//                 labelText: 'Phone',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.phone,
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: () async {
//                   await retry(() => _spb.from('profiles').update({
//                     'full_name': _nameC.text.trim(),
//                     'phone_number': _phoneC.text.trim(),
//                   }).eq('id', _session!.user.id));
//                   setState(() => _edit = false);
//                   await _load();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Save'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => setState(() => _edit = false),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.grey),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   Widget _sellerPanel() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             'Store Location',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text('Address: $_address'),
//           const SizedBox(height: 4),
//           Text(
//             _locMsg,
//             style: TextStyle(
//               color: _locMsg.startsWith('Warning') ? Colors.red : Colors.green,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(children: [
//             ElevatedButton(
//               onPressed: _detectLocation,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Detect Location'),
//             ),
//             const SizedBox(width: 12),
//             OutlinedButton(
//               onPressed: () => setState(() => _showManualLoc = true),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.blueAccent),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Enter Manually'),
//             ),
//           ]),
//           if (_showManualLoc) ...[
//             const SizedBox(height: 12),
//             TextField(
//               controller: _latC,
//               decoration: const InputDecoration(
//                 labelText: 'Latitude (-90 to 90)',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _lonC,
//               decoration: const InputDecoration(
//                 labelText: 'Longitude (-180 to 180)',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: _manualLocUpdate,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Submit'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => setState(() => _showManualLoc = false),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.grey),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ]),
//           ],
//           const SizedBox(height: 12),
//           TextButton(
//             onPressed: () => context.push('/seller'),
//             child: const Text(
//               'Go to Seller Dashboard',
//               style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }

//   Widget _productsGrid() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         'My Products',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       if (_products.isEmpty)
//         const Text(
//           'No products',
//           style: TextStyle(color: Colors.grey),
//         ),
//       if (_products.isNotEmpty)
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.72,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           children: _products.map((p) {
//             final imageUrl = (p['images'] as List?)?.isNotEmpty == true
//                 ? p['images'][0]
//                 : 'https://dummyimage.com/150';
//             return Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       errorBuilder: (context, error, stackTrace) => const Icon(
//                         Icons.image_not_supported,
//                         size: 50,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         p['title'] ?? 'Unnamed Product',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '₹${p['price'].toStringAsFixed(2)}',
//                         style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       Center(
//                         child: TextButton(
//                           onPressed: () => context.push('/product/${p['id']}'),
//                           child: const Text(
//                             'View',
//                             style: TextStyle(color: Colors.blueAccent),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ]),
//             );
//           }).toList(),
//         ),
//       const SizedBox(height: 12),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//           onPressed: _prodPage == 1
//               ? null
//               : () async {
//                   _prodPage--;
//                   await _load();
//                 },
//           child: const Text('Prev'),
//         ),
//         Text('Page $_prodPage'),
//         TextButton(
//           onPressed: _products.length < _perPage
//               ? null
//               : () async {
//                   _prodPage++;
//                   await _load();
//                 },
//           child: const Text('Next'),
//         ),
//       ])
//     ]);
//   }

//   Widget _ordersList() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         _profile?['is_seller'] == true ? 'Orders Received' : 'My Orders',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       if (_orders.isEmpty)
//         Text(
//           _profile?['is_seller'] == true ? 'No orders received' : 'No orders',
//           style: const TextStyle(color: Colors.grey),
//         ),
//       ..._orders.map((o) {
//         final orderItems = o['order_items'] as List?;
//         final emiApp = o['emi_applications'];
//         final firstItem = orderItems != null && orderItems.isNotEmpty ? orderItems[0] : null;
//         final productTitle = firstItem != null ? firstItem['products']['title'] ?? 'Unknown Product' : 'N/A';
//         final imageUrl = firstItem != null && (firstItem['products']['images'] as List?)?.isNotEmpty == true
//             ? firstItem['products']['images'][0]
//             : 'https://dummyimage.com/150';

//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           margin: const EdgeInsets.only(bottom: 12),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         imageUrl,
//                         width: 72,
//                         height: 72,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) => const Icon(
//                           Icons.image_not_supported,
//                           size: 72,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Order #${o['id']}',
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Total: ₹${o['total'].toStringAsFixed(2)} • ${o['order_status']}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           if (o['order_status'] == 'Cancelled')
//                             Text(
//                               'Reason: ${o['cancellation_reason']}',
//                               style: const TextStyle(color: Colors.red, fontSize: 14),
//                             ),
//                           if (o['payment_method'] == 'emi' && o['order_status'] == 'pending')
//                             Text(
//                               '(Waiting for EMI Approval)',
//                               style: const TextStyle(color: Colors.orange, fontSize: 14),
//                             ),
//                           if (o['estimated_delivery'] != null)
//                             Text(
//                               'Est. Delivery: ${o['estimated_delivery'].substring(0, 16)}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Product: $productTitle',
//                             style: const TextStyle(fontSize: 14),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (!_profile?['is_seller'] && o['sellers'] != null)
//                             Text(
//                               'Seller: ${o['sellers']['store_name'] ?? 'Unknown'}',
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                             ),
//                           if (_profile?['is_seller'] && o['payment_method'] == 'emi' && emiApp != null) ...[
//                             Text(
//                               'Buyer: ${emiApp['full_name'] ?? 'Unknown'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             Text(
//                               'Buyer Email: ${o['profiles']['email'] ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             Text(
//                               'EMI Product: ${emiApp['product_name'] ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             Text(
//                               'EMI Price: ₹${emiApp['product_price']?.toStringAsFixed(2) ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                           if (o['shipping_address'] != null)
//                             Text(
//                               'Shipping: ${o['shipping_address']}',
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         if (_profile?['is_seller'] == true) ...[
//                           if (o['payment_method'] == 'emi' && emiApp?['status'] == 'pending')
//                             DropdownButton<String>(
//                               value: _emiStatusUpdates[o['id']] ?? emiApp['status'],
//                               items: ['pending', 'approved', 'rejected']
//                                   .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                   .toList(),
//                               onChanged: (v) => _updateEmiStatus(o['id'], emiApp['id'], v!),
//                             ),
//                           if (o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered')
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.blueAccent),
//                               onPressed: () async {
//                                 final next = await _showStatus(o['order_status']);
//                                 if (next != null) _updateOrderStatus(o['id'], next);
//                               },
//                             ),
//                         ] else ...[
//                           if (_cancelId != o['id'] &&
//                               o['order_status'] != 'Cancelled' &&
//                               o['order_status'] != 'Delivered')
//                             IconButton(
//                               icon: const Icon(Icons.cancel_outlined, color: Colors.red),
//                               onPressed: () => setState(() => _cancelId = o['id']),
//                             ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () => context.push('/order-details/${o['id']}'),
//                     child: const Text(
//                       'View Details',
//                       style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//       const SizedBox(height: 12),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//           onPressed: _orderPage == 1
//               ? null
//               : () async {
//                   _orderPage--;
//                   await _load();
//                 },
//           child: const Text('Prev'),
//         ),
//         Text('Page $_orderPage'),
//         TextButton(
//           onPressed: _orders.length < _perPage
//               ? null
//               : () async {
//                   _orderPage++;
//                   await _load();
//                 },
//           child: const Text('Next'),
//         ),
//       ])
//     ]);
//   }

//   Future<String?> _showStatus(String current) async {
//     const statuses = ['Order Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
//     String? sel = current;
//     final res = await showDialog<String>(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (_, setD) => AlertDialog(
//           title: const Text('Update status'),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           content: DropdownButton<String>(
//             value: sel,
//             isExpanded: true,
//             items: statuses
//                 .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                 .toList(),
//             onChanged: (v) => setD(() => sel = v),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, sel),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//     return res == current ? null : res;
//   }

//   Widget _cancelDialog() {
//     final reasons = _profile?['is_seller'] == true ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel order #$_cancelId'),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         DropdownButton<String>(
//           value: _cancelReason.isEmpty ? null : _cancelReason,
//           isExpanded: true,
//           hint: const Text('Select a reason'),
//           items: reasons
//               .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//               .toList(),
//           onChanged: (v) => setState(() {
//             _cancelReason = v ?? '';
//             _isCustomReason = v == 'Other (please specify)';
//           }),
//         ),
//         if (_isCustomReason)
//           TextField(
//             onChanged: (v) => setState(() => _cancelReason = v),
//             decoration: const InputDecoration(
//               labelText: 'Custom reason',
//               border: OutlineInputBorder(),
//             ),
//           ),
//       ]),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() {
//             _cancelId = null;
//             _cancelReason = '';
//             _isCustomReason = false;
//           }),
//           child: const Text('Back'),
//         ),
//         ElevatedButton(
//           onPressed: () async => await _cancel(_cancelId!),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: const Text('Confirm'),
//         ),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #$_retryOrderId'),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Text('EMI application was rejected. Select a new payment method.'),
//         DropdownButton<String>(
//           value: _newPaymentMethod,
//           isExpanded: true,
//           items: _paymentMethods
//               .map((m) => DropdownMenuItem(
//                     value: m,
//                     child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                   ))
//               .toList(),
//           onChanged: (v) => setState(() => _newPaymentMethod = v!),
//         ),
//       ]),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _retryPayment,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: const Text('Confirm'),
//         ),
//       ],
//     );
//   }

//   Widget _supportForm() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             'Support',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _supportC,
//             decoration: const InputDecoration(
//               labelText: 'Describe your issue',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 4,
//             onChanged: (v) => _supportMsg = v,
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _submitSupport,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//             ),
//             child: const Text('Submit'),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Contact us at support@justorder.com or call 8825287284 (Sunil Rawani). WhatsApp: +918825287284.',
//             style: const TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//         ]),
//       ),
//     );
//   }

//   /* ─── build ──────────────────────────────────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     if (_err != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 12),
//             Text(
//               'Error: $_err',
//               style: const TextStyle(color: Colors.red, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: _load,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Retry'),
//             ),
//           ]),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Account'),
//         elevation: 4,
//         shadowColor: Colors.grey.withOpacity(0.3),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _profileCard(),
//               const SizedBox(height: 16),
//               _sellerPanel(),
//               const SizedBox(height: 16),
//               _productsGrid(),
//               const SizedBox(height: 16),
//               _ordersList(),
//               const SizedBox(height: 16),
//               _supportForm(),
//               if (_cancelId != null) _cancelDialog(),
//               if (_showRetryPayment) _retryPaymentDialog(),
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
// import '../utils/supabase_utils.dart'; // Assuming this contains the retry function

// const _blr = {'lat': 12.9753, 'lon': 77.591};

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _spb = Supabase.instance.client;

//   /* ─── core models ─────────────────────────────────────────────── */
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];

//   /* ─── ui helpers ──────────────────────────────────────────────── */
//   bool _loading = true;
//   String? _err;
//   String _locMsg = '';
//   String _address = 'Not set';
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // profile edit
//   bool _edit = false;
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController();

//   // geo
//   Map<String, double>? _sellerLoc;
//   Map<String, double>? _buyerLoc;
//   bool _showManualLoc = false;
//   final _latC = TextEditingController();
//   final _lonC = TextEditingController();

//   // cancellation
//   int? _cancelId;
//   String _cancelReason = '';
//   bool _isCustomReason = false;
//   final _buyerReasons = [
//     'Changed my mind',
//     'Found a better price elsewhere',
//     'Item no longer needed',
//     'Other (please specify)'
//   ];
//   final _sellerReasons = [
//     'Out of stock',
//     'Unable to ship',
//     'Buyer request',
//     'Other (please specify)'
//   ];

//   // emi & retry payment
//   Map<int, String> _emiStatusUpdates = {};
//   bool _showRetryPayment = false;
//   int? _retryOrderId;
//   String _newPaymentMethod = 'credit_card';
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   // support
//   String _supportMsg = '';
//   final _supportC = TextEditingController();

//   /* ─── math & network helpers ──────────────────────────────────── */
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

//   Future<String> _fetchAddress(double? lat, double? lon) async {
//     if (lat == null || lon == null) return 'Coordinates unavailable';
//     try {
//       final dio = Dio();
//       final response = await dio.get(
//         'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
//         options: Options(headers: {'User-Agent': 'Markeet/1.0'}),
//       );
//       if (response.statusCode == 200 && response.data['display_name'] != null) {
//         return response.data['display_name'];
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Error fetching address: $e';
//     }
//   }

//   /* ─── data load ──────────────────────────────────────────────── */
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
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single());
//       _nameC.text = _profile?['full_name'] ?? '';
//       _phoneC.text = _profile?['phone_number'] ?? '';

//       // Set buyer location
//       if (_profile?['latitude'] != null && _profile?['longitude'] != null) {
//         _buyerLoc = {
//           'lat': (_profile!['latitude'] as num).toDouble(),
//           'lon': (_profile!['longitude'] as num).toDouble(),
//         };
//       } else {
//         _buyerLoc = _blr;
//       }

//       // Seller & Products
//       if (_profile?['is_seller'] == true) {
//         _seller = await retry(() => _spb
//             .from('sellers')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single());
//         if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//           _sellerLoc = {
//             'lat': (_seller!['latitude'] as num).toDouble(),
//             'lon': (_seller!['longitude'] as num).toDouble(),
//           };
//           _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
//           _checkDistance();
//         } else {
//           _sellerLoc = null;
//           _address = 'Location not set';
//         }

//         _products = await retry(() => _spb
//             .from('products')
//             .select('id, title, price, images')
//             .eq('seller_id', _session!.user.id)
//             .eq('is_approved', true)
//             .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));
//       }

//       // Orders
//       final field = _profile?['is_seller'] == true ? 'seller_id' : 'user_id';
//       final base = _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications!orders_emi_application_uuid_fkey(status, product_name, product_price, full_name, mobile_number, seller_name, id),
//         profiles!orders_user_id_fkey(email)
//       ''').eq(field, _session!.user.id).order('created_at', ascending: false);

//       _orders = await retry(() => base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

//       // Fetch store_name for all orders in one query (optimized)
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
//       _err = e.toString();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /* ─── seller-location helpers ────────────────────────────────── */
//   Future<void> _detectLocation() async {
//     setState(() => _locMsg = 'Detecting…');
//     _clearLocMsg();
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         setState(() => _locMsg = 'Location permission denied. Enter manually.');
//         _showManualLoc = true;
//         _clearLocMsg();
//         return;
//       }
//       final p = await Geolocator.getCurrentPosition();
//       await _setSellerLoc(p.latitude, p.longitude);
//     } catch (e) {
//       setState(() => _locMsg = 'Failed: $e');
//       _clearLocMsg();
//       _showManualLoc = true;
//     }
//   }

//   Future<void> _setSellerLoc(double lat, double lon) async {
//     try {
//       await retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': _seller?['store_name'] ?? 'Store'
//           }));
//       _sellerLoc = {'lat': lat, 'lon': lon};
//       context.read<AppState>().setSellerLocation(lat, lon);
//       _address = await _fetchAddress(lat, lon);
//       _checkDistance();
//       setState(() => _locMsg = 'Location updated: $_address');
//       _clearLocMsg();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating location: $e');
//       _clearLocMsg();
//     }
//   }

//   void _checkDistance() {
//     if (_sellerLoc == null || _buyerLoc == null) {
//       setState(() => _locMsg = 'Unable to calculate distance due to missing location data.');
//       _clearLocMsg();
//       return;
//     }
//     final d = _distKm(_buyerLoc!, _sellerLoc!);
//     setState(() {
//       _locMsg = d <= 40
//           ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
//           : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
//     });
//     _clearLocMsg();
//   }

//   Future<void> _manualLocUpdate() async {
//     final lat = double.tryParse(_latC.text);
//     final lon = double.tryParse(_lonC.text);
//     if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
//       setState(() => _locMsg = 'Invalid latitude or longitude.');
//       _clearLocMsg();
//       return;
//     }
//     await _setSellerLoc(lat, lon);
//     setState(() => _showManualLoc = false);
//     _latC.clear();
//     _lonC.clear();
//   }

//   void _clearLocMsg() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (mounted) setState(() => _locMsg = '');
//     });
//   }

//   /* ─── order ops ──────────────────────────────────────────────── */
//   Future<void> _cancel(int id) async {
//     if (_cancelReason.isEmpty) {
//       setState(() => _locMsg = 'Please select a cancellation reason.');
//       _clearLocMsg();
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', id));
//       setState(() {
//         _cancelId = null;
//         _cancelReason = '';
//         _isCustomReason = false;
//         _locMsg = 'Order cancelled successfully.';
//       });
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error cancelling order: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _updateOrderStatus(int id, String status) async {
//     try {
//       const validTransitions = {
//         'pending': ['Order Placed', 'Cancelled'],
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _orders.firstWhere((o) => o['id'] == id)['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         setState(() => _locMsg = 'Invalid status transition from $current to $status.');
//         _clearLocMsg();
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
//       setState(() => _locMsg = 'Order #$id status updated to $status.');
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating status: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _updateEmiStatus(int orderId, String emiAppId, String newStatus) async {
//     try {
//       const validEmiTransitions = {
//         'pending': ['approved', 'rejected'],
//         'approved': [],
//         'rejected': [],
//       };
//       final emiApp = _orders.firstWhere((o) => o['id'] == orderId)['emi_applications'];
//       if (emiApp == null) {
//         setState(() => _locMsg = 'EMI application not found for order #$orderId.');
//         _clearLocMsg();
//         return;
//       }
//       final currentStatus = emiApp['status'];
//       if (!validEmiTransitions[currentStatus]!.contains(newStatus)) {
//         setState(() => _locMsg = 'Invalid EMI status transition from $currentStatus to $newStatus.');
//         _clearLocMsg();
//         return;
//       }

//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';

//         // Recalculate estimated delivery for EMI orders based on current time
//         final now = DateTime.now();
//         final distance = _distKm(_buyerLoc!, _sellerLoc!);
//         final estimatedDelivery = distance <= 40
//             ? now.add(const Duration(hours: 24)) // 24 hours from now for ≤40 km
//             : now.add(const Duration(hours: 48)); // 48 hours from now for >40 km
//         await retry(() => _spb.from('orders').update({
//           'order_status': orderStatus,
//           'estimated_delivery': estimatedDelivery.toIso8601String(),
//         }).eq('id', orderId));

//         setState(() => _locMsg = 'EMI approved successfully!');
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() {
//           _locMsg = 'EMI rejected. Prompting buyer to retry payment.';
//           _retryOrderId = orderId;
//           _showRetryPayment = true;
//         });
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', orderId));
//       setState(() => _emiStatusUpdates = {..._emiStatusUpdates, orderId: ''});
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating EMI status: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _retryPayment() async {
//     if (_retryOrderId == null) {
//       setState(() => _locMsg = 'Error: No order selected for retry.');
//       _clearLocMsg();
//       return;
//     }
//     try {
//       // Recalculate estimated delivery for non-EMI orders after retry based on current time
//       final now = DateTime.now();
//       final distance = _distKm(_buyerLoc!, _sellerLoc!);
//       final estimatedDelivery = distance <= 40
//           ? now.add(const Duration(hours: 15)) // 15 hours from now for ≤40 km
//           : now.add(const Duration(hours: 36)); // 36 hours from now for >40 km

//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//         'estimated_delivery': estimatedDelivery.toIso8601String(),
//       }).eq('id', _retryOrderId!));
//       setState(() {
//         _showRetryPayment = false;
//         _retryOrderId = null;
//         _newPaymentMethod = 'credit_card';
//         _locMsg = 'Payment method updated successfully.';
//       });
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating payment: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _submitSupport() async {
//     if (_supportMsg.trim().isEmpty) {
//       setState(() => _locMsg = 'Please enter a support message.');
//       _clearLocMsg();
//       return;
//     }
//     try {
//       await retry(() => _spb.from('support_requests').insert({
//         'user_id': _session!.user.id,
//         'message': _supportMsg,
//         'created_at': DateTime.now().toIso8601String(),
//       }));
//       setState(() {
//         _supportMsg = '';
//         _supportC.clear();
//         _locMsg = 'Support request submitted successfully.';
//       });
//       _clearLocMsg();
//     } catch (e) {
//       setState(() => _locMsg = 'Error submitting support request: $e');
//       _clearLocMsg();
//     }
//   }

//   /* ─── lifecycle ──────────────────────────────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _buyerLoc = context.read<AppState>().buyerLocation ?? _blr;
//     _load();
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _phoneC.dispose();
//     _latC.dispose();
//     _lonC.dispose();
//     _supportC.dispose();
//     super.dispose();
//   }

//   /* ─── UI helpers ─────────────────────────────────────────────── */
//   Widget _profileCard() {
//     if (_profile == null) return const SizedBox();
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             _session!.user.email ?? 'No email',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           if (!_edit) ...[
//             Text('Name: ${_profile!['full_name'] ?? '-'}'),
//             Text('Phone: ${_profile!['phone_number'] ?? '-'}'),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: () => setState(() => _edit = true),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Edit'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () async {
//                   await _spb.auth.signOut();
//                   final error = await context.read<AppState>().signOut();
//                   if (error != null && mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(error), backgroundColor: Colors.red),
//                     );
//                   } else {
//                     context.go('/');
//                   }
//                 },
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.red),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Logout', style: TextStyle(color: Colors.red)),
//               ),
//             ])
//           ] else ...[
//             TextField(
//               controller: _nameC,
//               decoration: const InputDecoration(
//                 labelText: 'Full name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _phoneC,
//               decoration: const InputDecoration(
//                 labelText: 'Phone (10 digits)',
//                 border: OutlineInputBorder(),
//                 hintText: 'e.g., 9123456789',
//               ),
//               keyboardType: TextInputType.phone,
//               maxLength: 10,
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: () async {
//                   final phone = _phoneC.text.trim();
//                   if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Please enter a valid 10-digit phone number.'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                     return;
//                   }
//                   await retry(() => _spb.from('profiles').update({
//                     'full_name': _nameC.text.trim(),
//                     'phone_number': phone,
//                   }).eq('id', _session!.user.id));
//                   setState(() => _edit = false);
//                   await _load();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Save'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => setState(() => _edit = false),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.grey),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   Widget _sellerPanel() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             'Store Location',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text('Address: $_address'),
//           const SizedBox(height: 4),
//           Text(
//             _locMsg,
//             style: TextStyle(
//               color: _locMsg.startsWith('Warning') ? Colors.red : Colors.green,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(children: [
//             ElevatedButton(
//               onPressed: _detectLocation,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Detect Location'),
//             ),
//             const SizedBox(width: 12),
//             OutlinedButton(
//               onPressed: () => setState(() => _showManualLoc = true),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.blueAccent),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Enter Manually'),
//             ),
//           ]),
//           if (_showManualLoc) ...[
//             const SizedBox(height: 12),
//             TextField(
//               controller: _latC,
//               decoration: const InputDecoration(
//                 labelText: 'Latitude (-90 to 90)',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _lonC,
//               decoration: const InputDecoration(
//                 labelText: 'Longitude (-180 to 180)',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: _manualLocUpdate,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Submit'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => setState(() => _showManualLoc = false),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.grey),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ]),
//           ],
//           const SizedBox(height: 12),
//           TextButton(
//             onPressed: () => context.push('/seller'),
//             child: const Text(
//               'Go to Seller Dashboard',
//               style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }

//   Widget _productsGrid() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         'My Products',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       if (_products.isEmpty)
//         const Text(
//           'No products',
//           style: TextStyle(color: Colors.grey),
//         ),
//       if (_products.isNotEmpty)
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.72,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           children: _products.map((p) {
//             final imageUrl = (p['images'] as List?)?.isNotEmpty == true
//                 ? p['images'][0]
//                 : 'https://dummyimage.com/150';
//             return Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       errorBuilder: (context, error, stackTrace) => const Icon(
//                         Icons.image_not_supported,
//                         size: 50,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         p['title'] ?? 'Unnamed Product',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '₹${(p['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                         style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       Center(
//                         child: TextButton(
//                           onPressed: () => context.push('/product/${p['id']}'),
//                           child: const Text(
//                             'View',
//                             style: TextStyle(color: Colors.blueAccent),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ]),
//             );
//           }).toList(),
//         ),
//       const SizedBox(height: 12),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//           onPressed: _prodPage == 1
//               ? null
//               : () async {
//                   _prodPage--;
//                   await _load();
//                 },
//           child: const Text('Prev'),
//         ),
//         Text('Page $_prodPage'),
//         TextButton(
//           onPressed: _products.length < _perPage
//               ? null
//               : () async {
//                   _prodPage++;
//                   await _load();
//                 },
//           child: const Text('Next'),
//         ),
//       ])
//     ]);
//   }

//   Widget _ordersList() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         _profile?['is_seller'] == true ? 'Orders Received' : 'My Orders',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       if (_orders.isEmpty)
//         Text(
//           _profile?['is_seller'] == true ? 'No orders received' : 'No orders',
//           style: const TextStyle(color: Colors.grey),
//         ),
//       ..._orders.map((o) {
//         final orderItems = o['order_items'] as List?;
//         final emiApp = o['emi_applications'];
//         final firstItem = orderItems != null && orderItems.isNotEmpty ? orderItems[0] : null;
//         final productTitle = firstItem != null
//             ? (firstItem['products'] != null ? firstItem['products']['title'] ?? 'Unknown Product' : 'Unknown Product')
//             : 'N/A';
//         final imageUrl = firstItem != null && firstItem['products'] != null
//             ? (firstItem['products']['images'] as List?)?.isNotEmpty == true
//                 ? firstItem['products']['images'][0]
//                 : 'https://dummyimage.com/150'
//             : 'https://dummyimage.com/150';

//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           margin: const EdgeInsets.only(bottom: 12),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         imageUrl,
//                         width: 72,
//                         height: 72,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) => const Icon(
//                           Icons.image_not_supported,
//                           size: 72,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Order #${o['id']}',
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Total: ₹${(o['total'] as num?)?.toStringAsFixed(2) ?? '0.00'} • ${o['order_status']}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           if (o['order_status'] == 'Cancelled')
//                             Text(
//                               'Reason: ${o['cancellation_reason'] ?? 'N/A'}',
//                               style: const TextStyle(color: Colors.red, fontSize: 14),
//                             ),
//                           if (o['payment_method'] == 'emi' && o['order_status'] == 'pending')
//                             const Text(
//                               '(Waiting for EMI Approval)',
//                               style: TextStyle(color: Colors.orange, fontSize: 14),
//                             ),
//                           if (o['estimated_delivery'] != null)
//                             Text(
//                               'Est. Delivery: ${DateTime.tryParse(o['estimated_delivery']?.toString() ?? '')?.toString().substring(0, 16).replaceFirst('T', ' ') ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Product: $productTitle',
//                             style: const TextStyle(fontSize: 14),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (!_profile?['is_seller'] && o['sellers'] != null)
//                             Text(
//                               'Seller: ${o['sellers']['store_name'] ?? 'Unknown'}',
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                             ),
//                           if (_profile?['is_seller'] == true && o['payment_method'] == 'emi' && emiApp != null) ...[
//                             Text(
//                               'Buyer: ${emiApp['full_name'] ?? 'Unknown'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             Text(
//                               'Buyer Email: ${(o['profiles'] as Map<String, dynamic>?)?['email'] ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             Text(
//                               'EMI Product: ${emiApp['product_name'] ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             Text(
//                               'EMI Price: ₹${(emiApp['product_price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                           if (o['shipping_address'] != null)
//                             Text(
//                               'Shipping: ${o['shipping_address']}',
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         if (_profile?['is_seller'] == true) ...[
//                      if (o['payment_method'] == 'emi' && emiApp != null && (emiApp as Map<String, dynamic>)['status'] != null)
//   DropdownButton<String>(
//     value: _emiStatusUpdates[o['id']] ?? (emiApp as Map<String, dynamic>)['status'],
//     items: const [
//       DropdownMenuItem(value: 'pending', child: Text('Pending')),
//       DropdownMenuItem(value: 'approved', child: Text('Approved')),
//       DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
//     ],
//     onChanged: (v) => _updateEmiStatus(o['id'], (emiApp as Map<String, dynamic>)['id'], v!),
//   ),
//                           if (o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered')
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.blueAccent),
//                               onPressed: () async {
//                                 final next = await _showStatus(o['order_status']);
//                                 if (next != null) _updateOrderStatus(o['id'], next);
//                               },
//                             ),
//                         ] else ...[
//                           if (_cancelId != o['id'] &&
//                               o['order_status'] != 'Cancelled' &&
//                               o['order_status'] != 'Delivered')
//                             IconButton(
//                               icon: const Icon(Icons.cancel_outlined, color: Colors.red),
//                               onPressed: () => setState(() => _cancelId = o['id']),
//                             ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () => context.push('/order-details/${o['id']}'),
//                     child: const Text(
//                       'View Details',
//                       style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//       const SizedBox(height: 12),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//           onPressed: _orderPage == 1
//               ? null
//               : () async {
//                   _orderPage--;
//                   await _load();
//                 },
//           child: const Text('Prev'),
//         ),
//         Text('Page $_orderPage'),
//         TextButton(
//           onPressed: _orders.length < _perPage
//               ? null
//               : () async {
//                   _orderPage++;
//                   await _load();
//                 },
//           child: const Text('Next'),
//         ),
//       ])
//     ]);
//   }

//   Future<String?> _showStatus(String current) async {
//     const statuses = ['pending', 'Order Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
//     String? sel = current;
//     final res = await showDialog<String>(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (_, setD) => AlertDialog(
//           title: const Text('Update status'),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           content: DropdownButton<String>(
//             value: sel,
//             isExpanded: true,
//             items: statuses
//                 .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                 .toList(),
//             onChanged: (v) => setD(() => sel = v),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, sel),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//     return res == current ? null : res;
//   }

//   Widget _cancelDialog() {
//     final reasons = _profile?['is_seller'] == true ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel order #$_cancelId'),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         DropdownButton<String>(
//           value: _cancelReason.isEmpty ? null : _cancelReason,
//           isExpanded: true,
//           hint: const Text('Select a reason'),
//           items: reasons
//               .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//               .toList(),
//           onChanged: (v) => setState(() {
//             _cancelReason = v ?? '';
//             _isCustomReason = v == 'Other (please specify)';
//           }),
//         ),
//         if (_isCustomReason)
//           TextField(
//             onChanged: (v) => setState(() => _cancelReason = v),
//             decoration: const InputDecoration(
//               labelText: 'Custom reason',
//               border: OutlineInputBorder(),
//             ),
//           ),
//       ]),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() {
//             _cancelId = null;
//             _cancelReason = '';
//             _isCustomReason = false;
//           }),
//           child: const Text('Back'),
//         ),
//         ElevatedButton(
//           onPressed: () async => await _cancel(_cancelId!),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: const Text('Confirm'),
//         ),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #$_retryOrderId'),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Text('EMI application was rejected. Select a new payment method.'),
//         DropdownButton<String>(
//           value: _newPaymentMethod,
//           isExpanded: true,
//           items: _paymentMethods
//               .map((m) => DropdownMenuItem(
//                     value: m,
//                     child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                   ))
//               .toList(),
//           onChanged: (v) => setState(() => _newPaymentMethod = v!),
//         ),
//       ]),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _retryPayment,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: const Text('Confirm'),
//         ),
//       ],
//     );
//   }

//   Widget _supportForm() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             'Support',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _supportC,
//             decoration: const InputDecoration(
//               labelText: 'Describe your issue',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 4,
//             onChanged: (v) => _supportMsg = v,
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _submitSupport,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//             ),
//             child: const Text('Submit'),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Contact us at support@justorder.com or call 8825287284 (Sunil Rawani). WhatsApp: +918825287284.',
//             style: const TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//         ]),
//       ),
//     );
//   }

//   /* ─── build ──────────────────────────────────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     if (_err != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 12),
//             Text(
//               'Error: $_err',
//               style: const TextStyle(color: Colors.red, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: _load,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Retry'),
//             ),
//           ]),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Account'),
//         elevation: 4,
//         shadowColor: Colors.grey.withOpacity(0.3),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _profileCard(),
//               const SizedBox(height: 16),
//               _sellerPanel(),
//               const SizedBox(height: 16),
//               _productsGrid(),
//               const SizedBox(height: 16),
//               _ordersList(),
//               const SizedBox(height: 16),
//               _supportForm(),
//               if (_cancelId != null) _cancelDialog(),
//               if (_showRetryPayment) _retryPaymentDialog(),
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

// const _blr = {'lat': 12.9753, 'lon': 77.591};

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});
//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _spb = Supabase.instance.client;

//   /* ─── core models ─────────────────────────────────────────────── */
//   Session? _session;
//   Map<String, dynamic>? _profile;
//   Map<String, dynamic>? _seller;
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _orders = [];
//   List<Map<String, dynamic>> _emiApplications = [];

//   /* ─── ui helpers ──────────────────────────────────────────────── */
//   bool _loading = true;
//   String? _err;
//   String _locMsg = '';
//   String _address = 'Not set';
//   int _prodPage = 1;
//   int _orderPage = 1;
//   final int _perPage = 5;

//   // profile edit
//   bool _edit = false;
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController();

//   // geo
//   Map<String, double>? _sellerLoc;
//   Map<String, double>? _buyerLoc;
//   bool _showManualLoc = false;
//   final _latC = TextEditingController();
//   final _lonC = TextEditingController();

//   // cancellation
//   int? _cancelId;
//   String _cancelReason = '';
//   bool _isCustomReason = false;
//   final _buyerReasons = [
//     'Changed my mind',
//     'Found a better price elsewhere',
//     'Item no longer needed',
//     'Other (please specify)'
//   ];
//   final _sellerReasons = [
//     'Out of stock',
//     'Unable to ship',
//     'Buyer request',
//     'Other (please specify)'
//   ];

//   // emi & retry payment
//   Map<int, String> _emiStatusUpdates = {};
//   bool _showRetryPayment = false;
//   int? _retryOrderId;
//   String _newPaymentMethod = 'credit_card';
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   // support
//   String _supportMsg = '';
//   final _supportC = TextEditingController();

//   /* ─── math & network helpers ──────────────────────────────────── */
//   double _distKm(Map<String, double> a, Map<String, dynamic> b) {
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

//   Future<String> _fetchAddress(double? lat, double? lon) async {
//     if (lat == null || lon == null) return 'Coordinates unavailable';
//     try {
//       final dio = Dio();
//       final response = await dio.get(
//         'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
//         options: Options(headers: {'User-Agent': 'Markeet/1.0'}),
//       );
//       if (response.statusCode == 200 && response.data['display_name'] != null) {
//         return response.data['display_name'];
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Error fetching address: $e';
//     }
//   }

//   /* ─── data load ──────────────────────────────────────────────── */
//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = Provider.of<AppState>(context, listen: false).session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       // Profile
//       _profile = await retry(() => _spb
//           .from('profiles')
//           .select('*')
//           .eq('id', _session!.user.id)
//           .single());
//       _nameC.text = _profile?['full_name'] ?? '';
//       _phoneC.text = _profile?['phone_number'] ?? '';

//       // Set buyer location
//       if (_profile?['latitude'] != null && _profile?['longitude'] != null) {
//         _buyerLoc = {
//           'lat': (_profile!['latitude'] as num).toDouble(),
//           'lon': (_profile!['longitude'] as num).toDouble(),
//         };
//       } else {
//         _buyerLoc = _blr;
//       }

//       // Seller & Products
//       if (_profile?['is_seller'] == true) {
//         _seller = await retry(() => _spb
//             .from('sellers')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single());
//         if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
//           _sellerLoc = {
//             'lat': (_seller!['latitude'] as num).toDouble(),
//             'lon': (_seller!['longitude'] as num).toDouble(),
//           };
//           _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
//           _checkDistance();
//         } else {
//           _sellerLoc = null;
//           _address = 'Location not set';
//         }

//         _products = await retry(() => _spb
//             .from('products')
//             .select('id, title, price, images')
//             .eq('seller_id', _session!.user.id)
//             .eq('is_approved', true)
//             .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));
//       }

//       // Orders
//       final field = _profile?['is_seller'] == true ? 'seller_id' : 'user_id';
//       final base = _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         profiles!orders_user_id_fkey(email),
//         emi_applications(id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at)
//       ''').eq(field, _session!.user.id).order('created_at', ascending: false);

//       _orders = await retry(() => base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));

//       // Fetch emi_applications using user_id
//       if (_profile?['is_seller'] != true) { // Buyers can see their EMI applications
//         _emiApplications = await retry(() => _spb
//             .from('emi_applications')
//             .select('id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at')
//             .eq('user_id', _session!.user.id));
//       } else { // Sellers can see EMI applications related to their orders
//         final orderIds = _orders.map((order) => order['id']).toList();
//         if (orderIds.isNotEmpty) {
//           _emiApplications = await retry(() => _spb
//               .from('emi_applications')
//               .select('id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at')
//               .eq('seller_phone_number', _seller?['phone_number'] ?? ''));
//         }
//       }

//       // Fetch store_name for all orders in one query (optimized)
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
//       _err = e.toString();
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         _err = 'Network error: Unable to connect to the server. Please check your internet connection and try again.';
//       }
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   /* ─── seller-location helpers ────────────────────────────────── */
//   Future<void> _detectLocation() async {
//     setState(() => _locMsg = 'Detecting…');
//     _clearLocMsg();
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         setState(() => _locMsg = 'Location permission denied. Enter manually.');
//         _showManualLoc = true;
//         _clearLocMsg();
//         return;
//       }
//       final p = await Geolocator.getCurrentPosition();
//       await _setSellerLoc(p.latitude, p.longitude);
//     } catch (e) {
//       setState(() => _locMsg = 'Failed: $e');
//       _clearLocMsg();
//       _showManualLoc = true;
//     }
//   }

//   Future<void> _setSellerLoc(double lat, double lon) async {
//     try {
//       await retry(() => _spb.rpc('set_seller_location', params: {
//             'seller_uuid': _session!.user.id,
//             'user_lat': lat,
//             'user_lon': lon,
//             'store_name_input': _seller?['store_name'] ?? 'Store'
//           }));
//       _sellerLoc = {'lat': lat, 'lon': lon};
//       Provider.of<AppState>(context, listen: false).setSellerLocation(lat, lon);
//       _address = await _fetchAddress(lat, lon);
//       _checkDistance();
//       setState(() => _locMsg = 'Location updated: $_address');
//       _clearLocMsg();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating location: $e');
//       _clearLocMsg();
//     }
//   }

//   void _checkDistance() {
//     if (_sellerLoc == null || _buyerLoc == null) {
//       setState(() => _locMsg = 'Unable to calculate distance due to missing location data.');
//       _clearLocMsg();
//       return;
//     }
//     final d = _distKm(_buyerLoc!, _sellerLoc!);
//     setState(() {
//       _locMsg = d <= 40
//           ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
//           : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
//     });
//     _clearLocMsg();
//   }

//   Future<void> _manualLocUpdate() async {
//     final lat = double.tryParse(_latC.text);
//     final lon = double.tryParse(_lonC.text);
//     if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
//       setState(() => _locMsg = 'Invalid latitude or longitude.');
//       _clearLocMsg();
//       return;
//     }
//     await _setSellerLoc(lat, lon);
//     setState(() => _showManualLoc = false);
//     _latC.clear();
//     _lonC.clear();
//   }

//   void _clearLocMsg() {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (mounted) setState(() => _locMsg = '');
//     });
//   }

//   /* ─── order ops ──────────────────────────────────────────────── */
//   Future<void> _cancel(int id) async {
//     if (_cancelReason.isEmpty) {
//       setState(() => _locMsg = 'Please select a cancellation reason.');
//       _clearLocMsg();
//       return;
//     }
//     try {
//       // Fetch order items to update related products
//       final orderData = await retry(() => _spb
//           .from('orders')
//           .select('order_items(*, products(id))')
//           .eq('id', id)
//           .single());

//       // Update order status
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', id));

//       // Update related products
//       final orderItems = orderData['order_items'] as List<dynamic>? ?? [];
//       for (var item in orderItems) {
//         if (item != null && item['products'] != null && item['products']['id'] != null) {
//           await retry(() => _spb
//               .from('products')
//               .update({'status': 'cancelled', 'cancel_reason': _cancelReason})
//               .eq('id', item['products']['id']));
//         }
//       }

//       setState(() {
//         _cancelId = null;
//         _cancelReason = '';
//         _isCustomReason = false;
//         _locMsg = 'Order cancelled successfully.';
//       });
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error cancelling order: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _updateOrderStatus(int id, String status) async {
//     try {
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
//       setState(() => _locMsg = 'Order #$id status updated to $status.');
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating status: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
//     try {
//       const validEmiTransitions = {
//         'pending': ['approved', 'rejected'],
//         'approved': [],
//         'rejected': [],
//       };
//       final emiApp = _emiApplications.firstWhere((app) => app['id'] == emiAppId);
//       final currentStatus = emiApp['status'];
//       if (!validEmiTransitions[currentStatus]!.contains(newStatus)) {
//         setState(() => _locMsg = 'Invalid EMI status transition from $currentStatus to $newStatus.');
//         _clearLocMsg();
//         return;
//       }

//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
//       if (newStatus == 'approved') {
//         setState(() => _locMsg = 'EMI approved successfully!');
//       } else if (newStatus == 'rejected') {
//         setState(() {
//           _locMsg = 'EMI rejected.';
//           _showRetryPayment = true;
//           _retryOrderId = null; // No direct order link
//         });
//       }
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating EMI status: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _retryPayment() async {
//     if (_retryOrderId == null) {
//       setState(() => _locMsg = 'Error: No order selected for retry. Please retry manually.');
//       _clearLocMsg();
//       return;
//     }
//     try {
//       // Recalculate estimated delivery for non-EMI orders after retry based on current time
//       final now = DateTime.now();
//       final distance = _buyerLoc != null && _sellerLoc != null ? _distKm(_buyerLoc!, _sellerLoc!) : 0.0;
//       final estimatedDelivery = distance <= 40
//           ? now.add(const Duration(hours: 15))
//           : now.add(const Duration(hours: 36));

//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//         'estimated_delivery': estimatedDelivery.toIso8601String(),
//       }).eq('id', _retryOrderId!));
//       setState(() {
//         _showRetryPayment = false;
//         _retryOrderId = null;
//         _newPaymentMethod = 'credit_card';
//         _locMsg = 'Payment method updated successfully.';
//       });
//       _clearLocMsg();
//       await _load();
//     } catch (e) {
//       setState(() => _locMsg = 'Error updating payment: $e');
//       _clearLocMsg();
//     }
//   }

//   Future<void> _submitSupport() async {
//     if (_supportMsg.trim().isEmpty) {
//       setState(() => _locMsg = 'Please enter a support message.');
//       _clearLocMsg();
//       return;
//     }
//     try {
//       await retry(() => _spb.from('support_requests').insert({
//         'user_id': _session!.user.id,
//         'message': _supportMsg,
//         'created_at': DateTime.now().toIso8601String(),
//       }));
//       setState(() {
//         _supportMsg = '';
//         _supportC.clear();
//         _locMsg = 'Support request submitted successfully.';
//       });
//       _clearLocMsg();
//     } catch (e) {
//       setState(() => _locMsg = 'Error submitting support request: $e');
//       _clearLocMsg();
//     }
//   }

//   /* ─── lifecycle ──────────────────────────────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _buyerLoc = Provider.of<AppState>(context, listen: false).buyerLocation ?? _blr;
//     _load();
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _phoneC.dispose();
//     _latC.dispose();
//     _lonC.dispose();
//     _supportC.dispose();
//     super.dispose();
//   }

//   /* ─── UI helpers ─────────────────────────────────────────────── */
//   Widget _profileCard() {
//     if (_profile == null) return const SizedBox();
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             _session!.user.email ?? 'No email',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           if (!_edit) ...[
//             Text('Name: ${_profile!['full_name'] ?? '-'}'),
//             Text('Phone: ${_profile!['phone_number'] ?? '-'}'),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: () => setState(() => _edit = true),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Edit'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () async {
//                   await _spb.auth.signOut();
//                   final error = await Provider.of<AppState>(context, listen: false).signOut();
//                   if (error != null && mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(error), backgroundColor: Colors.red),
//                     );
//                   } else {
//                     context.go('/');
//                   }
//                 },
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.red),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Logout', style: TextStyle(color: Colors.red)),
//               ),
//             ])
//           ] else ...[
//             TextField(
//               controller: _nameC,
//               decoration: const InputDecoration(
//                 labelText: 'Full name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _phoneC,
//               decoration: const InputDecoration(
//                 labelText: 'Phone (10 digits)',
//                 border: OutlineInputBorder(),
//                 hintText: 'e.g., 9123456789',
//               ),
//               keyboardType: TextInputType.phone,
//               maxLength: 10,
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: () async {
//                   final phone = _phoneC.text.trim();
//                   if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Please enter a valid 10-digit phone number.'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                     return;
//                   }
//                   await retry(() => _spb.from('profiles').update({
//                     'full_name': _nameC.text.trim(),
//                     'phone_number': phone,
//                   }).eq('id', _session!.user.id));
//                   setState(() => _edit = false);
//                   await _load();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Save'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => setState(() => _edit = false),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.grey),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   Widget _sellerPanel() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             'Store Location',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text('Address: $_address'),
//           const SizedBox(height: 4),
//           Text(
//             _locMsg,
//             style: TextStyle(
//               color: _locMsg.startsWith('Warning') ? Colors.red : Colors.green,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(children: [
//             ElevatedButton(
//               onPressed: _detectLocation,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Detect Location'),
//             ),
//             const SizedBox(width: 12),
//             OutlinedButton(
//               onPressed: () => setState(() => _showManualLoc = true),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.blueAccent),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Enter Manually'),
//             ),
//           ]),
//           if (_showManualLoc) ...[
//             const SizedBox(height: 12),
//             TextField(
//               controller: _latC,
//               decoration: const InputDecoration(
//                 labelText: 'Latitude (-90 to 90)',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _lonC,
//               decoration: const InputDecoration(
//                 labelText: 'Longitude (-180 to 180)',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             ),
//             const SizedBox(height: 12),
//             Row(children: [
//               ElevatedButton(
//                 onPressed: _manualLocUpdate,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Submit'),
//               ),
//               const SizedBox(width: 12),
//               OutlinedButton(
//                 onPressed: () => setState(() => _showManualLoc = false),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.grey),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ]),
//           ],
//           const SizedBox(height: 12),
//           TextButton(
//             onPressed: () => context.push('/seller'),
//             child: const Text(
//               'Go to Seller Dashboard',
//               style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }

//   Widget _productsGrid() {
//     if (_profile?['is_seller'] != true) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         'My Products',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       if (_products.isEmpty)
//         const Text(
//           'No products',
//           style: TextStyle(color: Colors.grey),
//         ),
//       if (_products.isNotEmpty)
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.72,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           children: _products.map((p) {
//             final imageUrl = (p['images'] as List?)?.isNotEmpty == true
//                 ? p['images'][0]
//                 : 'https://dummyimage.com/150';
//             return Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Column(children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       errorBuilder: (context, error, stackTrace) => const Icon(
//                         Icons.image_not_supported,
//                         size: 50,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         p['title'] ?? 'Unnamed Product',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '₹${(p['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                         style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       Center(
//                         child: TextButton(
//                           onPressed: () => context.push('/product/${p['id']}'),
//                           child: const Text(
//                             'View',
//                             style: TextStyle(color: Colors.blueAccent),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ]),
//             );
//           }).toList(),
//         ),
//       const SizedBox(height: 12),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//           onPressed: _prodPage == 1
//               ? null
//               : () async {
//                   _prodPage--;
//                   await _load();
//                 },
//           child: const Text('Prev'),
//         ),
//         Text('Page $_prodPage'),
//         TextButton(
//           onPressed: _products.length < _perPage
//               ? null
//               : () async {
//                   _prodPage++;
//                   await _load();
//                 },
//           child: const Text('Next'),
//         ),
//       ])
//     ]);
//   }

//   Widget _ordersList() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         _profile?['is_seller'] == true ? 'Orders Received' : 'My Orders',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       if (_orders.isEmpty)
//         Text(
//           _profile?['is_seller'] == true ? 'No orders received' : 'No orders',
//           style: const TextStyle(color: Colors.grey),
//         ),
//       ..._orders.map((o) {
//         final orderItems = o['order_items'] as List?;
//         final firstItem = orderItems != null && orderItems.isNotEmpty ? orderItems[0] : null;
//         final productTitle = firstItem != null
//             ? (firstItem['products'] != null ? firstItem['products']['title'] ?? 'Unknown Product' : 'Unknown Product')
//             : 'N/A';
//         final imageUrl = firstItem != null && firstItem['products'] != null
//             ? (firstItem['products']['images'] as List?)?.isNotEmpty == true
//                 ? firstItem['products']['images'][0]
//                 : 'https://dummyimage.com/150'
//             : 'https://dummyimage.com/150';

//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           margin: const EdgeInsets.only(bottom: 12),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         imageUrl,
//                         width: 72,
//                         height: 72,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) => const Icon(
//                           Icons.image_not_supported,
//                           size: 72,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Order #${o['id']}',
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Total: ₹${(o['total'] as num?)?.toStringAsFixed(2) ?? '0.00'} • ${o['order_status']}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           if (o['order_status'] == 'Cancelled')
//                             Text(
//                               'Reason: ${o['cancellation_reason'] ?? 'N/A'}',
//                               style: const TextStyle(color: Colors.red, fontSize: 14),
//                             ),
//                           if (o['payment_method'] == 'emi' && o['order_status'] == 'pending')
//                             const Text(
//                               '(Waiting for EMI Approval)',
//                               style: TextStyle(color: Colors.orange, fontSize: 14),
//                             ),
//                           if (o['estimated_delivery'] != null)
//                             Text(
//                               'Est. Delivery: ${DateTime.parse(o['estimated_delivery']).toLocal().toString().substring(0, 16)}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Product: $productTitle',
//                             style: const TextStyle(fontSize: 14),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (!_profile?['is_seller'] && o['sellers'] != null)
//                             Text(
//                               'Seller: ${o['sellers']['store_name'] ?? 'Unknown'}',
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                             ),
//                           if (_profile?['is_seller'] == true)
//                             Text(
//                               'Buyer Email: ${(o['profiles'] as Map<String, dynamic>?)?['email'] ?? 'N/A'}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           if (o['shipping_address'] != null)
//                             Text(
//                               'Shipping: ${o['shipping_address']}',
//                               style: const TextStyle(fontSize: 14, color: Colors.grey),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         if (_profile?['is_seller'] == true) ...[
//                           if (o['order_status'] != 'Cancelled' && o['order_status'] != 'Delivered')
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.blueAccent),
//                               onPressed: () async {
//                                 final next = await _showStatus(o['order_status']);
//                                 if (next != null) _updateOrderStatus(o['id'], next);
//                               },
//                             ),
//                         ] else ...[
//                           if (_cancelId != o['id'] &&
//                               o['order_status'] != 'Cancelled' &&
//                               o['order_status'] != 'Delivered')
//                             IconButton(
//                               icon: const Icon(Icons.cancel_outlined, color: Colors.red),
//                               onPressed: () => context.push('/orders/cancel/${o['id']}'),
//                             ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () => context.push('/order-details/${o['id']}'),
//                     child: const Text(
//                       'View Details',
//                       style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//       const SizedBox(height: 12),
//       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         TextButton(
//           onPressed: _orderPage == 1
//               ? null
//               : () async {
//                   _orderPage--;
//                   await _load();
//                 },
//           child: const Text('Prev'),
//         ),
//         Text('Page $_orderPage'),
//         TextButton(
//           onPressed: _orders.length < _perPage
//               ? null
//               : () async {
//                   _orderPage++;
//                   await _load();
//                 },
//           child: const Text('Next'),
//         ),
//       ])
//     ]);
//   }

//   Widget _emiApplicationsList() {
//     if (_emiApplications.isEmpty) return const SizedBox();
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(
//         _profile?['is_seller'] == true ? 'EMI Applications Received' : 'My EMI Applications',
//         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//       const SizedBox(height: 12),
//       ..._emiApplications.map((emiApp) {
//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           margin: const EdgeInsets.only(bottom: 12),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'EMI Application #${emiApp['id']}',
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Product: ${emiApp['product_name'] ?? 'N/A'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           Text(
//                             'Price: ₹${(emiApp['product_price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           Text(
//                             'Buyer: ${emiApp['full_name'] ?? 'Unknown'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           Text(
//                             'Buyer Phone: ${emiApp['mobile_number'] ?? 'N/A'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           Text(
//                             'Seller: ${emiApp['seller_name'] ?? 'Unknown'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           Text(
//                             'Seller Phone: ${emiApp['seller_phone_number'] ?? 'Not provided'}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                           Text(
//                             'Status: ${emiApp['status'] ?? 'N/A'}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: emiApp['status'] == 'approved'
//                                   ? Colors.green
//                                   : emiApp['status'] == 'rejected'
//                                       ? Colors.red
//                                       : Colors.orange,
//                             ),
//                           ),
//                           Text(
//                             'Applied: ${DateTime.parse(emiApp['created_at']).toLocal().toString().substring(0, 16)}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (_profile?['is_seller'] == true) ...[
//                       DropdownButton<String>(
//                         value: _emiStatusUpdates[emiApp['id']] ?? emiApp['status'],
//                         items: const [
//                           DropdownMenuItem(value: 'pending', child: Text('Pending')),
//                           DropdownMenuItem(value: 'approved', child: Text('Approved')),
//                           DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
//                         ],
//                         onChanged: (v) => _updateEmiStatus(emiApp['id'], v!),
//                       ),
//                     ],
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//     ]);
//   }

//   Future<String?> _showStatus(String current) async {
//     const statuses = ['pending', 'Order Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
//     String? sel = current;
//     final res = await showDialog<String>(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (_, setD) => AlertDialog(
//           title: const Text('Update status'),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           content: DropdownButton<String>(
//             value: sel,
//             isExpanded: true,
//             items: statuses
//                 .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                 .toList(),
//             onChanged: (v) => setD(() => sel = v),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, sel),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//     return res == current ? null : res;
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: const Text('Retry Payment'),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       content: Column(mainAxisSize: MainAxisSize.min, children: [
//         const Text('EMI application was rejected. Select a new payment method.'),
//         DropdownButton<String>(
//           value: _newPaymentMethod,
//           isExpanded: true,
//           items: _paymentMethods
//               .map((m) => DropdownMenuItem(
//                     value: m,
//                     child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                   ))
//               .toList(),
//           onChanged: (v) => setState(() => _newPaymentMethod = v!),
//         ),
//       ]),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _retryPayment,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: const Text('Confirm'),
//         ),
//       ],
//     );
//   }

//   Widget _supportForm() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(
//             'Support',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _supportC,
//             decoration: const InputDecoration(
//               labelText: 'Describe your issue',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 4,
//             onChanged: (v) => _supportMsg = v,
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _submitSupport,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//             ),
//             child: const Text('Submit'),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Contact us at support@justorder.com or call 8825287284 (Sunil Rawani). WhatsApp: +918825287284.',
//             style: const TextStyle(color: Colors.grey, fontSize: 12),
//           ),
//         ]),
//       ),
//     );
//   }

//   /* ─── build ──────────────────────────────────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     if (_err != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 48),
//             const SizedBox(height: 12),
//             Text(
//               'Error: $_err',
//               style: const TextStyle(color: Colors.red, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: _load,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: const Text('Retry'),
//             ),
//           ]),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Account'),
//         elevation: 4,
//         shadowColor: Colors.grey.withOpacity(0.3),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _profileCard(),
//               const SizedBox(height: 16),
//               _sellerPanel(),
//               const SizedBox(height: 16),
//               _productsGrid(),
//               const SizedBox(height: 16),
//               _ordersList(),
//               const SizedBox(height: 16),
//               _emiApplicationsList(),
//               const SizedBox(height: 16),
//               _supportForm(),
//               if (_showRetryPayment) _retryPaymentDialog(),
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

import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

// Define the premium color palette for consistency
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

const _blr = {'lat': 12.9753, 'lon': 77.591};

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _spb = Supabase.instance.client;

  /* ─── core models ─────────────────────────────────────────────── */
  Session? _session;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _seller;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _emiApplications = [];

  /* ─── ui helpers ──────────────────────────────────────────────── */
  bool _loading = true;
  String? _err;
  String _locMsg = '';
  String _address = 'Not set';
  int _prodPage = 1;
  int _orderPage = 1;
  final int _perPage = 5;

  // profile edit
  bool _edit = false;
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();

  // geo
  Map<String, double>? _sellerLoc;
  Map<String, double>? _buyerLoc;
  bool _showManualLoc = false;
  final _latC = TextEditingController();
  final _lonC = TextEditingController();

  // emi & retry payment
  Map<int, String> _emiStatusUpdates = {};
  bool _showRetryPayment = false;
  int? _retryOrderId;
  String _newPaymentMethod = 'credit_card';
  final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

  // support
  String _supportMsg = '';
  final _supportC = TextEditingController();

  /* ─── math & network helpers ──────────────────────────────────── */
  double _distKm(Map<String, double> a, Map<String, dynamic> b) {
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

  Future<String> _fetchAddress(double? lat, double? lon) async {
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
      return 'Error fetching address: $e';
    }
  }

  /* ─── data load ──────────────────────────────────────────────── */
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _session = Provider.of<AppState>(context, listen: false).session;
      if (_session == null) {
        context.go('/auth');
        return;
      }

      // Profile
      _profile = await retry(() => _spb
          .from('profiles')
          .select('*')
          .eq('id', _session!.user.id)
          .single());
      _nameC.text = _profile?['full_name'] ?? '';
      _phoneC.text = _profile?['phone_number'] ?? '';

      // Set buyer location
      if (_profile?['latitude'] != null && _profile?['longitude'] != null) {
        _buyerLoc = {
          'lat': (_profile!['latitude'] as num).toDouble(),
          'lon': (_profile!['longitude'] as num).toDouble(),
        };
      } else {
        _buyerLoc = _blr;
      }

      // Seller & Products
      if (_profile?['is_seller'] == true) {
        _seller = await retry(() => _spb
            .from('sellers')
            .select('*')
            .eq('id', _session!.user.id)
            .single());
        if (_seller?['latitude'] != null && _seller?['longitude'] != null) {
          _sellerLoc = {
            'lat': (_seller!['latitude'] as num).toDouble(),
            'lon': (_seller!['longitude'] as num).toDouble(),
          };
          _address = await _fetchAddress(_seller!['latitude'], _seller!['longitude']);
          _checkDistance();
        } else {
          _sellerLoc = null;
          _address = 'Location not set';
        }

        _products = await retry(() => _spb
            .from('products')
            .select('id, title, price, images')
            .eq('seller_id', _session!.user.id)
            .eq('is_approved', true)
            .range((_prodPage - 1) * _perPage, _prodPage * _perPage - 1));
      }

      // Orders (only for sellers now)
      if (_profile?['is_seller'] == true) {
        final base = _spb.from('orders').select('''
          id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id, shipping_address,
          order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
          profiles!orders_user_id_fkey(email),
          emi_applications(id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at)
        ''').eq('seller_id', _session!.user.id).order('created_at', ascending: false);

        _orders = await retry(() => base.range((_orderPage - 1) * _perPage, _orderPage * _perPage - 1));
      }

      // Fetch emi_applications using user_id
      if (_profile?['is_seller'] != true) { // Buyers can see their EMI applications
        _emiApplications = await retry(() => _spb
            .from('emi_applications')
            .select('id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at')
            .eq('user_id', _session!.user.id));
      } else { // Sellers can see EMI applications related to their orders
        final orderIds = _orders.map((order) => order['id']).toList();
        if (orderIds.isNotEmpty) {
          _emiApplications = await retry(() => _spb
              .from('emi_applications')
              .select('id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at')
              .eq('seller_phone_number', _seller?['phone_number'] ?? ''));
        }
      }

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

  /* ─── seller-location helpers ────────────────────────────────── */
  Future<void> _detectLocation() async {
    setState(() => _locMsg = 'Detecting…');
    _clearLocMsg();
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _locMsg = 'Location permission denied. Enter manually.');
        _showManualLoc = true;
        _clearLocMsg();
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      await _setSellerLoc(p.latitude, p.longitude);
    } catch (e) {
      setState(() => _locMsg = 'Failed: $e');
      _clearLocMsg();
      _showManualLoc = true;
    }
  }

  Future<void> _setSellerLoc(double lat, double lon) async {
    try {
      await retry(() => _spb.rpc('set_seller_location', params: {
            'seller_uuid': _session!.user.id,
            'user_lat': lat,
            'user_lon': lon,
            'store_name_input': _seller?['store_name'] ?? 'Store'
          }));
      _sellerLoc = {'lat': lat, 'lon': lon};
      Provider.of<AppState>(context, listen: false).setSellerLocation(lat, lon);
      _address = await _fetchAddress(lat, lon);
      _checkDistance();
      setState(() => _locMsg = 'Location updated: $_address');
      _clearLocMsg();
    } catch (e) {
      setState(() => _locMsg = 'Error updating location: $e');
      _clearLocMsg();
    }
  }

  void _checkDistance() {
    if (_sellerLoc == null || _buyerLoc == null) {
      setState(() => _locMsg = 'Unable to calculate distance due to missing location data.');
      _clearLocMsg();
      return;
    }
    final d = _distKm(_buyerLoc!, _sellerLoc!);
    setState(() {
      _locMsg = d <= 40
          ? 'Store is ${d.toStringAsFixed(2)} km away ✅'
          : 'Warning: store ${d.toStringAsFixed(2)} km away (>40 km)';
    });
    _clearLocMsg();
  }

  Future<void> _manualLocUpdate() async {
    final lat = double.tryParse(_latC.text);
    final lon = double.tryParse(_lonC.text);
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      setState(() => _locMsg = 'Invalid latitude or longitude.');
      _clearLocMsg();
      return;
    }
    await _setSellerLoc(lat, lon);
    setState(() => _showManualLoc = false);
    _latC.clear();
    _lonC.clear();
  }

  void _clearLocMsg() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _locMsg = '');
    });
  }

  /* ─── order ops ──────────────────────────────────────────────── */
  Future<void> _updateOrderStatus(int id, String status) async {
    try {
      await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', id));
      setState(() => _locMsg = 'Order #$id status updated to $status.');
      _clearLocMsg();
      await _load();
    } catch (e) {
      setState(() => _locMsg = 'Error updating status: $e');
      _clearLocMsg();
    }
  }

  Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
    try {
      const validEmiTransitions = {
        'pending': ['approved', 'rejected'],
        'approved': [],
        'rejected': [],
      };
      final emiApp = _emiApplications.firstWhere((app) => app['id'] == emiAppId);
      final currentStatus = emiApp['status'];
      if (!validEmiTransitions[currentStatus]!.contains(newStatus)) {
        setState(() => _locMsg = 'Invalid EMI status transition from $currentStatus to $newStatus.');
        _clearLocMsg();
        return;
      }

      await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
      if (newStatus == 'approved') {
        setState(() => _locMsg = 'EMI approved successfully!');
      } else if (newStatus == 'rejected') {
        setState(() {
          _locMsg = 'EMI rejected.';
          _showRetryPayment = true;
          _retryOrderId = null; // No direct order link
        });
      }
      _clearLocMsg();
      await _load();
    } catch (e) {
      setState(() => _locMsg = 'Error updating EMI status: $e');
      _clearLocMsg();
    }
  }

  Future<void> _retryPayment() async {
    if (_retryOrderId == null) {
      setState(() => _locMsg = 'Error: No order selected for retry. Please retry manually.');
      _clearLocMsg();
      return;
    }
    try {
      // Recalculate estimated delivery for non-EMI orders after retry based on current time
      final now = DateTime.now();
      final distance = _buyerLoc != null && _sellerLoc != null ? _distKm(_buyerLoc!, _sellerLoc!) : 0.0;
      final estimatedDelivery = distance <= 40
          ? now.add(const Duration(hours: 15))
          : now.add(const Duration(hours: 36));

      await retry(() => _spb.from('orders').update({
        'payment_method': _newPaymentMethod,
        'order_status': 'Order Placed',
        'estimated_delivery': estimatedDelivery.toIso8601String(),
      }).eq('id', _retryOrderId!));
      setState(() {
        _showRetryPayment = false;
        _retryOrderId = null;
        _newPaymentMethod = 'credit_card';
        _locMsg = 'Payment method updated successfully.';
      });
      _clearLocMsg();
      await _load();
    } catch (e) {
      setState(() => _locMsg = 'Error updating payment: $e');
      _clearLocMsg();
    }
  }

  Future<void> _submitSupport() async {
    if (_supportMsg.trim().isEmpty) {
      setState(() => _locMsg = 'Please enter a support message.');
      _clearLocMsg();
      return;
    }
    try {
      await retry(() => _spb.from('support_requests').insert({
        'user_id': _session!.user.id,
        'message': _supportMsg,
        'created_at': DateTime.now().toIso8601String(),
      }));
      setState(() {
        _supportMsg = '';
        _supportC.clear();
        _locMsg = 'Support request submitted successfully.';
      });
      _clearLocMsg();
    } catch (e) {
      setState(() => _locMsg = 'Error submitting support request: $e');
      _clearLocMsg();
    }
  }

  /* ─── lifecycle ──────────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _buyerLoc = Provider.of<AppState>(context, listen: false).buyerLocation ?? _blr;
    _load();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _latC.dispose();
    _lonC.dispose();
    _supportC.dispose();
    super.dispose();
  }

  /* ─── UI helpers ─────────────────────────────────────────────── */
  Widget _profileCard() {
    if (_profile == null) return const SizedBox();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: premiumCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _session!.user.email ?? 'No email',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: premiumTextColor,
                ),
          ),
          const SizedBox(height: 8),
          if (!_edit) ...[
            Text(
              'Name: ${_profile!['full_name'] ?? '-'}',
              style: const TextStyle(color: premiumTextColor),
            ),
            Text(
              'Phone: ${_profile!['phone_number'] ?? '-'}',
              style: const TextStyle(color: premiumTextColor),
            ),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                onPressed: () => setState(() => _edit = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  await _spb.auth.signOut();
                  final error = await Provider.of<AppState>(context, listen: false).signOut();
                  if (error != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.red),
                    );
                  } else {
                    context.go('/');
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ])
          ] else ...[
            TextField(
              controller: _nameC,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneC,
              decoration: const InputDecoration(
                labelText: 'Phone (10 digits)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 9123456789',
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                onPressed: () async {
                  final phone = _phoneC.text.trim();
                  if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid 10-digit phone number.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  await retry(() => _spb.from('profiles').update({
                    'full_name': _nameC.text.trim(),
                    'phone_number': phone,
                  }).eq('id', _session!.user.id));
                  setState(() => _edit = false);
                  await _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() => _edit = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: premiumSecondaryTextColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(color: premiumSecondaryTextColor)),
              ),
            ])
          ]
        ]),
      ),
    );
  }

  Widget _sellerPanel() {
    if (_profile?['is_seller'] != true) return const SizedBox();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: premiumCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Store Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: premiumTextColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Address: $_address',
            style: const TextStyle(color: premiumTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            _locMsg,
            style: TextStyle(
              color: _locMsg.startsWith('Warning') ? Colors.red : Colors.green,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(
              onPressed: _detectLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Detect Location'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => setState(() => _showManualLoc = true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: premiumPrimaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Enter Manually', style: TextStyle(color: premiumPrimaryColor)),
            ),
          ]),
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
            Row(children: [
              ElevatedButton(
                onPressed: _manualLocUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() => _showManualLoc = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: premiumSecondaryTextColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(color: premiumSecondaryTextColor)),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/seller'),
            child: const Text(
              'Go to Seller Dashboard',
              style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _productsGrid() {
    if (_profile?['is_seller'] != true) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'My Products',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: premiumTextColor,
            ),
      ),
      const SizedBox(height: 12),
      if (_products.isEmpty)
        const Text(
          'No products',
          style: TextStyle(color: premiumSecondaryTextColor),
        ),
      if (_products.isNotEmpty)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: _products.map((p) {
            final imageUrl = (p['images'] as List?)?.isNotEmpty == true
                ? p['images'][0]
                : 'https://dummyimage.com/150';
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: premiumCardColor,
              child: Column(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: premiumSecondaryTextColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['title'] ?? 'Unnamed Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: premiumTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${(p['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/product/${p['id']}'),
                          child: const Text(
                            'View',
                            style: TextStyle(color: premiumPrimaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(
          onPressed: _prodPage == 1
              ? null
              : () async {
                  _prodPage--;
                  await _load();
                },
          child: const Text('Prev', style: TextStyle(color: premiumPrimaryColor)),
        ),
        Text('Page $_prodPage', style: const TextStyle(color: premiumTextColor)),
        TextButton(
          onPressed: _products.length < _perPage
              ? null
              : () async {
                  _prodPage++;
                  await _load();
                },
          child: const Text('Next', style: TextStyle(color: premiumPrimaryColor)),
        ),
      ])
    ]);
  }

  Widget _ordersList() {
    final isSeller = _profile?['is_seller'] == true;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isSeller ? 'Orders Received' : 'My Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: premiumTextColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!isSeller)
            TextButton(
              onPressed: () => context.go('/orders'),
              child: const Text(
                'See All',
                style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (!isSeller)
        const SizedBox(), // Remove buyer orders; they are now on OrdersPage
      if (isSeller) ...[
        if (_orders.isEmpty)
          const Text(
            'No orders received',
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
                            Text(
                              'Buyer Email: ${(o['profiles'] as Map<String, dynamic>?)?['email'] ?? 'N/A'}',
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
                              icon: const Icon(Icons.edit, color: premiumPrimaryColor),
                              onPressed: () async {
                                final next = await _showStatus(o['order_status']);
                                if (next != null) _updateOrderStatus(o['id'], next);
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
      ],
    ]);
  }

  Widget _emiApplicationsList() {
    if (_emiApplications.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        _profile?['is_seller'] == true ? 'EMI Applications Received' : 'My EMI Applications',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: premiumTextColor,
            ),
      ),
      const SizedBox(height: 12),
      ..._emiApplications.map((emiApp) {
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMI Application #${emiApp['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: premiumTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Product: ${emiApp['product_name'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          Text(
                            'Price: ₹${(emiApp['product_price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          Text(
                            'Buyer: ${emiApp['full_name'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          Text(
                            'Buyer Phone: ${emiApp['mobile_number'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          Text(
                            'Seller: ${emiApp['seller_name'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          Text(
                            'Seller Phone: ${emiApp['seller_phone_number'] ?? 'Not provided'}',
                            style: const TextStyle(fontSize: 14, color: premiumTextColor),
                          ),
                          Text(
                            'Status: ${emiApp['status'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: emiApp['status'] == 'approved'
                                  ? Colors.green
                                  : emiApp['status'] == 'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),
                          Text(
                            'Applied: ${DateTime.parse(emiApp['created_at']).toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(fontSize: 14, color: premiumSecondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                    if (_profile?['is_seller'] == true) ...[
                      DropdownButton<String>(
                        value: _emiStatusUpdates[emiApp['id']] ?? emiApp['status'],
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'approved', child: Text('Approved')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (v) => _updateEmiStatus(emiApp['id'], v!),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    ]);
  }

  Future<String?> _showStatus(String current) async {
    const statuses = ['pending', 'Order Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];
    String? sel = current;
    final res = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          title: const Text('Update status'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: DropdownButton<String>(
            value: sel,
            isExpanded: true,
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setD(() => sel = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: premiumSecondaryTextColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, sel),
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    return res == current ? null : res;
  }

  Widget _retryPaymentDialog() {
    return AlertDialog(
      title: const Text('Retry Payment'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('EMI application was rejected. Select a new payment method.'),
        DropdownButton<String>(
          value: _newPaymentMethod,
          isExpanded: true,
          items: _paymentMethods
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m.replaceAll('_', ' ').toUpperCase()),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _newPaymentMethod = v!),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showRetryPayment = false),
          child: const Text('Cancel', style: TextStyle(color: premiumSecondaryTextColor)),
        ),
        ElevatedButton(
          onPressed: _retryPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _supportForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: premiumCardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Support',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: premiumTextColor,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supportC,
            decoration: const InputDecoration(
              labelText: 'Describe your issue',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (v) => _supportMsg = v,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submitSupport,
            style: ElevatedButton.styleFrom(
              backgroundColor: premiumPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: const Text('Submit'),
          ),
          const SizedBox(height: 12),
          Text(
            'Contact us at support@justorder.com or call 8825287284 (Sunil Rawani). WhatsApp: +918825287284.',
            style: const TextStyle(color: premiumSecondaryTextColor, fontSize: 12),
          ),
        ]),
      ),
    );
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
        title: const Text('Account'),
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
              _profileCard(),
              const SizedBox(height: 16),
              _sellerPanel(),
              const SizedBox(height: 16),
              _productsGrid(),
              const SizedBox(height: 16),
              _ordersList(),
              const SizedBox(height: 16),
              _emiApplicationsList(),
              const SizedBox(height: 16),
              _supportForm(),
              if (_showRetryPayment) _retryPaymentDialog(),
            ],
          ),
        ),
      ),
    );
  }
}