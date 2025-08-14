// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// class OrderDetailsPage extends StatefulWidget {
//   final String id;
//   const OrderDetailsPage({super.key, required this.id});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   final _spb = Supabase.instance.client;
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _order;
//   Session? _session;
//   bool _isSeller = false;
//   String? _cancelReason;
//   bool _isCustomReason = false;
//   bool _showRetryPayment = false;
//   String _newPaymentMethod = 'credit_card';
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
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       final profile = await retry(() => _spb
//           .from('profiles')
//           .select('is_seller')
//           .eq('id', _session!.user.id)
//           .single());
//       _isSeller = profile['is_seller'] == true;

//       _order = await retry(() => _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(status, product_name, product_price, full_name, mobile_number, uuid),
//         profiles!orders_user_id_fkey(email),
//         sellers(store_name)
//       ''').eq('id', widget.id).single());

//       if (_order == null) {
//         setState(() => _error = 'Order not found.');
//       }
//     } catch (e) {
//       setState(() => _error = 'Error: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _cancel() async {
//     if (_cancelReason == null || _cancelReason!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a cancellation reason.')),
//       );
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order cancelled successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error cancelling order: $e');
//     }
//   }

//   Future<void> _updateOrderStatus(String status) async {
//     try {
//       const validTransitions = {
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _order!['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid status transition from $current to $status.')),
//         );
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Order status updated to $status.')),
//       );
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating status: $e');
//     }
//   }

//   Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('uuid', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI approved successfully!')),
//         );
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() => _showRetryPayment = true);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI rejected. Prompting buyer to retry payment.')),
//         );
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', widget.id));
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating EMI status: $e');
//     }
//   }

//   Future<void> _retryPayment() async {
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', widget.id));
//       setState(() {
//         _showRetryPayment = false;
//         _newPaymentMethod = 'credit_card';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Payment method updated successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating payment: $e');
//     }
//   }

//   Widget _cancelDialog() {
//     final reasons = _isSeller ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DropdownButton<String>(
//             value: _cancelReason,
//             isExpanded: true,
//             hint: const Text('Select reason'),
//             items: reasons
//                 .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//                 .toList(),
//             onChanged: (v) => setState(() {
//               _cancelReason = v;
//               _isCustomReason = v == 'Other (please specify)';
//             }),
//           ),
//           if (_isCustomReason)
//             TextField(
//               onChanged: (v) => _cancelReason = v,
//               decoration: const InputDecoration(labelText: 'Custom reason'),
//             ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() {
//             _cancelReason = null;
//             _isCustomReason = false;
//           }),
//           child: const Text('Back'),
//         ),
//         TextButton(onPressed: _cancel, child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('EMI application was rejected. Select a new payment method.'),
//           DropdownButton<String>(
//             value: _newPaymentMethod,
//             isExpanded: true,
//             items: _paymentMethods
//                 .map((m) => DropdownMenuItem(
//                       value: m,
//                       child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                     ))
//                 .toList(),
//             onChanged: (v) => setState(() => _newPaymentMethod = v!),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         TextButton(onPressed: _retryPayment, child: const Text('Confirm')),
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

//     final items = _order!['order_items'] as List<dynamic>;
//     final emiApp = _order!['emi_applications'];

//     return Scaffold(
//       appBar: AppBar(title: Text('Order #${widget.id}')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: ListTile(
//                 title: Text('Order #${_order!['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Total: ₹${_order!['total'].toStringAsFixed(2)}'),
//                     Text('Status: ${_order!['order_status']}'),
//                     if (_order!['order_status'] == 'Cancelled')
//                       Text('Reason: ${_order!['cancellation_reason']}'),
//                     Text('Payment: ${_order!['payment_method'].replaceAll('_', ' ').toUpperCase()}'),
//                     if (_order!['estimated_delivery'] != null)
//                       Text('Est. Delivery: ${_order!['estimated_delivery'].substring(0, 16)}'),
//                     if (!_isSeller) Text('Seller: ${_order!['sellers']['store_name'] ?? 'Unknown'}'),
//                     if (_isSeller && emiApp != null)
//                       Text('Buyer: ${emiApp['full_name']} (${_order!['profiles']['email']})'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text('Items', style: Theme.of(context).textTheme.titleLarge),
//             ...items.map((item) => Card(
//                   child: ListTile(
//                     leading: item['products']['images'].isNotEmpty
//                         ? Image.network(item['products']['images'][0],
//                             width: 50, height: 50, fit: BoxFit.cover)
//                         : const Icon(Icons.image),
//                     title: Text(item['products']['title']),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Qty: ${item['quantity']}'),
//                         Text('Price: ₹${item['price'].toStringAsFixed(2)}'),
//                         if (item['variant_id'] != null)
//                           Text('Variant: ${item['product_variants'][0]['attributes'].toString()}'),
//                       ],
//                     ),
//                   ),
//                 )),
//             if (_isSeller && emiApp != null && emiApp['status'] == 'pending') ...[
//               const SizedBox(height: 16),
//               Text('EMI Application', style: Theme.of(context).textTheme.titleLarge),
//               Card(
//                 child: ListTile(
//                   title: Text(emiApp['product_name']),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Price: ₹${emiApp['product_price'].toStringAsFixed(2)}'),
//                       Text('Buyer: ${emiApp['full_name']} (${emiApp['mobile_number']})'),
//                       Text('Status: ${emiApp['status']}'),
//                       DropdownButton<String>(
//                         value: emiApp['status'],
//                         items: ['pending', 'approved', 'rejected']
//                             .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                             .toList(),
//                         onChanged: (v) => _updateEmiStatus(emiApp['uuid'], v!),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             if (_order!['order_status'] != 'Cancelled' && _order!['order_status'] != 'Delivered') ...[
//               const SizedBox(height: 16),
//               if (_isSeller)
//                 ElevatedButton(
//                   onPressed: () async {
//                     final next = await showDialog<String>(
//                       context: context,
//                       builder: (_) => StatefulBuilder(
//                         builder: (_, setD) {
//                           String? sel = _order!['order_status'];
//                           return AlertDialog(
//                             title: const Text('Update Status'),
//                             content: DropdownButton<String>(
//                               value: sel,
//                               isExpanded: true,
//                               items: [
//                                 'Order Placed',
//                                 'Shipped',
//                                 'Out for Delivery',
//                                 'Delivered',
//                                 'Cancelled'
//                               ]
//                                   .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                   .toList(),
//                               onChanged: (v) => setD(() => sel = v),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('Cancel'),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, sel),
//                                 child: const Text('Save'),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     );
//                     if (next != null && next != _order!['order_status']) {
//                       _updateOrderStatus(next);
//                     }
//                   },
//                   child: const Text('Update Status'),
//                 ),
//               if (!_isSeller)
//                 ElevatedButton(
//                   onPressed: () => setState(() => _cancelReason = ''),
//                   child: const Text('Cancel Order'),
//                 ),
//             ],
//             if (_cancelReason != null) _cancelDialog(),
//             if (_showRetryPayment) _retryPaymentDialog(),
//           ],
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// class OrderDetailsPage extends StatefulWidget {
//   final String id;
//   const OrderDetailsPage({super.key, required this.id});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   final _spb = Supabase.instance.client;
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _order;
//   Session? _session;
//   bool _isSeller = false;
//   String? _cancelReason;
//   bool _isCustomReason = false;
//   bool _showRetryPayment = false;
//   String _newPaymentMethod = 'credit_card';
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
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       final profile = await retry(() => _spb
//           .from('profiles')
//           .select('is_seller')
//           .eq('id', _session!.user.id)
//           .single());
//       _isSeller = profile['is_seller'] == true;

//       // Fetch the order with seller_id, but without the problematic foreign key join
//       _order = await retry(() => _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(status, product_name, product_price, full_name, mobile_number, uuid),
//         profiles!orders_user_id_fkey(email)
//       ''').eq('id', widget.id).single());

//       if (_order == null) {
//         setState(() => _error = 'Order not found.');
//         return;
//       }

//       // Fetch the seller's store_name separately using seller_id
//       if (_order!['seller_id'] != null) {
//         final seller = await retry(() => _spb
//             .from('sellers')
//             .select('store_name')
//             .eq('id', _order!['seller_id'])
//             .single());
//         _order!['sellers'] = seller; // Add the seller data to the order map
//       } else {
//         _order!['sellers'] = {'store_name': 'Unknown'}; // Fallback if seller_id is missing
//       }
//     } catch (e) {
//       setState(() => _error = 'Error: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _cancel() async {
//     if (_cancelReason == null || _cancelReason!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a cancellation reason.')),
//       );
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order cancelled successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error cancelling order: $e');
//     }
//   }

//   Future<void> _updateOrderStatus(String status) async {
//     try {
//       const validTransitions = {
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _order!['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid status transition from $current to $status.')),
//         );
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Order status updated to $status.')),
//       );
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating status: $e');
//     }
//   }

