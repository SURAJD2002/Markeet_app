// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// // Define the premium color palette for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// class ProductsPage extends StatefulWidget {
//   final String? categoryId;
//   const ProductsPage({super.key, this.categoryId});

//   @override
//   State<ProductsPage> createState() => _ProductsPageState();
// }

// class _ProductsPageState extends State<ProductsPage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   String _categoryName = 'Products';
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadProducts() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       // Fetch category name if categoryId is provided
//       if (widget.categoryId != null) {
//         final category = await _spb
//             .from('categories')
//             .select('name')
//             .eq('id', int.parse(widget.categoryId!))
//             .maybeSingle();
//         if (category != null) {
//           setState(() => _categoryName = category['name'] ?? 'Products');
//         }
//       }

//       // Fetch products
//       var query = _spb
//           .from('products')
//           .select('id, title, price, images, stock, sellers(store_name)')
//           .eq('is_approved', true);

//       if (widget.categoryId != null) {
//         query = query.eq('category_id', int.parse(widget.categoryId!));
//       }

//       final res = await query.order('title');
//       setState(() {
//         _products = res.cast<Map<String, dynamic>>();
//       });
//     } catch (e) {
//       setState(() => _error = 'Error fetching products: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filtered = _search.isEmpty
//         ? _products
//         : _products.where((p) => (p['title'] as String).toLowerCase().contains(_search.toLowerCase())).toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: AppBar(
//         title: Text(
//           _categoryName,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: premiumPrimaryColor,
//         elevation: 4,
//         shadowColor: Colors.black.withOpacity(0.2),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [premiumPrimaryColor, Color(0xFF3F51B5)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadProducts,
//         color: premiumPrimaryColor,
//         child: _loading
//             ? const Center(child: CircularProgressIndicator(color: premiumPrimaryColor))
//             : _error != null
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           color: Colors.red,
//                           size: 48,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           _error!,
//                           style: const TextStyle(
//                             color: premiumTextColor,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _loadProducts,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: premiumPrimaryColor,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                           ),
//                           child: const Text(
//                             'Retry',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Column(
//                     children: [
//                       // Search Bar
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         child: TextField(
//                           decoration: InputDecoration(
//                             prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//                             hintText: 'Search products…',
//                             hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                           ),
//                           onChanged: (txt) {
//                             _debounce?.cancel();
//                             _debounce = Timer(const Duration(milliseconds: 300), () {
//                               setState(() => _search = txt.toLowerCase());
//                             });
//                           },
//                         ),
//                       ),
//                       Expanded(
//                         child: filtered.isEmpty
//                             ? const Center(child: Text('No products found.', style: TextStyle(color: premiumTextColor)))
//                             : GridView.builder(
//                                 padding: const EdgeInsets.all(12),
//                                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 2,
//                                   childAspectRatio: 0.75,
//                                   crossAxisSpacing: 12,
//                                   mainAxisSpacing: 12,
//                                 ),
//                                 itemCount: filtered.length,
//                                 itemBuilder: (context, index) {
//                                   final product = filtered[index];
//                                   final imageUrl = (product['images'] as List?)?.isNotEmpty == true
//                                       ? product['images'][0]
//                                       : 'https://via.placeholder.com/150x150?text=Product';
//                                   return InkWell(
//                                     onTap: () => context.go('/products/${product['id']}'),
//                                     borderRadius: BorderRadius.circular(12),
//                                     child: Card(
//                                       elevation: 4,
//                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                       color: premiumCardColor,
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                                         children: [
//                                           Expanded(
//                                             child: ClipRRect(
//                                               borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                                               child: Image.network(
//                                                 imageUrl,
//                                                 fit: BoxFit.cover,
//                                                 loadingBuilder: (context, child, loadingProgress) {
//                                                   if (loadingProgress == null) return child;
//                                                   return const Center(
//                                                     child: CircularProgressIndicator(
//                                                       color: premiumPrimaryColor,
//                                                       strokeWidth: 2,
//                                                     ),
//                                                   );
//                                                 },
//                                                 errorBuilder: (context, error, stackTrace) => const Icon(
//                                                   Icons.broken_image,
//                                                   color: premiumSecondaryTextColor,
//                                                   size: 50,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           Padding(
//                                             padding: const EdgeInsets.all(8),
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   product['title'] ?? 'Unknown Product',
//                                                   maxLines: 2,
//                                                   overflow: TextOverflow.ellipsis,
//                                                   style: const TextStyle(
//                                                     color: premiumTextColor,
//                                                     fontWeight: FontWeight.w600,
//                                                     fontSize: 14,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 4),
//                                                 Text(
//                                                   '₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
//                                                   style: const TextStyle(
//                                                     color: Colors.green,
//                                                     fontWeight: FontWeight.w600,
//                                                     fontSize: 14,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 4),
//                                                 Text(
//                                                   product['sellers']?['store_name'] ?? 'Unknown Seller',
//                                                   style: const TextStyle(
//                                                     color: premiumSecondaryTextColor,
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ],
//                   ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart'; // Import AppState for cart functionality

// // Define the premium color palette for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// class ProductsPage extends StatefulWidget {
//   final String? categoryId;
//   const ProductsPage({super.key, this.categoryId});

//   @override
//   State<ProductsPage> createState() => _ProductsPageState();
// }

// class _ProductsPageState extends State<ProductsPage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   String _categoryName = 'Products';
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadProducts() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       // Fetch category name if categoryId is provided
//       if (widget.categoryId != null) {
//         final category = await _spb
//             .from('categories')
//             .select('name')
//             .eq('id', int.parse(widget.categoryId!))
//             .maybeSingle();
//         if (category != null) {
//           setState(() => _categoryName = category['name'] ?? 'Products');
//         }
//       }

//       // Fetch products
//       var query = _spb
//           .from('products')
//           .select('id, title, price, images, stock, sellers(store_name)')
//           .eq('is_approved', true);

//       if (widget.categoryId != null) {
//         query = query.eq('category_id', int.parse(widget.categoryId!));
//       }

//       final res = await query.order('title');
//       setState(() {
//         _products = res.cast<Map<String, dynamic>>();
//       });
//     } catch (e) {
//       setState(() => _error = 'Error fetching products: $e');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   // Function to handle adding a product to the cart
//   Future<void> _addToCart(Map<String, dynamic> product, {bool goToCart = false}) async {
//     final app = context.read<AppState>();
//     final uid = app.session?.user.id;

//     if (uid == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please log in to add items to your cart'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       context.go('/auth');
//       return;
//     }

//     try {
//       final exists = await _spb
//           .from('cart')
//           .select('id, quantity')
//           .eq('user_id', uid)
//           .eq('product_id', product['id'])
//           .maybeSingle();

//       if (exists != null) {
//         await _spb.from('cart').update({'quantity': exists['quantity'] + 1}).eq('id', exists['id']);
//       } else {
//         await _spb.from('cart').insert({
//           'user_id': uid,
//           'product_id': product['id'],
//           'quantity': 1,
//           'price': product['price'],
//         });
//       }

//       await app.refreshCartCount();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Added to cart'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       if (goToCart) context.go('/cart');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding to cart: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filtered = _search.isEmpty
//         ? _products
//         : _products.where((p) => (p['title'] as String).toLowerCase().contains(_search.toLowerCase())).toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: AppBar(
//         title: Text(
//           _categoryName,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: premiumPrimaryColor,
//         elevation: 4,
//         shadowColor: Colors.black.withOpacity(0.2),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [premiumPrimaryColor, Color(0xFF3F51B5)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadProducts,
//         color: premiumPrimaryColor,
//         child: _loading
//             ? const Center(child: CircularProgressIndicator(color: premiumPrimaryColor))
//             : _error != null
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           color: Colors.red,
//                           size: 48,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           _error!,
//                           style: const TextStyle(
//                             color: premiumTextColor,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: _loadProducts,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: premiumPrimaryColor,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                           ),
//                           child: const Text(
//                             'Retry',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Column(
//                     children: [
//                       // Search Bar
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         child: TextField(
//                           decoration: InputDecoration(
//                             prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//                             hintText: 'Search products…',
//                             hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                           ),
//                           onChanged: (txt) {
//                             _debounce?.cancel();
//                             _debounce = Timer(const Duration(milliseconds: 300), () {
//                               setState(() => _search = txt.toLowerCase());
//                             });
//                           },
//                         ),
//                       ),
//                       Expanded(
//                         child: filtered.isEmpty
//                             ? const Center(child: Text('No products found.', style: TextStyle(color: premiumTextColor)))
//                             : GridView.builder(
//                                 padding: const EdgeInsets.all(12),
//                                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 2,
//                                   childAspectRatio: 0.65, // Adjusted to accommodate buttons
//                                   crossAxisSpacing: 12,
//                                   mainAxisSpacing: 12,
//                                 ),
//                                 itemCount: filtered.length,
//                                 itemBuilder: (context, index) {
//                                   final product = filtered[index];
//                                   final imageUrl = (product['images'] as List?)?.isNotEmpty == true
//                                       ? product['images'][0]
//                                       : 'https://via.placeholder.com/150x150?text=Product';
//                                   final isOutOfStock = product['stock'] == null || product['stock'] == 0;

//                                   return InkWell(
//                                     onTap: () => context.go('/products/${product['id']}'),
//                                     borderRadius: BorderRadius.circular(12),
//                                     child: Card(
//                                       elevation: 4,
//                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                       color: premiumCardColor,
//                                       child: Stack(
//                                         children: [
//                                           Column(
//                                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                                             children: [
//                                               Expanded(
//                                                 child: ClipRRect(
//                                                   borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                                                   child: Image.network(
//                                                     imageUrl,
//                                                     fit: BoxFit.cover,
//                                                     loadingBuilder: (context, child, loadingProgress) {
//                                                       if (loadingProgress == null) return child;
//                                                       return const Center(
//                                                         child: CircularProgressIndicator(
//                                                           color: premiumPrimaryColor,
//                                                           strokeWidth: 2,
//                                                         ),
//                                                       );
//                                                     },
//                                                     errorBuilder: (context, error, stackTrace) => const Icon(
//                                                       Icons.broken_image,
//                                                       color: premiumSecondaryTextColor,
//                                                       size: 50,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                               Padding(
//                                                 padding: const EdgeInsets.all(8),
//                                                 child: Column(
//                                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       product['title'] ?? 'Unknown Product',
//                                                       maxLines: 2,
//                                                       overflow: TextOverflow.ellipsis,
//                                                       style: const TextStyle(
//                                                         color: premiumTextColor,
//                                                         fontWeight: FontWeight.w600,
//                                                         fontSize: 14,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 4),
//                                                     Text(
//                                                       '₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
//                                                       style: const TextStyle(
//                                                         color: Colors.green,
//                                                         fontWeight: FontWeight.w600,
//                                                         fontSize: 14,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 4),
//                                                     Text(
//                                                       product['sellers']?['store_name'] ?? 'Unknown Seller',
//                                                       style: const TextStyle(
//                                                         color: premiumSecondaryTextColor,
//                                                         fontSize: 12,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 8),
//                                                     Row(
//                                                       children: [
//                                                         Expanded(
//                                                           child: ElevatedButton(
//                                                             onPressed: isOutOfStock
//                                                                 ? null
//                                                                 : () => _addToCart(product),
//                                                             style: ElevatedButton.styleFrom(
//                                                               backgroundColor: premiumPrimaryColor,
//                                                               padding: const EdgeInsets.symmetric(vertical: 8),
//                                                               shape: RoundedRectangleBorder(
//                                                                 borderRadius: BorderRadius.circular(12),
//                                                               ),
//                                                               elevation: 2,
//                                                             ),
//                                                             child: const Text(
//                                                               'Add to Cart',
//                                                               style: TextStyle(
//                                                                 fontSize: 12,
//                                                                 color: Colors.white,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         const SizedBox(width: 8),
//                                                         Expanded(
//                                                           child: OutlinedButton(
//                                                             onPressed: isOutOfStock
//                                                                 ? null
//                                                                 : () => _addToCart(product, goToCart: true),
//                                                             style: OutlinedButton.styleFrom(
//                                                               side: const BorderSide(
//                                                                 color: premiumPrimaryColor,
//                                                                 width: 1.5,
//                                                               ),
//                                                               padding: const EdgeInsets.symmetric(vertical: 8),
//                                                               shape: RoundedRectangleBorder(
//                                                                 borderRadius: BorderRadius.circular(12),
//                                                               ),
//                                                             ),
//                                                             child: const Text(
//                                                               'Buy Now',
//                                                               style: TextStyle(
//                                                                 fontSize: 12,
//                                                                 color: premiumPrimaryColor,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           if (isOutOfStock)
//                                             Positioned(
//                                               top: 8,
//                                               right: 8,
//                                               child: Container(
//                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.redAccent,
//                                                   borderRadius: BorderRadius.circular(12),
//                                                 ),
//                                                 child: const Text(
//                                                   'Out of Stock',
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                     fontSize: 12,
//                                                     fontWeight: FontWeight.bold,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ],
//                   ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';

// /// ------------------------------------------------------------
// /// Premium color palette – keep UI consistent across the app
// /// ------------------------------------------------------------
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740);  // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// /// ProductsPage – lists all products or products in a category
// /// ------------------------------------------------------------
// /// * Supports optional [categoryId] param (String UUID / int id)
// /// * Search bar with 300‑ms debounce
// /// * Pull‑to‑refresh & graceful error handling
// /// * Add‑to‑cart + Buy‑now buttons (integrates with AppState)
// /// ------------------------------------------------------------
// class ProductsPage extends StatefulWidget {
//   /// Category id (nullable). When null, page shows all approved products.
//   final String? categoryId;
//   const ProductsPage({super.key, this.categoryId});

//   @override
//   State<ProductsPage> createState() => _ProductsPageState();
// }

// class _ProductsPageState extends State<ProductsPage> {
//   /* ─────────────────── DB & helpers ─────────────────── */
//   final SupabaseClient _spb = Supabase.instance.client;

//   /* ─────────────────── UI state ─────────────────────── */
//   List<Map<String, dynamic>> _products = []; // mapped rows
//   String _categoryName = 'Products';
//   bool _loading = true;
//   String? _error; // store error string (null = no error)
//   String _search = '';
//   Timer? _debounce; // for search bar

//   /* ─────────────────── Lifecycle ────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   /* ─────────────────── Data fetch ───────────────────── */
//   Future<void> _loadProducts() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       /* 1️⃣  Fetch category name (if any) */
//       if (widget.categoryId != null) {
//         final catRes = await _spb
//             .from('categories')
//             .select('name')
//             .eq('id', int.parse(widget.categoryId!))
//             .maybeSingle();
//         if (catRes != null) {
//           _categoryName = catRes['name'] as String? ?? 'Products';
//         }
//       }

//       /* 2️⃣  Fetch products (approved only) */
//       var query = _spb
//           .from('products')
//           .select('id, title, price, images, stock, sellers(store_name)')
//           .eq('is_approved', true);

//       if (widget.categoryId != null) {
//         query = query.eq('category_id', int.parse(widget.categoryId!));
//       }

//       final res = await query.order('title');
//       _products = res.cast<Map<String, dynamic>>();
//     } catch (e) {
//       _error = 'Error fetching products: $e';
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   /* ─────────────────── Cart logic ───────────────────── */
//   Future<void> _addToCart(
//     Map<String, dynamic> product, {
//     bool goToCart = false,
//   }) async {
//     final app = context.read<AppState>();
//     final uid = app.session?.user.id;

//     if (uid == null) {
//       // Prompt login
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please log in to add items to your cart'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       context.go('/auth');
//       return;
//     }

//     try {
//       // Check if cart row exists
//       final exists = await _spb
//           .from('cart')
//           .select('id, quantity')
//           .eq('user_id', uid)
//           .eq('product_id', product['id'])
//           .maybeSingle();

//       if (exists != null) {
//         // Increment quantity
//         await _spb
//             .from('cart')
//             .update({'quantity': (exists['quantity'] as int) + 1})
//             .eq('id', exists['id']);
//       } else {
//         // Insert new row
//         await _spb.from('cart').insert({
//           'user_id': uid,
//           'product_id': product['id'],
//           'quantity': 1,
//           'price': product['price'],
//         });
//       }

//       await app.refreshCartCount();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Added to cart'), backgroundColor: Colors.green),
//       );

//       if (goToCart) context.go('/cart');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding to cart: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }

//   /* ─────────────────── Build UI ─────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     // Filter products by search query
//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String)
//                 .toLowerCase()
//                 .contains(_search.toLowerCase()))
//             .toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: _buildAppBar(),
//       body: RefreshIndicator(
//         onRefresh: _loadProducts,
//         color: premiumPrimaryColor,
//         child: _loading
//             ? const Center(
//                 child: CircularProgressIndicator(color: premiumPrimaryColor),
//               )
//             : _error != null
//                 ? _buildErrorState()
//                 : _buildProductGrid(filtered),
//       ),
//     );
//   }

//   /* ─────────────────── Widgets ──────────────────────── */

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         _categoryName,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       backgroundColor: premiumPrimaryColor,
//       elevation: 4,
//       shadowColor: Colors.black.withOpacity(0.2),
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [premiumPrimaryColor, Color(0xFF3F51B5)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//           const SizedBox(height: 16),
//           Text(
//             _error!,
//             style: const TextStyle(
//               color: premiumTextColor,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadProducts,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//             child: const Text(
//               'Retry',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//           hintText: 'Search products…',
//           hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.grey),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
//           ),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(const Duration(milliseconds: 300), () {
//             setState(() => _search = txt.toLowerCase());
//           });
//         },
//       ),
//     );
//   }

//   Widget _buildProductGrid(List<Map<String, dynamic>> filtered) {
//     return Column(
//       children: [
//         _buildSearchBar(),
//         Expanded(
//           child: filtered.isEmpty
//               ? const Center(
//                   child: Text('No products found.',
//                       style: TextStyle(color: premiumTextColor)),
//                 )
//               : GridView.builder(
//                   padding: const EdgeInsets.all(12),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     childAspectRatio: 0.65,
//                     crossAxisSpacing: 12,
//                     mainAxisSpacing: 12,
//                   ),
//                   itemCount: filtered.length,
//                   itemBuilder: (context, index) {
//                     final product = filtered[index];
//                     return _buildProductCard(product);
//                   },
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProductCard(Map<String, dynamic> product) {
//     final imageUrl = (product['images'] as List?)?.isNotEmpty == true
//         ? product['images'][0]
//         : 'https://via.placeholder.com/150x150?text=Product';
//     final isOutOfStock = product['stock'] == null || product['stock'] == 0;

//     return InkWell(
//       onTap: () => context.go('/products/${product['id']}'),
//       borderRadius: BorderRadius.circular(12),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: premiumCardColor,
//         child: Stack(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Image
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius:
//                         const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Center(
//                           child: CircularProgressIndicator(
//                             color: premiumPrimaryColor,
//                             strokeWidth: 2,
//                           ),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) => const Icon(
//                         Icons.broken_image,
//                         color: premiumSecondaryTextColor,
//                         size: 50,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Details + buttons
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Title
//                       Text(
//                         product['title'] ?? 'Unknown Product',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // Price
//                       Text(
//                         '₹${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // Seller name
//                       Text(
//                         product['sellers']?['store_name'] ?? 'Unknown Seller',
//                         style: const TextStyle(
//                           color: premiumSecondaryTextColor,
//                           fontSize: 12,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       // Buttons
//                       Row(
//                         children: [
//                           // Add to cart
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed:
//                                   isOutOfStock ? null : () => _addToCart(product),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: premiumPrimaryColor,
//                                 padding: const EdgeInsets.symmetric(vertical: 8),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: const Text(
//                                 'Add to Cart',
//                                 style: TextStyle(fontSize: 12, color: Colors.white),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // Buy now
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: isOutOfStock
//                                   ? null
//                                   : () => _addToCart(product, goToCart: true),
//                               style: OutlinedButton.styleFrom(
//                                 side: const BorderSide(
//                                   color: premiumPrimaryColor,
//                                   width: 1.5,
//                                 ),
//                                 padding: const EdgeInsets.symmetric(vertical: 8),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Buy Now',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: premiumPrimaryColor,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             // Stock badge
//             if (isOutOfStock)
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.redAccent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Text(
//                     'Out of Stock',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart'; // Ensure this path is correct

// /// ------------------------------------------------------------
// /// Premium color palette – keep UI consistent across the app
// /// ------------------------------------------------------------
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740);  // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// /// ProductsPage – lists all products or products in a category
// /// ------------------------------------------------------------
// /// * Supports optional [categoryId] param (String UUID / int id)
// /// * Search bar with 300‑ms debounce
// /// * Pull‑to‑refresh & graceful error handling
// /// * Add‑to‑cart + Buy‑now buttons (integrates with AppState)
// /// ------------------------------------------------------------
// class ProductsPage extends StatefulWidget {
//   /// Category id (nullable). When null, page shows all approved products.
//   final String? categoryId;
//   const ProductsPage({super.key, this.categoryId});

//   @override
//   State<ProductsPage> createState() => _ProductsPageState();
// }

// class _ProductsPageState extends State<ProductsPage> {
//   /* ─────────────────── DB & helpers ─────────────────── */
//   final SupabaseClient _spb = Supabase.instance.client;

//   /* ─────────────────── UI state ─────────────────────── */
//   List<Map<String, dynamic>> _products = []; // mapped rows
//   String _categoryName = 'Products';
//   bool _loading = true;
//   String? _error; // store error string (null = no error)
//   String _search = '';
//   Timer? _debounce; // for search bar

//   /* ─────────────────── Lifecycle ────────────────────── */
//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   /* ─────────────────── Data fetch ───────────────────── */
//   Future<void> _loadProducts() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       /* 1️⃣  Fetch category name (if any) */
//       if (widget.categoryId != null) {
//         final catRes = await _spb
//             .from('categories')
//             .select('name')
//             .eq('id', int.parse(widget.categoryId!))
//             .maybeSingle();
//         if (catRes != null) {
//           _categoryName = catRes['name'] as String? ?? 'Products';
//         }
//       }

//       /* 2️⃣  Fetch products (approved only) */
//       var query = _spb
//           .from('products')
//           .select('id, title, price, images, stock, sellers(store_name)')
//           .eq('is_approved', true);

//       if (widget.categoryId != null) {
//         query = query.eq('category_id', int.parse(widget.categoryId!));
//       }

//       final res = await query.order('title');
//       _products = res.cast<Map<String, dynamic>>();
//     } catch (e) {
//       _error = 'Error fetching products: $e';
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   /* ─────────────────── Cart logic ───────────────────── */
//   Future<void> _addToCart(
//     Map<String, dynamic> product, {
//     bool goToCart = false,
//   }) async {
//     final app = context.read<AppState>();
//     final uid = app.session?.user.id;

//     if (uid == null) {
//       // Prompt login
//       if (mounted) { // Check if widget is still in tree before showing SnackBar or navigating
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please log in to add items to your cart'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         context.go('/auth');
//       }
//       return;
//     }

//     try {
//       // Check if cart row exists
//       final exists = await _spb
//           .from('cart')
//           .select('id, quantity')
//           .eq('user_id', uid)
//           .eq('product_id', product['id'])
//           .maybeSingle();

//       if (exists != null) {
//         // Increment quantity
//         await _spb
//             .from('cart')
//             .update({'quantity': (exists['quantity'] as int) + 1})
//             .eq('id', exists['id']);
//       } else {
//         // Insert new row
//         await _spb.from('cart').insert({
//           'user_id': uid,
//           'product_id': product['id'],
//           'quantity': 1,
//           'price': product['price'],
//         });
//       }

//       await app.refreshCartCount();

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Added to cart'), backgroundColor: Colors.green),
//         );

//         if (goToCart) context.go('/cart');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error adding to cart: $e'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   /* ─────────────────── Build UI ─────────────────────── */
//   @override
//   Widget build(BuildContext context) {
//     // Filter products by search query
//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String)
//                 .toLowerCase()
//                 .contains(_search.toLowerCase()))
//             .toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: _buildAppBar(),
//       body: RefreshIndicator(
//         onRefresh: _loadProducts,
//         color: premiumPrimaryColor,
//         child: _loading
//             ? const Center(
//                 child: CircularProgressIndicator(color: premiumPrimaryColor),
//               )
//             : _error != null
//                 ? _buildErrorState()
//                 : _buildProductGrid(filtered),
//       ),
//     );
//   }

//   /* ─────────────────── Widgets ──────────────────────── */

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: Text(
//         _categoryName,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 20,
//         ),
//       ),
//       backgroundColor: premiumPrimaryColor,
//       elevation: 4,
//       shadowColor: Colors.black.withOpacity(0.2),
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [premiumPrimaryColor, Color(0xFF3F51B5)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//       actions: [
//         // Example: Cart button with count
//         Consumer<AppState>(
//           builder: (context, appState, child) {
//             return Stack(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.shopping_cart, color: Colors.white),
//                   onPressed: () => context.go('/cart'),
//                 ),
//                 if (appState.cartCount > 0)
//                   Positioned(
//                     right: 8,
//                     top: 8,
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(
//                         color: premiumAccentColor,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       constraints: const BoxConstraints(
//                         minWidth: 16,
//                         minHeight: 16,
//                       ),
//                       child: Text(
//                         '${appState.cartCount}',
//                         style: const TextStyle(
//                           color: premiumPrimaryColor,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//               ],
//             );
//           },
//         ),
//         // Example: User profile/login button
//         IconButton(
//           icon: const Icon(Icons.person, color: Colors.white),
//           onPressed: () => context.go('/auth'), // Navigate to auth page
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//           const SizedBox(height: 16),
//           Text(
//             _error!,
//             style: const TextStyle(
//               color: premiumTextColor,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadProducts,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//             child: const Text(
//               'Retry',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//           hintText: 'Search products…',
//           hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.grey),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
//           ),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(const Duration(milliseconds: 300), () {
//             // Using setState to trigger rebuild with filtered results
//             setState(() => _search = txt.toLowerCase());
//           });
//         },
//       ),
//     );
//   }

//   Widget _buildProductGrid(List<Map<String, dynamic>> filtered) {
//     return Column(
//       children: [
//         _buildSearchBar(),
//         Expanded(
//           child: filtered.isEmpty
//               ? const Center(
//                   child: Text('No products found.',
//                       style: TextStyle(color: premiumTextColor)),
//                 )
//               : GridView.builder(
//                   padding: const EdgeInsets.all(12),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     childAspectRatio: 0.65, // Adjust based on your product card layout
//                     crossAxisSpacing: 12,
//                     mainAxisSpacing: 12,
//                   ),
//                   itemCount: filtered.length,
//                   itemBuilder: (context, index) {
//                     final product = filtered[index];
//                     return _buildProductCard(product);
//                   },
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProductCard(Map<String, dynamic> product) {
//     final imageUrl = (product['images'] as List?)?.isNotEmpty == true
//         ? product['images'][0]
//         : 'https://via.placeholder.com/150x150?text=Product';
//     final isOutOfStock = product['stock'] == null || product['stock'] == 0;

//     return InkWell(
//       onTap: () => context.go('/products/${product['id']}'),
//       borderRadius: BorderRadius.circular(12),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: premiumCardColor,
//         child: Stack(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Image
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius:
//                         const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Center(
//                           child: CircularProgressIndicator(
//                             color: premiumPrimaryColor,
//                             strokeWidth: 2,
//                           ),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) => const Icon(
//                         Icons.broken_image,
//                         color: premiumSecondaryTextColor,
//                         size: 50,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Details + buttons
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Title
//                       Text(
//                         product['title'] ?? 'Unknown Product',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // Price
//                       Text(
//                         '₹${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // Seller name
//                       Text(
//                         product['sellers']?['store_name'] ?? 'Unknown Seller',
//                         style: const TextStyle(
//                           color: premiumSecondaryTextColor,
//                           fontSize: 12,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       // Buttons
//                       Row(
//                         children: [
//                           // Add to cart
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed:
//                                   isOutOfStock ? null : () => _addToCart(product),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: premiumPrimaryColor,
//                                 padding: const EdgeInsets.symmetric(vertical: 8),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: const Text(
//                                 'Add to Cart',
//                                 style: TextStyle(fontSize: 12, color: Colors.white),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // Buy now
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: isOutOfStock
//                                   ? null
//                                   : () => _addToCart(product, goToCart: true),
//                               style: OutlinedButton.styleFrom(
//                                 side: const BorderSide(
//                                   color: premiumPrimaryColor,
//                                   width: 1.5,
//                                 ),
//                                 padding: const EdgeInsets.symmetric(vertical: 8),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Buy Now',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: premiumPrimaryColor,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             // Stock badge
//             if (isOutOfStock)
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.redAccent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Text(
//                     'Out of Stock',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../state/app_state.dart'; // Ensure this path is correct

/// ------------------------------------------------------------
/// Premium color palette – keep UI consistent across the app
/// ------------------------------------------------------------
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumAccentColor = Color(0xFFFFD740);  // Gold
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey
const premiumErrorColor = Color(0xFFEF4444);
const premiumSuccessColor = Color(0xFF2ECC71);

/// ProductsPage – lists all products or products in a category
/// ------------------------------------------------------------
/// * Supports optional [categoryId] param (String UUID / int id)
/// * Search bar with 300‑ms debounce
/// * Pull‑to‑refresh & graceful error handling
/// * Add‑to‑cart + Buy‑now buttons (integrates with AppState)
/// * Handles no internet connection with caching and toast feedback
/// * Robust navigation handling to prevent back dispatcher issues
/// ------------------------------------------------------------
class ProductsPage extends StatefulWidget {
  final String? categoryId;
  const ProductsPage({super.key, this.categoryId});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  /* ─────────────────── DB & helpers ─────────────────── */
  final SupabaseClient _spb = Supabase.instance.client;
  late final SharedPreferences _prefs;
  String get _cacheKey => widget.categoryId != null ? 'products_cache_${widget.categoryId}' : 'products_cache';
  String get _categoryCacheKey => widget.categoryId != null ? 'category_name_${widget.categoryId}' : 'category_name_all';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /* ─────────────────── UI state ─────────────────────── */
  List<Map<String, dynamic>> _products = [];
  String _categoryName = 'Products';
  bool _loading = true;
  String? _error;
  String _search = '';
  Timer? _debounce;
  bool _isConnected = true;

  /* ─────────────────── Lifecycle ────────────────────── */
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    print('ProductsPage: Initializing');
    _prefs = await SharedPreferences.getInstance();
    print('ProductsPage: SharedPreferences initialized');
    _isConnected = await _checkNetworkStatus(); // Initial connectivity check
    _setupConnectivityListener();
    await _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectivitySubscription?.cancel();
    Fluttertoast.cancel(); // Cancel any pending toasts
    print('ProductsPage: Disposed');
    super.dispose();
  }

  /* ─────────────────── Helpers ──────────────────────── */
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      print('ProductsPage: Connectivity changed - isOnline: $isOnline, results: $results');
      if (_isConnected != isOnline && mounted) {
        setState(() => _isConnected = isOnline);
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: isOnline
              ? 'Internet connection restored.'
              : 'No internet connection detected. Showing cached data.',
          backgroundColor: isOnline ? premiumSuccessColor : premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3, // Longer duration for visibility
        );
        await _loadProducts();
      }
    });
  }

  Future<bool> _checkNetworkStatus() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      print('ProductsPage: checkNetworkStatus - isOnline: $isOnline, result: $connectivityResult');
      if (mounted) setState(() => _isConnected = isOnline);
      if (!isOnline && mounted) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: 'No internet connection. Please check your network and try again.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
        );
      }
      return isOnline;
    } catch (e) {
      print('ProductsPage: Error checking network status: $e');
      if (mounted) setState(() => _isConnected = false);
      if (mounted) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: 'Error checking network status: $e',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
        );
      }
      return false;
    }
  }

  /* ─────────────────── Data fetch & caching ─────────── */
  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('ProductsPage: Loading products, isConnected: $_isConnected');
      if (!(await _checkNetworkStatus())) {
        print('ProductsPage: Offline, checking cache');
        final cachedData = _prefs.getString(_cacheKey);
        final cachedCategoryName = _prefs.getString(_categoryCacheKey);
        if (cachedData != null) {
          _products = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
          _categoryName = cachedCategoryName ?? (widget.categoryId != null ? 'Cached Category' : 'Cached Products');
          setState(() {
            _loading = false;
            _error = 'No internet connection. Showing cached data.';
          });
          print('ProductsPage: Loaded cached products: ${_products.length} items');
          return;
        } else {
          throw Exception('No internet connection and no cached data available.');
        }
      }

      print('ProductsPage: Fetching fresh data');
      /* 1️⃣ Fetch category name (if any) */
      if (widget.categoryId != null) {
        final catRes = await _spb
            .from('categories')
            .select('name')
            .eq('id', int.parse(widget.categoryId!))
            .maybeSingle();
        if (catRes != null) {
          _categoryName = catRes['name'] as String? ?? 'Products';
          await _prefs.setString(_categoryCacheKey, _categoryName);
          print('ProductsPage: Category name fetched: $_categoryName');
        }
      } else {
        _categoryName = 'Products';
        await _prefs.setString(_categoryCacheKey, _categoryName);
      }

      /* 2️⃣ Fetch products (approved only) */
      var query = _spb
          .from('products')
          .select('id, title, price, images, stock, sellers(store_name)')
          .eq('is_approved', true);

      if (widget.categoryId != null) {
        query = query.eq('category_id', int.parse(widget.categoryId!));
      }

      final res = await query.order('title');
      _products = res.cast<Map<String, dynamic>>();

      // Cache the products
      await _prefs.setString(_cacheKey, jsonEncode(_products));
      print('ProductsPage: Products fetched: ${_products.length} items');
    } catch (e) {
      print('ProductsPage: Error in _loadProducts: $e');
      final cachedData = _prefs.getString(_cacheKey);
      final cachedCategoryName = _prefs.getString(_categoryCacheKey);
      if (cachedData != null) {
        _products = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
        _categoryName = cachedCategoryName ?? (widget.categoryId != null ? 'Cached Category' : 'Cached Products');
        _error = 'Failed to fetch products. Showing cached data.';
        print('ProductsPage: Loaded cached products: ${_products.length} items');
      } else {
        _error = e.toString().contains('Network') || e is SocketException || e is PostgrestException
            ? 'Network error. Please check your connection.'
            : 'Error fetching products: $e';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ─────────────────── Cart logic ───────────────────── */
  Future<void> _addToCart(Map<String, dynamic> product, {bool goToCart = false}) async {
    if (!_isConnected) {
      print('ProductsPage: Add to cart blocked - offline');
      if (mounted) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: 'No internet connection. Please check your network.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
        );
      }
      return;
    }

    final app = context.read<AppState>();
    final uid = app.session?.user.id;

    if (uid == null) {
      print('ProductsPage: Add to cart - user not logged in');
      if (mounted) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: 'Please log in to add items to your cart',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
        );
        context.push('/auth');
      }
      return;
    }

    try {
      final exists = await _spb
          .from('cart')
          .select('id, quantity')
          .eq('user_id', uid)
          .eq('product_id', product['id'])
          .maybeSingle();

      if (exists != null) {
        await _spb
            .from('cart')
            .update({'quantity': (exists['quantity'] as int) + 1})
            .eq('id', exists['id']);
        print('ProductsPage: Updated cart item quantity');
      } else {
        await _spb.from('cart').insert({
          'user_id': uid,
          'product_id': product['id'],
          'quantity': 1,
          'price': product['price'],
        });
        print('ProductsPage: Added new item to cart');
      }

      await app.refreshCartCount();

      if (mounted) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: 'Added to cart',
          backgroundColor: premiumSuccessColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
        );

        if (goToCart) context.push('/cart');
      }
    } catch (e) {
      print('ProductsPage: Error adding to cart: $e');
      if (mounted) {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: 'Error adding to cart: $e',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
        );
      }
    }
  }

  /* ─────────────────── Build UI ─────────────────────── */
  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _products
        : _products
            .where((p) => (p['title'] as String).toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          print('ProductsPage: Back navigation triggered');
          _debounce?.cancel();
          Fluttertoast.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: premiumBackgroundColor,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: _loadProducts,
          color: premiumPrimaryColor,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: premiumPrimaryColor))
              : _error != null
                  ? _buildErrorState()
                  : _buildProductGrid(filtered),
        ),
      ),
    );
  }

  /* ─────────────────── Widgets ──────────────────────── */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _categoryName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: premiumPrimaryColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [premiumPrimaryColor, Color(0xFF3F51B5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        Consumer<AppState>(
          builder: (context, appState, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () => context.push('/cart'),
                ),
                if (appState.cartCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: premiumAccentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${appState.cartCount}',
                        style: const TextStyle(
                          color: premiumPrimaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () => context.push('/auth'),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: premiumErrorColor, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              color: premiumTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProducts,
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
          hintText: 'Search products…',
          hintStyle: const TextStyle(color: premiumSecondaryTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (txt) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            setState(() => _search = txt.toLowerCase());
          });
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> filtered) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products found.', style: TextStyle(color: premiumTextColor)))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrl = (product['images'] as List?)?.isNotEmpty == true
        ? product['images'][0]
        : 'https://via.placeholder.com/150x150?text=Product';
    final isOutOfStock = product['stock'] == null || product['stock'] == 0;

    return InkWell(
      onTap: () => context.push('/products/${product['id']}'),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: premiumCardColor,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: premiumPrimaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        color: premiumSecondaryTextColor,
                        size: 50,
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
                        product['title'] ?? 'Unknown Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: premiumTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: premiumSuccessColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['sellers']?['store_name'] ?? 'Unknown Seller',
                        style: const TextStyle(
                          color: premiumSecondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isOutOfStock || !_isConnected
                                  ? () {
                                      if (!_isConnected && mounted) {
                                        Fluttertoast.cancel();
                                        Fluttertoast.showToast(
                                          msg: 'No internet connection. Please check your network.',
                                          backgroundColor: premiumErrorColor,
                                          textColor: Colors.white,
                                          fontSize: 15,
                                          toastLength: Toast.LENGTH_LONG,
                                          gravity: ToastGravity.TOP,
                                          timeInSecForIosWeb: 3,
                                        );
                                      }
                                    }
                                  : () => _addToCart(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: premiumPrimaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isOutOfStock || !_isConnected
                                  ? () {
                                      if (!_isConnected && mounted) {
                                        Fluttertoast.cancel();
                                        Fluttertoast.showToast(
                                          msg: 'No internet connection. Please check your network.',
                                          backgroundColor: premiumErrorColor,
                                          textColor: Colors.white,
                                          fontSize: 15,
                                          toastLength: Toast.LENGTH_LONG,
                                          gravity: ToastGravity.TOP,
                                          timeInSecForIosWeb: 3,
                                        );
                                      }
                                    }
                                  : () => _addToCart(product, goToCart: true),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: premiumPrimaryColor,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Buy Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: premiumPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOutOfStock)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: premiumErrorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Out of Stock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}