//   Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('uuid', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI approved successfully!')),
//         );
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() => _showRetryPayment = true);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI rejected. Prompting buyer to retry payment.')),
//         );
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', widget.id));
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating EMI status: $e');
//     }
//   }

//   Future<void> _retryPayment() async {
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', widget.id));
//       setState(() {
//         _showRetryPayment = false;
//         _newPaymentMethod = 'credit_card';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Payment method updated successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       setState(() => _error = 'Error updating payment: $e');
//     }
//   }

//   Widget _cancelDialog() {
//     final reasons = _isSeller ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DropdownButton<String>(
//             value: _cancelReason,
//             isExpanded: true,
//             hint: const Text('Select reason'),
//             items: reasons
//                 .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//                 .toList(),
//             onChanged: (v) => setState(() {
//               _cancelReason = v;
//               _isCustomReason = v == 'Other (please specify)';
//             }),
//           ),
//           if (_isCustomReason)
//             TextField(
//               onChanged: (v) => _cancelReason = v,
//               decoration: const InputDecoration(labelText: 'Custom reason'),
//             ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() {
//             _cancelReason = null;
//             _isCustomReason = false;
//           }),
//           child: const Text('Back'),
//         ),
//         TextButton(onPressed: _cancel, child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('EMI application was rejected. Select a new payment method.'),
//           DropdownButton<String>(
//             value: _newPaymentMethod,
//             isExpanded: true,
//             items: _paymentMethods
//                 .map((m) => DropdownMenuItem(
//                       value: m,
//                       child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                     ))
//                 .toList(),
//             onChanged: (v) => setState(() => _newPaymentMethod = v!),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         TextButton(onPressed: _retryPayment, child: const Text('Confirm')),
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

//     final items = _order!['order_items'] as List<dynamic>;
//     final emiApp = _order!['emi_applications'];

//     return Scaffold(
//       appBar: AppBar(title: Text('Order #${widget.id}')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: ListTile(
//                 title: Text('Order #${_order!['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Total: ₹${_order!['total'].toStringAsFixed(2)}'),
//                     Text('Status: ${_order!['order_status']}'),
//                     if (_order!['order_status'] == 'Cancelled')
//                       Text('Reason: ${_order!['cancellation_reason']}'),
//                     Text('Payment: ${_order!['payment_method'].replaceAll('_', ' ').toUpperCase()}'),
//                     if (_order!['estimated_delivery'] != null)
//                       Text('Est. Delivery: ${_order!['estimated_delivery'].substring(0, 16)}'),
//                     if (!_isSeller) Text('Seller: ${_order!['sellers']['store_name'] ?? 'Unknown'}'),
//                     if (_isSeller && emiApp != null)
//                       Text('Buyer: ${emiApp['full_name']} (${_order!['profiles']['email']})'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text('Items', style: Theme.of(context).textTheme.titleLarge),
//             ...items.map((item) => Card(
//                   child: ListTile(
//                     leading: item['products']['images'].isNotEmpty
//                         ? Image.network(item['products']['images'][0],
//                             width: 50, height: 50, fit: BoxFit.cover)
//                         : const Icon(Icons.image),
//                     title: Text(item['products']['title']),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Qty: ${item['quantity']}'),
//                         Text('Price: ₹${item['price'].toStringAsFixed(2)}'),
//                         if (item['variant_id'] != null)
//                           Text('Variant: ${item['product_variants'][0]['attributes'].toString()}'),
//                       ],
//                     ),
//                   ),
//                 )),
//             if (_isSeller && emiApp != null && emiApp['status'] == 'pending') ...[
//               const SizedBox(height: 16),
//               Text('EMI Application', style: Theme.of(context).textTheme.titleLarge),
//               Card(
//                 child: ListTile(
//                   title: Text(emiApp['product_name']),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Price: ₹${emiApp['product_price'].toStringAsFixed(2)}'),
//                       Text('Buyer: ${emiApp['full_name']} (${emiApp['mobile_number']})'),
//                       Text('Status: ${emiApp['status']}'),
//                       DropdownButton<String>(
//                         value: emiApp['status'],
//                         items: ['pending', 'approved', 'rejected']
//                             .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                             .toList(),
//                         onChanged: (v) => _updateEmiStatus(emiApp['uuid'], v!),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             if (_order!['order_status'] != 'Cancelled' && _order!['order_status'] != 'Delivered') ...[
//               const SizedBox(height: 16),
//               if (_isSeller)
//                 ElevatedButton(
//                   onPressed: () async {
//                     final next = await showDialog<String>(
//                       context: context,
//                       builder: (_) => StatefulBuilder(
//                         builder: (_, setD) {
//                           String? sel = _order!['order_status'];
//                           return AlertDialog(
//                             title: const Text('Update Status'),
//                             content: DropdownButton<String>(
//                               value: sel,
//                               isExpanded: true,
//                               items: [
//                                 'Order Placed',
//                                 'Shipped',
//                                 'Out for Delivery',
//                                 'Delivered',
//                                 'Cancelled'
//                               ]
//                                   .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                   .toList(),
//                               onChanged: (v) => setD(() => sel = v),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('Cancel'),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, sel),
//                                 child: const Text('Save'),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     );
//                     if (next != null && next != _order!['order_status']) {
//                       _updateOrderStatus(next);
//                     }
//                   },
//                   child: const Text('Update Status'),
//                 ),
//               if (!_isSeller)
//                 ElevatedButton(
//                   onPressed: () => setState(() => _cancelReason = ''),
//                   child: const Text('Cancel Order'),
//                 ),
//             ],
//             if (_cancelReason != null) _cancelDialog(),
//             if (_showRetryPayment) _retryPaymentDialog(),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// class OrderDetailsPage extends StatefulWidget {
//   final String id;
//   const OrderDetailsPage({super.key, required this.id});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   final _spb = Supabase.instance.client;
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _order;
//   Session? _session;
//   bool _isSeller = false;
//   String? _cancelReason;
//   bool _isCustomReason = false;
//   bool _showRetryPayment = false;
//   String _newPaymentMethod = 'credit_card';
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
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       final profile = await retry(() => _spb
//           .from('profiles')
//           .select('is_seller')
//           .eq('id', _session!.user.id)
//           .single());
//       _isSeller = profile['is_seller'] == true;

//       // Fetch the order with seller_id, but without the problematic foreign key join
//       _order = await retry(() => _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(status, product_name, product_price, full_name, mobile_number, uuid),
//         profiles!orders_user_id_fkey(email)
//       ''').eq('id', widget.id).single());

//       if (_order == null) {
//         setState(() => _error = 'Order not found.');
//         return;
//       }

//       // Fetch the seller's store_name separately using seller_id
//       if (_order!['seller_id'] != null) {
//         final seller = await retry(() => _spb
//             .from('sellers')
//             .select('store_name')
//             .eq('id', _order!['seller_id'])
//             .single());
//         _order!['sellers'] = seller; // Add the seller data to the order map
//       } else {
//         _order!['sellers'] = {'store_name': 'Unknown'}; // Fallback if seller_id is missing
//       }
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error: $e');
//       }
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _cancel() async {
//     if (_cancelReason == null || _cancelReason!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a cancellation reason.')),
//       );
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order cancelled successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error cancelling order: $e');
//       }
//     }
//   }

//   Future<void> _updateOrderStatus(String status) async {
//     try {
//       const validTransitions = {
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _order!['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid status transition from $current to $status.')),
//         );
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Order status updated to $status.')),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating status: $e');
//       }
//     }
//   }

//   Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('uuid', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI approved successfully!')),
//         );
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() => _showRetryPayment = true);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI rejected. Prompting buyer to retry payment.')),
//         );
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', widget.id));
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating EMI status: $e');
//       }
//     }
//   }

//   Future<void> _retryPayment() async {
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', widget.id));
//       setState(() {
//         _showRetryPayment = false;
//         _newPaymentMethod = 'credit_card';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Payment method updated successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating payment: $e');
//       }
//     }
//   }

//   Widget _cancelDialog() {
//     final reasons = _isSeller ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DropdownButton<String>(
//             value: _cancelReason,
//             isExpanded: true,
//             hint: const Text('Select reason'),
//             items: reasons
//                 .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//                 .toList(),
//             onChanged: (v) => setState(() {
//               _cancelReason = v;
//               _isCustomReason = v == 'Other (please specify)';
//             }),
//           ),
//           if (_isCustomReason)
//             TextField(
//               onChanged: (v) => _cancelReason = v,
//               decoration: const InputDecoration(labelText: 'Custom reason'),
//             ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() {
//             _cancelReason = null;
//             _isCustomReason = false;
//           }),
//           child: const Text('Back'),
//         ),
//         TextButton(onPressed: _cancel, child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('EMI application was rejected. Select a new payment method.'),
//           DropdownButton<String>(
//             value: _newPaymentMethod,
//             isExpanded: true,
//             items: _paymentMethods
//                 .map((m) => DropdownMenuItem(
//                       value: m,
//                       child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                     ))
//                 .toList(),
//             onChanged: (v) => setState(() => _newPaymentMethod = v!),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         TextButton(onPressed: _retryPayment, child: const Text('Confirm')),
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

//     final items = _order!['order_items'] as List<dynamic>;
//     final emiApp = _order!['emi_applications'];

//     return Scaffold(
//       appBar: AppBar(title: Text('Order #${widget.id}')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: ListTile(
//                 title: Text('Order #${_order!['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Ordered on: ${DateTime.parse(_order!['created_at']).toLocal().toString().substring(0, 16)}'),
//                     Text('Total: ₹${_order!['total'].toStringAsFixed(2)}'),
//                     Text('Status: ${_order!['order_status']}'),
//                     if (_order!['order_status'] == 'Cancelled')
//                       Text('Reason: ${_order!['cancellation_reason']}'),
//                     Text('Payment: ${_order!['payment_method'].replaceAll('_', ' ').toUpperCase()}'),
//                     if (_order!['estimated_delivery'] != null)
//                       Text('Est. Delivery: ${DateTime.parse(_order!['estimated_delivery']).toLocal().toString().substring(0, 16)}'),
//                     if (!_isSeller) Text('Seller: ${_order!['sellers']['store_name'] ?? 'Unknown'}'),
//                     if (_isSeller && emiApp != null)
//                       Text('Buyer: ${emiApp['full_name']} (${_order!['profiles']['email']})'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text('Items', style: Theme.of(context).textTheme.titleLarge),
//             ...items.map((item) => Card(
//                   child: ListTile(
//                     leading: item['products']['images'].isNotEmpty
//                         ? Image.network(
//                             item['products']['images'][0],
//                             width: 50,
//                             height: 50,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
//                           )
//                         : const Icon(Icons.image),
//                     title: Text(item['products']['title']),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Qty: ${item['quantity']}'),
//                         Text('Price: ₹${item['price'].toStringAsFixed(2)}'),
//                         if (item['variant_id'] != null)
//                           Text('Variant: ${item['product_variants'][0]['attributes'].toString()}'),
//                       ],
//                     ),
//                   ),
//                 )),
//             if (_isSeller && emiApp != null && emiApp['status'] == 'pending') ...[
//               const SizedBox(height: 16),
//               Text('EMI Application', style: Theme.of(context).textTheme.titleLarge),
//               Card(
//                 child: ListTile(
//                   title: Text(emiApp['product_name']),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Price: ₹${emiApp['product_price'].toStringAsFixed(2)}'),
//                       Text('Buyer: ${emiApp['full_name']} (${emiApp['mobile_number']})'),
//                       Text('Status: ${emiApp['status']}'),
//                       DropdownButton<String>(
//                         value: emiApp['status'],
//                         items: ['pending', 'approved', 'rejected']
//                             .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                             .toList(),
//                         onChanged: (v) => _updateEmiStatus(emiApp['uuid'], v!),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             if (_order!['order_status'] != 'Cancelled' && _order!['order_status'] != 'Delivered') ...[
//               const SizedBox(height: 16),
//               if (_isSeller)
//                 ElevatedButton(
//                   onPressed: () async {
//                     final next = await showDialog<String>(
//                       context: context,
//                       builder: (_) => StatefulBuilder(
//                         builder: (_, setD) {
//                           String? sel = _order!['order_status'];
//                           return AlertDialog(
//                             title: const Text('Update Status'),
//                             content: DropdownButton<String>(
//                               value: sel,
//                               isExpanded: true,
//                               items: [
//                                 'Order Placed',
//                                 'Shipped',
//                                 'Out for Delivery',
//                                 'Delivered',
//                                 'Cancelled'
//                               ]
//                                   .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                   .toList(),
//                               onChanged: (v) => setD(() => sel = v),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('Cancel'),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, sel),
//                                 child: const Text('Save'),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     );
//                     if (next != null && next != _order!['order_status']) {
//                       _updateOrderStatus(next);
//                     }
//                   },
//                   child: const Text('Update Status'),
//                 ),
//               if (!_isSeller)
//                 ElevatedButton(
//                   onPressed: () => setState(() => _cancelReason = ''),
//                   child: const Text('Cancel Order'),
//                 ),
//             ],
//             if (_cancelReason != null) _cancelDialog(),
//             if (_showRetryPayment) _retryPaymentDialog(),
//           ],
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// class OrderDetailsPage extends StatefulWidget {
//   final String id;
//   const OrderDetailsPage({super.key, required this.id});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   final _spb = Supabase.instance.client;
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _order;
//   Session? _session;
//   bool _isSeller = false;
//   String? _cancelReason;
//   bool _isCustomReason = false;
//   bool _showRetryPayment = false;
//   String _newPaymentMethod = 'credit_card';
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
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       final profile = await retry(() => _spb
//           .from('profiles')
//           .select('is_seller')
//           .eq('id', _session!.user.id)
//           .single());
//       _isSeller = profile['is_seller'] == true;

//       // Fetch the order with seller_id, without problematic foreign key join
//       _order = await retry(() => _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at),
//         profiles!orders_user_id_fkey(email)
//       ''').eq('id', widget.id).single());

//       if (_order == null) {
//         setState(() => _error = 'Order not found.');
//         return;
//       }

//       // Fetch the seller's store_name separately using seller_id
//       if (_order!['seller_id'] != null) {
//         final seller = await retry(() => _spb
//             .from('sellers')
//             .select('store_name')
//             .eq('id', _order!['seller_id'])
//             .single());
//         _order!['sellers'] = seller;
//       } else {
//         _order!['sellers'] = {'store_name': 'Unknown'};
//       }

//       // Debug: Print the order data to inspect product_variants and EMI status
//       print('Order data: $_order');
//       if (_isSeller && _order!['emi_applications'] != null) {
//         print('EMI Application Status: ${_order!['emi_applications']['status']}');
//       }
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error: $e');
//       }
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _cancel() async {
//     if (_cancelReason == null || _cancelReason!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a cancellation reason.')),
//       );
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order cancelled successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error cancelling order: $e');
//       }
//     }
//   }

//   Future<void> _updateOrderStatus(String status) async {
//     try {
//       const validTransitions = {
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _order!['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid status transition from $current to $status.')),
//         );
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Order status updated to $status.')),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating status: $e');
//       }
//     }
//   }

//   Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI approved successfully!')),
//         );
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() => _showRetryPayment = true);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('EMI rejected. Prompting buyer to retry payment.')),
//         );
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', widget.id));
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating EMI status: $e');
//       }
//     }
//   }

//   Future<void> _retryPayment() async {
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', widget.id));
//       setState(() {
//         _showRetryPayment = false;
//         _newPaymentMethod = 'credit_card';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Payment method updated successfully.')),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating payment: $e');
//       }
//     }
//   }

//   Widget _cancelDialog() {
//     final reasons = _isSeller ? _sellerReasons : _buyerReasons;
//     return AlertDialog(
//       title: Text('Cancel Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DropdownButton<String>(
//             value: _cancelReason,
//             isExpanded: true,
//             hint: const Text('Select reason'),
//             items: reasons
//                 .map((r) => DropdownMenuItem(value: r, child: Text(r)))
//                 .toList(),
//             onChanged: (v) => setState(() {
//               _cancelReason = v;
//               _isCustomReason = v == 'Other (please specify)';
//             }),
//           ),
//           if (_isCustomReason)
//             TextField(
//               onChanged: (v) => _cancelReason = v,
//               decoration: const InputDecoration(labelText: 'Custom reason'),
//             ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() {
//             _cancelReason = null;
//             _isCustomReason = false;
//           }),
//           child: const Text('Back'),
//         ),
//         TextButton(onPressed: _cancel, child: const Text('Confirm')),
//       ],
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AlertDialog(
//       title: Text('Retry Payment for Order #${widget.id}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('EMI application was rejected. Select a new payment method.'),
//           DropdownButton<String>(
//             value: _newPaymentMethod,
//             isExpanded: true,
//             items: _paymentMethods
//                 .map((m) => DropdownMenuItem(
//                       value: m,
//                       child: Text(m.replaceAll('_', ' ').toUpperCase()),
//                     ))
//                 .toList(),
//             onChanged: (v) => setState(() => _newPaymentMethod = v!),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => setState(() => _showRetryPayment = false),
//           child: const Text('Cancel'),
//         ),
//         TextButton(onPressed: _retryPayment, child: const Text('Confirm')),
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

//     final items = _order!['order_items'] as List<dynamic>;
//     final emiApp = _order!['emi_applications'];

//     return Scaffold(
//       appBar: AppBar(title: Text('Order #${widget.id}')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               child: ListTile(
//                 title: Text('Order #${_order!['id']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Ordered on: ${DateTime.parse(_order!['created_at']).toLocal().toString().substring(0, 16)}'),
//                     Text('Total: ₹${_order!['total'].toStringAsFixed(2)}'),
//                     Text('Status: ${_order!['order_status']}'),
//                     if (_order!['order_status'] == 'Cancelled')
//                       Text('Reason: ${_order!['cancellation_reason']}'),
//                     Text('Payment: ${_order!['payment_method'].replaceAll('_', ' ').toUpperCase()}'),
//                     if (_order!['estimated_delivery'] != null)
//                       Text('Est. Delivery: ${DateTime.parse(_order!['estimated_delivery']).toLocal().toString().substring(0, 16)}'),
//                     if (!_isSeller) Text('Seller: ${_order!['sellers']['store_name'] ?? 'Unknown'}'),
//                     if (_isSeller && emiApp != null)
//                       Text('Buyer: ${emiApp['full_name']} (${_order!['profiles']['email']})'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text('Items', style: Theme.of(context).textTheme.titleLarge),
//             ...items.map((item) => Card(
//                   child: ListTile(
//                     leading: item['products'] != null && (item['products']['images'] as List?)?.isNotEmpty == true
//                         ? Image.network(
//                             item['products']['images'][0],
//                             width: 50,
//                             height: 50,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
//                           )
//                         : const Icon(Icons.image),
//                     title: Text(item['products']?['title'] ?? 'Unknown Product'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Qty: ${item['quantity'] ?? 'N/A'}'),
//                         Text('Price: ₹${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
//                         if (item['variant_id'] != null)
//                           Text(
//                             'Variant: ${(item['product_variants'] != null && (item['product_variants'] as List).isNotEmpty) ? item['product_variants'][0]['attributes']?.toString() ?? 'N/A' : 'N/A'}',
//                           ),
//                       ],
//                     ),
//                   ),
//                 )),
//             if (_isSeller && emiApp != null && emiApp['status'] == 'pending') ...[
//               const SizedBox(height: 16),
//               Text('EMI Application', style: Theme.of(context).textTheme.titleLarge),
//               Card(
//                 child: ListTile(
//                   title: Text(emiApp['product_name'] ?? 'Unknown Product'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Price: ₹${(emiApp['product_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
//                       Text('Buyer: ${emiApp['full_name'] ?? 'Unknown'} (${emiApp['mobile_number'] ?? 'N/A'})'),
//                       Text('Status: ${emiApp['status'] ?? 'N/A'}'),
//                       // Normalize the status value
//                       Builder(builder: (context) {
//                         final currentEmiStatus = emiApp['status'] != null
//                             ? (emiApp['status'] as String).toLowerCase().trim()
//                             : 'pending'; // Default to 'pending' if null
//                         final validEmiStatus = ['pending', 'approved', 'rejected'].contains(currentEmiStatus)
//                             ? currentEmiStatus
//                             : 'pending'; // Fallback to 'pending' if invalid
//                         return DropdownButton<String>(
//                           value: validEmiStatus,
//                           items: ['pending', 'approved', 'rejected']
//                               .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                               .toList(),
//                           onChanged: (v) => _updateEmiStatus(emiApp['id'], v!),
//                         );
//                       }),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             if (_order!['order_status'] != 'Cancelled' && _order!['order_status'] != 'Delivered') ...[
//               const SizedBox(height: 16),
//               if (_isSeller)
//                 ElevatedButton(
//                   onPressed: () async {
//                     final next = await showDialog<String>(
//                       context: context,
//                       builder: (_) => StatefulBuilder(
//                         builder: (_, setD) {
//                           String? sel = _order!['order_status'];
//                           return AlertDialog(
//                             title: const Text('Update Status'),
//                             content: DropdownButton<String>(
//                               value: sel,
//                               isExpanded: true,
//                               items: [
//                                 'Order Placed',
//                                 'Shipped',
//                                 'Out for Delivery',
//                                 'Delivered',
//                                 'Cancelled'
//                               ]
//                                   .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                   .toList(),
//                               onChanged: (v) => setD(() => sel = v),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('Cancel'),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, sel),
//                                 child: const Text('Save'),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                     );
//                     if (next != null && next != _order!['order_status']) {
//                       _updateOrderStatus(next);
//                     }
//                   },
//                   child: const Text('Update Status'),
//                 ),
//               if (!_isSeller)
//                 ElevatedButton(
//                   onPressed: () => setState(() => _cancelReason = ''),
//                   child: const Text('Cancel Order'),
//                 ),
//             ],
//             if (_cancelReason != null) _cancelDialog(),
//             if (_showRetryPayment) _retryPaymentDialog(),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// // Define a premium color palette
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// class OrderDetailsPage extends StatefulWidget {
//   final String id;
//   const OrderDetailsPage({super.key, required this.id});

//   @override
//   State<OrderDetailsPage> createState() => _OrderDetailsPageState();
// }

// class _OrderDetailsPageState extends State<OrderDetailsPage> {
//   final _spb = Supabase.instance.client;
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _order;
//   Session? _session;
//   bool _isSeller = false;
//   String? _cancelReason;
//   bool _isCustomReason = false;
//   bool _showRetryPayment = false;
//   String _newPaymentMethod = 'credit_card';
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
//   final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       _session = context.read<AppState>().session;
//       if (_session == null) {
//         context.go('/auth');
//         return;
//       }

//       final profile = await retry(() => _spb
//           .from('profiles')
//           .select('is_seller')
//           .eq('id', _session!.user.id)
//           .single());
//       _isSeller = profile['is_seller'] == true;

//       _order = await retry(() => _spb.from('orders').select('''
//         id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
//         order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
//         emi_applications(id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at),
//         profiles!orders_user_id_fkey(email)
//       ''').eq('id', widget.id).single());

//       if (_order == null) {
//         setState(() => _error = 'Order not found.');
//         return;
//       }

//       if (_order!['seller_id'] != null) {
//         final seller = await retry(() => _spb
//             .from('sellers')
//             .select('store_name')
//             .eq('id', _order!['seller_id'])
//             .single());
//         _order!['sellers'] = seller;
//       } else {
//         _order!['sellers'] = {'store_name': 'Unknown'};
//       }

//       print('Order data: $_order');
//       if (_isSeller && _order!['emi_applications'] != null) {
//         print('EMI Application Status: ${_order!['emi_applications']['status']}');
//       }
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error: $e');
//       }
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _cancel() async {
//     if (_cancelReason == null || _cancelReason!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a cancellation reason.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//     try {
//       await retry(() => _spb
//           .from('orders')
//           .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
//           .eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Order cancelled successfully.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error cancelling order: $e');
//       }
//     }
//   }

//   Future<void> _updateOrderStatus(String status) async {
//     try {
//       const validTransitions = {
//         'Order Placed': ['Shipped', 'Cancelled'],
//         'Shipped': ['Out for Delivery', 'Cancelled'],
//         'Out for Delivery': ['Delivered', 'Cancelled'],
//         'Delivered': [],
//         'Cancelled': [],
//       };
//       final current = _order!['order_status'];
//       if (!validTransitions[current]!.contains(status)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Invalid status transition from $current to $status.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//       await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', widget.id));
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Order status updated to $status.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating status: $e');
//       }
//     }
//   }

//   Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
//     try {
//       await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
//       String orderStatus = 'pending';
//       if (newStatus == 'approved') {
//         orderStatus = 'Order Placed';
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('EMI approved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else if (newStatus == 'rejected') {
//         orderStatus = 'Cancelled';
//         setState(() => _showRetryPayment = true);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('EMI rejected. Prompting buyer to retry payment.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', widget.id));
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating EMI status: $e');
//       }
//     }
//   }

//   Future<void> _retryPayment() async {
//     try {
//       await retry(() => _spb.from('orders').update({
//         'payment_method': _newPaymentMethod,
//         'order_status': 'Order Placed',
//       }).eq('id', widget.id));
//       setState(() {
//         _showRetryPayment = false;
//         _newPaymentMethod = 'credit_card';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Payment method updated successfully.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       await _load();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
//       } else {
//         setState(() => _error = 'Error updating payment: $e');
//       }
//     }
//   }

//   Widget _cancelDialog() {
//     final reasons = _isSeller ? _sellerReasons : _buyerReasons;
//     return AnimatedOpacity(
//       opacity: 1.0,
//       duration: const Duration(milliseconds: 300),
//       child: AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         backgroundColor: premiumCardColor,
//         title: Text(
//           'Cancel Order #${widget.id}',
//           style: const TextStyle(
//             color: premiumTextColor,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
//               ),
//               child: DropdownButton<String>(
//                 value: _cancelReason,
//                 isExpanded: true,
//                 hint: const Text(
//                   'Select reason',
//                   style: TextStyle(color: premiumSecondaryTextColor),
//                 ),
//                 items: reasons
//                     .map((r) => DropdownMenuItem(
//                           value: r,
//                           child: Text(
//                             r,
//                             style: const TextStyle(color: premiumTextColor),
//                           ),
//                         ))
//                     .toList(),
//                 onChanged: (v) => setState(() {
//                   _cancelReason = v;
//                   _isCustomReason = v == 'Other (please specify)';
//                 }),
//                 underline: const SizedBox(),
//                 icon: const Icon(
//                   Icons.arrow_drop_down,
//                   color: premiumPrimaryColor,
//                 ),
//               ),
//             ),
//             if (_isCustomReason) ...[
//               const SizedBox(height: 16),
//               TextField(
//                 onChanged: (v) => _cancelReason = v,
//                 decoration: InputDecoration(
//                   labelText: 'Custom reason',
//                   labelStyle: const TextStyle(color: premiumSecondaryTextColor),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: premiumPrimaryColor),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: premiumAccentColor),
//                   ),
//                 ),
//                 style: const TextStyle(color: premiumTextColor),
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => setState(() {
//               _cancelReason = null;
//               _isCustomReason = false;
//             }),
//             child: const Text(
//               'Back',
//               style: TextStyle(color: premiumSecondaryTextColor),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _cancel,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             child: const Text(
//               'Confirm',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _retryPaymentDialog() {
//     return AnimatedOpacity(
//       opacity: 1.0,
//       duration: const Duration(milliseconds: 300),
//       child: AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         backgroundColor: premiumCardColor,
//         title: Text(
//           'Retry Payment for Order #${widget.id}',
//           style: const TextStyle(
//             color: premiumTextColor,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'EMI application was rejected. Select a new payment method.',
//               style: TextStyle(color: premiumSecondaryTextColor),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
//               ),
//               child: DropdownButton<String>(
//                 value: _newPaymentMethod,
//                 isExpanded: true,
//                 items: _paymentMethods
//                     .map((m) => DropdownMenuItem(
//                           value: m,
//                           child: Text(
//                             m.replaceAll('_', ' ').toUpperCase(),
//                             style: const TextStyle(color: premiumTextColor),
//                           ),
//                         ))
//                     .toList(),
//                 onChanged: (v) => setState(() => _newPaymentMethod = v!),
//                 underline: const SizedBox(),
//                 icon: const Icon(
//                   Icons.arrow_drop_down,
//                   color: premiumPrimaryColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => setState(() => _showRetryPayment = false),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: premiumSecondaryTextColor),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _retryPayment,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumAccentColor,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             child: const Text(
//               'Confirm',
//               style: TextStyle(color: premiumTextColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: const Center(
//           child: CircularProgressIndicator(
//             color: premiumPrimaryColor,
//           ),
//         ),
//       );
//     }
//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 color: Colors.red,
//                 size: 48,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Error: $_error',
//                 style: const TextStyle(
//                   color: premiumTextColor,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _load,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: premiumPrimaryColor,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 child: const Text(
//                   'Retry',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final items = _order!['order_items'] as List<dynamic>;
//     final emiApp = _order!['emi_applications'];

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: AppBar(
//         title: Text(
//           'Order #${widget.id}',
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: premiumPrimaryColor,
//         elevation: 4,
//         shadowColor: Colors.black.withOpacity(0.2),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _load,
//         color: premiumPrimaryColor,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Order Summary Card
//               Card(
//                 elevation: 6,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 color: premiumCardColor,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.receipt_long,
//                             color: premiumPrimaryColor,
//                             size: 28,
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             'Order #${_order!['id']}',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: premiumTextColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Ordered on: ${DateTime.parse(_order!['created_at']).toLocal().toString().substring(0, 16)}',
//                         style: const TextStyle(
//                           color: premiumSecondaryTextColor,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Total: ₹${_order!['total'].toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           color: premiumTextColor,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           const Text(
//                             'Status: ',
//                             style: TextStyle(
//                               color: premiumSecondaryTextColor,
//                               fontSize: 14,
//                             ),
//                           ),
//                           Text(
//                             _order!['order_status'],
//                             style: TextStyle(
//                               color: _order!['order_status'] == 'Cancelled'
//                                   ? Colors.red
//                                   : _order!['order_status'] == 'Delivered'
//                                       ? Colors.green
//                                       : premiumPrimaryColor,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (_order!['order_status'] == 'Cancelled') ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           'Reason: ${_order!['cancellation_reason']}',
//                           style: const TextStyle(
//                             color: Colors.red,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 4),
//                       Text(
//                         'Payment: ${_order!['payment_method'].replaceAll('_', ' ').toUpperCase()}',
//                         style: const TextStyle(
//                           color: premiumSecondaryTextColor,
//                           fontSize: 14,
//                         ),
//                       ),
//                       if (_order!['estimated_delivery'] != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           'Est. Delivery: ${DateTime.parse(_order!['estimated_delivery']).toLocal().toString().substring(0, 16)}',
//                           style: const TextStyle(
//                             color: premiumSecondaryTextColor,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                       if (!_isSeller) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           'Seller: ${_order!['sellers']['store_name'] ?? 'Unknown'}',
//                           style: const TextStyle(
//                             color: premiumSecondaryTextColor,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                       if (_isSeller && emiApp != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           'Buyer: ${emiApp['full_name']} (${_order!['profiles']['email']})',
//                           style: const TextStyle(
//                             color: premiumSecondaryTextColor,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Items Section
//               Text(
//                 'Items',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 12),
//               ...items.map((item) => Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     color: premiumCardColor,
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: item['products'] != null && (item['products']['images'] as List?)?.isNotEmpty == true
//                                 ? Image.network(
//                                     item['products']['images'][0],
//                                     width: 60,
//                                     height: 60,
//                                     fit: BoxFit.cover,
//                                     loadingBuilder: (context, child, loadingProgress) {
//                                       if (loadingProgress == null) return child;
//                                       return const Center(
//                                         child: CircularProgressIndicator(
//                                           color: premiumPrimaryColor,
//                                           strokeWidth: 2,
//                                         ),
//                                       );
//                                     },
//                                     errorBuilder: (context, error, stackTrace) => const Icon(
//                                       Icons.broken_image,
//                                       color: premiumSecondaryTextColor,
//                                       size: 60,
//                                     ),
//                                   )
//                                 : const Icon(
//                                     Icons.image,
//                                     color: premiumSecondaryTextColor,
//                                     size: 60,
//                                   ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   item['products']?['title'] ?? 'Unknown Product',
//                                   style: const TextStyle(
//                                     color: premiumTextColor,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Qty: ${item['quantity'] ?? 'N/A'}',
//                                   style: const TextStyle(
//                                     color: premiumSecondaryTextColor,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Price: ₹${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                                   style: const TextStyle(
//                                     color: premiumTextColor,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                                 if (item['variant_id'] != null) ...[
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'Variant: ${(item['product_variants'] != null && (item['product_variants'] as List).isNotEmpty) ? item['product_variants'][0]['attributes']?.toString() ?? 'N/A' : 'N/A'}',
//                                     style: const TextStyle(
//                                       color: premiumSecondaryTextColor,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )),

//               // EMI Application Section
//               if (_isSeller && emiApp != null && emiApp['status'] == 'pending') ...[
//                 const SizedBox(height: 24),
//                 Text(
//                   'EMI Application',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         color: premiumTextColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//                 const SizedBox(height: 12),
//                 Card(
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   color: premiumCardColor,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.account_balance,
//                               color: premiumPrimaryColor,
//                               size: 28,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 emiApp['product_name'] ?? 'Unknown Product',
//                                 style: const TextStyle(
//                                   color: premiumTextColor,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Price: ₹${(emiApp['product_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                           style: const TextStyle(
//                             color: premiumTextColor,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Buyer: ${emiApp['full_name'] ?? 'Unknown'} (${emiApp['mobile_number'] ?? 'N/A'})',
//                           style: const TextStyle(
//                             color: premiumSecondaryTextColor,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Text(
//                               'Status: ',
//                               style: TextStyle(
//                                 color: premiumSecondaryTextColor,
//                                 fontSize: 14,
//                               ),
//                             ),
//                             Text(
//                               emiApp['status'] ?? 'N/A',
//                               style: const TextStyle(
//                                 color: Colors.orange,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
//                           ),
//                           child: Builder(builder: (context) {
//                             final currentEmiStatus = emiApp['status'] != null
//                                 ? (emiApp['status'] as String).toLowerCase().trim()
//                                 : 'pending';
//                             final validEmiStatus = ['pending', 'approved', 'rejected'].contains(currentEmiStatus)
//                                 ? currentEmiStatus
//                                 : 'pending';
//                             return DropdownButton<String>(
//                               value: validEmiStatus,
//                               isExpanded: true,
//                               items: ['pending', 'approved', 'rejected']
//                                   .map((s) => DropdownMenuItem(
//                                         value: s,
//                                         child: Text(
//                                           s,
//                                           style: const TextStyle(color: premiumTextColor),
//                                         ),
//                                       ))
//                                   .toList(),
//                               onChanged: (v) => _updateEmiStatus(emiApp['id'], v!),
//                               underline: const SizedBox(),
//                               icon: const Icon(
//                                 Icons.arrow_drop_down,
//                                 color: premiumPrimaryColor,
//                               ),
//                             );
//                           }),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],

//               // Action Buttons
//               if (_order!['order_status'] != 'Cancelled' && _order!['order_status'] != 'Delivered') ...[
//                 const SizedBox(height: 24),
//                 if (_isSeller)
//                   ElevatedButton(
//                     onPressed: () async {
//                       final next = await showDialog<String>(
//                         context: context,
//                         builder: (_) => StatefulBuilder(
//                           builder: (_, setD) {
//                             String? sel = _order!['order_status'];
//                             return AlertDialog(
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                               backgroundColor: premiumCardColor,
//                               title: const Text(
//                                 'Update Status',
//                                 style: TextStyle(
//                                   color: premiumTextColor,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 20,
//                                 ),
//                               ),
//                               content: Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
//                                 ),
//                                 child: DropdownButton<String>(
//                                   value: sel,
//                                   isExpanded: true,
//                                   items: [
//                                     'Order Placed',
//                                     'Shipped',
//                                     'Out for Delivery',
//                                     'Delivered',
//                                     'Cancelled'
//                                   ]
//                                       .map((s) => DropdownMenuItem(
//                                             value: s,
//                                             child: Text(
//                                               s,
//                                               style: const TextStyle(color: premiumTextColor),
//                                             ),
//                                           ))
//                                       .toList(),
//                                   onChanged: (v) => setD(() => sel = v),
//                                   underline: const SizedBox(),
//                                   icon: const Icon(
//                                     Icons.arrow_drop_down,
//                                     color: premiumPrimaryColor,
//                                   ),
//                                 ),
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: const Text(
//                                     'Cancel',
//                                     style: TextStyle(color: premiumSecondaryTextColor),
//                                   ),
//                                 ),
//                                 ElevatedButton(
//                                   onPressed: () => Navigator.pop(context, sel),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: premiumPrimaryColor,
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                   ),
//                                   child: const Text(
//                                     'Save',
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       );
//                       if (next != null && next != _order!['order_status']) {
//                         _updateOrderStatus(next);
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: premiumPrimaryColor,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                       elevation: 4,
//                     ),
//                     child: const Text(
//                       'Update Status',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 if (!_isSeller)
//                   ElevatedButton(
//                     onPressed: () => setState(() => _cancelReason = ''),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.redAccent,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                       elevation: 4,
//                     ),
//                     child: const Text(
//                       'Cancel Order',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//               ],
//               if (_cancelReason != null) _cancelDialog(),
//               if (_showRetryPayment) _retryPaymentDialog(),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

// Define a premium color palette
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumAccentColor = Color(0xFFFFD740); // Gold
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

class OrderDetailsPage extends StatefulWidget {
  final String id;
  const OrderDetailsPage({super.key, required this.id});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _spb = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;
  Session? _session;
  bool _isSeller = false;
  String? _cancelReason;
  bool _isCustomReason = false;
  bool _showRetryPayment = false;
  String _newPaymentMethod = 'credit_card';
  final _buyerReasons = [
    'Changed my mind',
    'Found a better price elsewhere',
    'Item no longer needed',
    'Other (please specify)'
  ];
  final _sellerReasons = [
    'Out of stock',
    'Unable to ship',
    'Buyer request',
    'Other (please specify)'
  ];
  final _paymentMethods = ['credit_card', 'debit_card', 'upi', 'cash_on_delivery'];
  final _validOrderStatuses = [
    'Order Placed',
    'Shipped',
    'Out for Delivery',
    'Delivered',
    'Cancelled'
  ];
  final _validEmiStatuses = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _session = context.read<AppState>().session;
      if (_session == null) {
        context.go('/auth');
        return;
      }

      final profile = await retry(() => _spb
          .from('profiles')
          .select('is_seller')
          .eq('id', _session!.user.id)
          .single());
      _isSeller = profile['is_seller'] == true;

      _order = await retry(() => _spb.from('orders').select('''
        id, total, order_status, cancellation_reason, payment_method, created_at, estimated_delivery, seller_id,
        order_items(quantity, price, variant_id, products(id, title, images), product_variants(id, attributes, images, price)),
        emi_applications(id, status, product_name, product_price, full_name, mobile_number, seller_name, seller_phone_number, created_at),
        profiles!orders_user_id_fkey(email)
      ''').eq('id', widget.id).single());

      if (_order == null) {
        setState(() => _error = 'Order not found.');
        return;
      }

      if (_order!['seller_id'] != null) {
        final seller = await retry(() => _spb
            .from('sellers')
            .select('store_name')
            .eq('id', _order!['seller_id'])
            .single());
        _order!['sellers'] = seller;
      } else {
        _order!['sellers'] = {'store_name': 'Unknown'};
      }

      // Normalize order_status to match _validOrderStatuses
      if (_order!['order_status'] != null) {
        final currentStatus = _order!['order_status'].toString().trim();
        _order!['order_status'] = _validOrderStatuses.firstWhere(
          (status) => status.toLowerCase() == currentStatus.toLowerCase(),
          orElse: () => 'Order Placed', // Default to 'Order Placed' if not found
        );
      } else {
        _order!['order_status'] = 'Order Placed'; // Default if null
      }

      // Normalize emi_applications status
      if (_order!['emi_applications'] != null && _order!['emi_applications']['status'] != null) {
        final currentEmiStatus = _order!['emi_applications']['status'].toString().trim().toLowerCase();
        _order!['emi_applications']['status'] = _validEmiStatuses.contains(currentEmiStatus)
            ? currentEmiStatus
            : 'pending'; // Default to 'pending' if not valid
      }

      print('Order data: $_order');
      if (_isSeller && _order!['emi_applications'] != null) {
        print('EMI Application Status: ${_order!['emi_applications']['status']}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    if (_cancelReason == null || _cancelReason!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cancellation reason.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await retry(() => _spb
          .from('orders')
          .update({'order_status': 'Cancelled', 'cancellation_reason': _cancelReason})
          .eq('id', widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      await _load();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        setState(() => _error = 'Error cancelling order: $e');
      }
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    try {
      const validTransitions = {
        'Order Placed': ['Shipped', 'Cancelled'],
        'Shipped': ['Out for Delivery', 'Cancelled'],
        'Out for Delivery': ['Delivered', 'Cancelled'],
        'Delivered': [],
        'Cancelled': [],
      };
      final current = _order!['order_status'];
      if (!validTransitions[current]!.contains(status)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid status transition from $current to $status.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await retry(() => _spb.from('orders').update({'order_status': status}).eq('id', widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status.'),
          backgroundColor: Colors.green,
        ),
      );
      await _load();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        setState(() => _error = 'Error updating status: $e');
      }
    }
  }

  Future<void> _updateEmiStatus(String emiAppId, String newStatus) async {
    try {
      await retry(() => _spb.from('emi_applications').update({'status': newStatus}).eq('id', emiAppId));
      String orderStatus = 'pending';
      if (newStatus == 'approved') {
        orderStatus = 'Order Placed';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMI approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (newStatus == 'rejected') {
        orderStatus = 'Cancelled';
        setState(() => _showRetryPayment = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMI rejected. Prompting buyer to retry payment.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await retry(() => _spb.from('orders').update({'order_status': orderStatus}).eq('id', widget.id));
      await _load();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        setState(() => _error = 'Error updating EMI status: $e');
      }
    }
  }

  Future<void> _retryPayment() async {
    try {
      await retry(() => _spb.from('orders').update({
        'payment_method': _newPaymentMethod,
        'order_status': 'Order Placed',
      }).eq('id', widget.id));
      setState(() {
        _showRetryPayment = false;
        _newPaymentMethod = 'credit_card';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      await _load();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        setState(() => _error = 'Error updating payment: $e');
      }
    }
  }

  Widget _cancelDialog() {
    final reasons = _isSeller ? _sellerReasons : _buyerReasons;
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: premiumCardColor,
        title: Text(
          'Cancel Order #${widget.id}',
          style: const TextStyle(
            color: premiumTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
              ),
              child: DropdownButton<String>(
                value: _cancelReason,
                isExpanded: true,
                hint: const Text(
                  'Select reason',
                  style: TextStyle(color: premiumSecondaryTextColor),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r,
                            style: const TextStyle(color: premiumTextColor),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _cancelReason = v;
                  _isCustomReason = v == 'Other (please specify)';
                }),
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: premiumPrimaryColor,
                ),
              ),
            ),
            if (_isCustomReason) ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => _cancelReason = v,
                decoration: InputDecoration(
                  labelText: 'Custom reason',
                  labelStyle: const TextStyle(color: premiumSecondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: premiumPrimaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: premiumAccentColor),
                  ),
                ),
                style: const TextStyle(color: premiumTextColor),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _cancelReason = null;
              _isCustomReason = false;
            }),
            child: const Text(
              'Back',
              style: TextStyle(color: premiumSecondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: _cancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retryPaymentDialog() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: premiumCardColor,
        title: Text(
          'Retry Payment for Order #${widget.id}',
          style: const TextStyle(
            color: premiumTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'EMI application was rejected. Select a new payment method.',
              style: TextStyle(color: premiumSecondaryTextColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
              ),
              child: DropdownButton<String>(
                value: _newPaymentMethod,
                isExpanded: true,
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(color: premiumTextColor),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _newPaymentMethod = v!),
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: premiumPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showRetryPayment = false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: premiumSecondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: _retryPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: premiumAccentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: premiumTextColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: premiumBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: premiumPrimaryColor,
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: premiumBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(
                  color: premiumTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _order!['order_items'] as List<dynamic>;
    final emiApp = _order!['emi_applications'];

    return Scaffold(
      backgroundColor: premiumBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Order #${widget.id}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: premiumPrimaryColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: premiumPrimaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: premiumCardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: premiumPrimaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order #${_order!['id']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: premiumTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ordered on: ${DateTime.parse(_order!['created_at']).toLocal().toString().substring(0, 16)}',
                        style: const TextStyle(
                          color: premiumSecondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ₹${_order!['total'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: premiumTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              color: premiumSecondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _order!['order_status'],
                            style: TextStyle(
                              color: _order!['order_status'] == 'Cancelled'
                                  ? Colors.red
                                  : _order!['order_status'] == 'Delivered'
                                      ? Colors.green
                                      : premiumPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (_order!['order_status'] == 'Cancelled') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${_order!['cancellation_reason']}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Payment: ${_order!['payment_method'].replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(
                          color: premiumSecondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      if (_order!['estimated_delivery'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Est. Delivery: ${DateTime.parse(_order!['estimated_delivery']).toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(
                            color: premiumSecondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (!_isSeller) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Seller: ${_order!['sellers']['store_name'] ?? 'Unknown'}',
                          style: const TextStyle(
                            color: premiumSecondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (_isSeller && emiApp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Buyer: ${emiApp['full_name']} (${_order!['profiles']['email']})',
                          style: const TextStyle(
                            color: premiumSecondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Items Section
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: premiumTextColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: premiumCardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item['products'] != null && (item['products']['images'] as List?)?.isNotEmpty == true
                                ? Image.network(
                                    item['products']['images'][0],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: premiumPrimaryColor,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      color: premiumSecondaryTextColor,
                                      size: 60,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    color: premiumSecondaryTextColor,
                                    size: 60,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['products']?['title'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                    color: premiumTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item['quantity'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    color: premiumSecondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Price: ₹${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    color: premiumTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item['variant_id'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Variant: ${(item['product_variants'] != null && (item['product_variants'] as List).isNotEmpty) ? item['product_variants'][0]['attributes']?.toString() ?? 'N/A' : 'N/A'}',
                                    style: const TextStyle(
                                      color: premiumSecondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              // EMI Application Section
              if (_isSeller && emiApp != null) ...[
                const SizedBox(height: 24),
                Text(
                  'EMI Application',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: premiumTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: premiumCardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance,
                              color: premiumPrimaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                emiApp['product_name'] ?? 'Unknown Product',
                                style: const TextStyle(
                                  color: premiumTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Price: ₹${(emiApp['product_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: premiumTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buyer: ${emiApp['full_name'] ?? 'Unknown'} (${emiApp['mobile_number'] ?? 'N/A'})',
                          style: const TextStyle(
                            color: premiumSecondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Status: ',
                              style: TextStyle(
                                color: premiumSecondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              emiApp['status']?.toString() ?? 'N/A',
                              style: TextStyle(
                                color: emiApp['status'] == 'pending'
                                    ? Colors.orange
                                    : emiApp['status'] == 'approved'
                                        ? Colors.green
                                        : Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (emiApp['status'] == 'pending') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
                            ),
                            child: DropdownButton<String>(
                              value: emiApp['status']?.toString().toLowerCase() ?? 'pending',
                              isExpanded: true,
                              items: _validEmiStatuses
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s.toUpperCase(),
                                          style: const TextStyle(color: premiumTextColor),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => _updateEmiStatus(emiApp['id'], v!),
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: premiumPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Action Buttons
              if (_order!['order_status'] != 'Cancelled' && _order!['order_status'] != 'Delivered') ...[
                const SizedBox(height: 24),
                if (_isSeller)
                  ElevatedButton(
                    onPressed: () async {
                      String? sel = _order!['order_status'];
                      final next = await showDialog<String>(
                        context: context,
                        builder: (_) => StatefulBuilder(
                          builder: (_, setD) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: premiumCardColor,
                              title: const Text(
                                'Update Status',
                                style: TextStyle(
                                  color: premiumTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              content: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: premiumPrimaryColor.withOpacity(0.3)),
                                ),
                                child: DropdownButton<String>(
                                  value: sel,
                                  isExpanded: true,
                                  items: _validOrderStatuses
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              s,
                                              style: const TextStyle(color: premiumTextColor),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setD(() => sel = v),
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: premiumPrimaryColor,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: premiumSecondaryTextColor),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, sel),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: premiumPrimaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                      if (next != null && next != _order!['order_status']) {
                        _updateOrderStatus(next);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: premiumPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Update Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!_isSeller)
                  ElevatedButton(
                    onPressed: () => setState(() => _cancelReason = ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              if (_cancelReason != null) _cancelDialog(),
              if (_showRetryPayment) _retryPaymentDialog(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}