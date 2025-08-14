// // lib/pages/home_page.dart
// import 'dart:async';
// import 'dart:math' as math;

// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';

// const kRadiusKm = 40.0;        // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _spb = Supabase.instance.client;

//   // data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<String> _banners = [];

//   // ui
//   bool _loading = true;
//   String _search = '';
//   Timer? _debounce;

//   // ─── helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty) return 1e9;
//     if (b['latitude'] == null || b['longitude'] == null) return 1e9;

//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     // If emulator still reports Mountain View, swap to Bengaluru so you see items.
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   // ─── load everything ──────────────────────────────────────────────────────
//   Future<void> _loadEverything() async {
//     final app = context.read<AppState>();

//     if (app.buyerLocation == null) return; // wait for ensureBuyerLocation()
//     final buyer = _sanitiseCoords(app.buyerLocation!);

//     setState(() => _loading = true);

//     // categories
//     _categories = (await _spb.from('categories').select().order('name').limit(6))
//         .cast<Map<String, dynamic>>();

//     // banners
//     final files = await _spb.storage.from('banner-images').list(path: '');
//     _banners = files
//         .where((f) => f.name.endsWith('.png') || f.name.endsWith('.jpg'))
//         .map((f) => _spb.storage.from('banner-images').getPublicUrl(f.name))
//         .cast<String>()
//         .toList();

//     // sellers near me
//     final sellers = (await _spb
//             .from('sellers')
//             .select('id, latitude, longitude'))
//         .cast<Map<String, dynamic>>();

//     final nearIds = sellers
//         .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//         .map((s) => s['id'])
//         .toList();

//     // products
//     if (nearIds.isNotEmpty) {
//       _products = (await _spb
//               .from('products')
//               .select('id,title,price,images,stock')
//               .inFilter('seller_id', nearIds)
//               .eq('is_approved', true))
//           .cast<Map<String, dynamic>>();
//     } else {
//       // fallback: show some items so the UI isn’t blank
//       _products = (await _spb
//               .from('products')
//               .select('id,title,price,images,stock')
//               .eq('is_approved', true)
//               .limit(20))
//           .cast<Map<String, dynamic>>();
//     }

//     if (mounted) setState(() => _loading = false);
//   }

//   // ─── lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     context.read<AppState>().ensureBuyerLocation().then((_) => _loadEverything());
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ─── ui ────────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     if (!app.locationReady) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) =>
//                 (p['title'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Markeet')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: _loadEverything,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // SEARCH
//                     TextField(
//                       decoration: const InputDecoration(
//                         prefixIcon: Icon(Icons.search),
//                         hintText: 'Search products…',
//                       ),
//                       onChanged: (txt) {
//                         _debounce?.cancel();
//                         _debounce = Timer(
//                           const Duration(milliseconds: 300),
//                           () => setState(() => _search = txt.toLowerCase()),
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 20),

//                     // BANNERS
//                     if (_banners.isNotEmpty)
//                       CarouselSlider(
//                         items: _banners
//                             .map((u) => ClipRRect(
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: Image.network(u,
//                                       fit: BoxFit.cover, width: double.infinity),
//                                 ))
//                             .toList(),
//                         options: CarouselOptions(
//                           height: 160, autoPlay: true, viewportFraction: 1),
//                       ),
//                     const SizedBox(height: 24),

//                     // CATEGORIES
//                     Text('Categories',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     GridView.count(
//                       crossAxisCount: 3,
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       childAspectRatio: .8,
//                       children: _categories
//                           .map((c) => Column(
//                                 children: [
//                                   Expanded(
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(8),
//                                       child: Image.network(
//                                         c['image_url'] ??
//                                             'https://dummyimage.com/150',
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(c['name'],
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis),
//                                 ],
//                               ))
//                           .toList(),
//                     ),
//                     const SizedBox(height: 24),

//                     // PRODUCTS
//                     Text('Products nearby',
//                         style: Theme.of(context).textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     if (filtered.isEmpty)
//                       const Text('No products found.')
//                     else
//                       GridView.count(
//                         crossAxisCount: 2,
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         childAspectRatio: .62,
//                         children: filtered
//                             .map((p) => Card(
//                                   child: InkWell(
//                                     onTap: () => context.go('/product/${p['id']}'),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Expanded(
//                                           child: ClipRRect(
//                                             borderRadius:
//                                                 BorderRadius.circular(8),
//                                             child: Image.network(
//                                               (p['images'] as List).isNotEmpty
//                                                   ? p['images'][0]
//                                                   : 'https://dummyimage.com/150',
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 6),
//                                         Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 6),
//                                           child: Text(p['title'],
//                                               maxLines: 2,
//                                               overflow: TextOverflow.ellipsis),
//                                         ),
//                                         Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 6),
//                                           child: Text(
//                                             '₹${p['price']}',
//                                             style: const TextStyle(
//                                                 fontWeight: FontWeight.bold),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.spaceEvenly,
//                                           children: [
//                                             TextButton(
//                                               onPressed: app.session == null
//                                                   ? null
//                                                   : () async {
//                                                       await _spb
//                                                           .from('cart')
//                                                           .insert({
//                                                         'user_id': app
//                                                             .session!.user.id,
//                                                         'product_id': p['id'],
//                                                         'quantity': 1,
//                                                         'price': p['price'],
//                                                       });
//                                                       ScaffoldMessenger.of(
//                                                               context)
//                                                           .showSnackBar(SnackBar(
//                                                               content: Text(
//                                                                   '${p['title']} added to cart')));
//                                                       await app
//                                                           .refreshCartCount();
//                                                     },
//                                               child: const Text('Add to cart'),
//                                             ),
//                                             TextButton(
//                                               onPressed: () =>
//                                                   context.go('/cart'),
//                                               child: const Text('Buy now'),
//                                             ),
//                                           ],
//                                         )
//                                       ],
//                                     ),
//                                   ),
//                                 ))
//                             .toList(),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }




// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';

// const kRadiusKm = 40.0; // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<String> _banners = [];

//   // UI
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;
//   int _currentBannerIndex = 0;

//   // ─── Helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty) return 1e9;
//     if (b['latitude'] == null || b['longitude'] == null) return 1e9;

//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     // If emulator still reports Mountain View, swap to Bengaluru so you see items.
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   // ─── Load Everything ──────────────────────────────────────────────────────
//   Future<void> _loadEverything() async {
//     final app = context.read<AppState>();

//     if (app.buyerLocation == null) return; // Wait for ensureBuyerLocation()
//     final buyer = _sanitiseCoords(app.buyerLocation!);

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       // Categories
//       _categories = (await _spb.from('categories').select().order('name').limit(6))
//           .cast<Map<String, dynamic>>();

//       // Banners
//       final files = await _spb.storage.from('banner-images').list(path: '');
//       _banners = files
//           .where((f) => f.name.endsWith('.png') || f.name.endsWith('.jpg'))
//           .map((f) => _spb.storage.from('banner-images').getPublicUrl(f.name))
//           .cast<String>()
//           .toList();

//       // Sellers near me
//       final sellers = (await _spb.from('sellers').select('id, latitude, longitude'))
//           .cast<Map<String, dynamic>>();

//       final nearIds = sellers
//           .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//           .map((s) => s['id'])
//           .toList();

//       // Products
//       if (nearIds.isNotEmpty) {
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .inFilter('seller_id', nearIds)
//                 .eq('is_approved', true))
//             .cast<Map<String, dynamic>>();
//       } else {
//         // Fallback: Show some items so the UI isn’t blank
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .eq('is_approved', true)
//                 .limit(20))
//             .cast<Map<String, dynamic>>();
//       }
//     } catch (e) {
//       setState(() => _error = 'Failed to load data: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── Lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     context.read<AppState>().ensureBuyerLocation().then((_) => _loadEverything());
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ─── UI Helpers ───────────────────────────────────────────────────────────
//   Widget _buildShimmer({required double height, required double width}) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         height: height,
//         width: width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red, size: 48),
//           const SizedBox(height: 8),
//           Text(
//             _error ?? 'Something went wrong',
//             style: const TextStyle(fontSize: 16, color: Colors.red),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadEverything,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             child: const Text('Retry', style: TextStyle(fontSize: 16)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: Colors.grey),
//           hintText: 'Search products…',
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(
//             const Duration(milliseconds: 300),
//             () => setState(() => _search = txt.toLowerCase()),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBanners() {
//     if (_loading) {
//       return Shimmer.fromColors(
//         baseColor: Colors.grey[300]!,
//         highlightColor: Colors.grey[100]!,
//         child: Container(
//           height: 160,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     }

//     if (_banners.isEmpty) {
//       return Container(
//         height: 160,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(child: Text('No banners available')),
//       );
//     }

//     return Column(
//       children: [
//         CarouselSlider(
//           items: _banners
//               .map((u) => ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: CachedNetworkImage(
//                       imageUrl: u,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder: (context, url) => _buildShimmer(height: 160, width: double.infinity),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[300],
//                         child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                       ),
//                     ),
//                   ))
//               .toList(),
//           options: CarouselOptions(
//             height: 160,
//             autoPlay: true,
//             viewportFraction: 1,
//             autoPlayInterval: const Duration(seconds: 3),
//             onPageChanged: (index, reason) {
//               setState(() => _currentBannerIndex = index);
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _banners.asMap().entries.map((entry) {
//             return Container(
//               width: 8,
//               height: 8,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _currentBannerIndex == entry.key ? Colors.blueAccent : Colors.grey[400],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories() {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           6,
//           (_) => _buildShimmer(height: 80, width: 80),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return const Text('No categories available.');
//     }

//     return GridView.count(
//       crossAxisCount: 3,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.8,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: _categories.map((c) {
//         return GestureDetector(
//           onTap: () => context.go('/category/${c['id']}'), // Assuming category navigation
//           child: Column(
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: ClipOval(
//                     child: CachedNetworkImage(
//                       imageUrl: c['image_url'] ?? 'https://dummyimage.com/150',
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => _buildShimmer(height: 80, width: 80),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[300],
//                         child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 c['name'],
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProducts(List<Map<String, dynamic>> filtered) {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           4,
//           (_) => _buildShimmer(height: 200, width: double.infinity),
//         ),
//       );
//     }

//     if (filtered.isEmpty) {
//       return const Center(child: Text('No products found.'));
//     }

//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.65,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: filtered.map((p) {
//         final isLowStock = (p['stock'] as int) <= 5;
//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: InkWell(
//             onTap: () => context.go('/product/${p['id']}'),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                         child: CachedNetworkImage(
//                           imageUrl: (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://dummyimage.com/150',
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           placeholder: (context, url) => _buildShimmer(height: 120, width: double.infinity),
//                           errorWidget: (context, url, error) => Container(
//                             color: Colors.grey[300],
//                             child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             p['title'],
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '₹${p['price'].toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               ElevatedButton(
//                                 onPressed: context.read<AppState>().session == null
//                                     ? null
//                                     : () async {
//                                         try {
//                                           await _spb.from('cart').insert({
//                                             'user_id': context.read<AppState>().session!.user.id,
//                                             'product_id': p['id'],
//                                             'quantity': 1,
//                                             'price': p['price'],
//                                           });
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(content: Text('${p['title']} added to cart')),
//                                           );
//                                           await context.read<AppState>().refreshCartCount();
//                                         } catch (e) {
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(content: Text('Error adding to cart: $e')),
//                                           );
//                                         }
//                                       },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blueAccent,
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                 ),
//                                 child: const Text(
//                                   'Add to cart',
//                                   style: TextStyle(fontSize: 12, color: Colors.white),
//                                 ),
//                               ),
//                               OutlinedButton(
//                                 onPressed: () => context.go('/cart'),
//                                 style: OutlinedButton.styleFrom(
//                                   side: const BorderSide(color: Colors.blueAccent),
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                 ),
//                                 child: const Text(
//                                   'Buy now',
//                                   style: TextStyle(fontSize: 12, color: Colors.blueAccent),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (isLowStock)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.redAccent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Text(
//                         'Low Stock',
//                         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // ─── UI ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     if (!app.locationReady) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Markeet'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.account_circle),
//               onPressed: () => context.go(app.session == null ? '/auth' : '/account'),
//             ),
//           ],
//         ),
//         body: _buildErrorWidget(),
//       );
//     }

//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Markeet'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.account_circle),
//             onPressed: () => context.go(app.session == null ? '/auth' : '/account'),
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadEverything,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // SEARCH
//               _buildSearchBar(),
//               const SizedBox(height: 24),

//               // BANNERS
//               _buildBanners(),
//               const SizedBox(height: 24),

//               // CATEGORIES
//               Text('Categories', style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 12),
//               _buildCategories(),
//               const SizedBox(height: 24),

//               // PRODUCTS
//               Text('Products nearby', style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 12),
//               _buildProducts(filtered),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';
// import '../widgets/header.dart'; // Updated import path
// import '../widgets/footer.dart'; // Updated import path (renamed from footer_nav.dart)

// // Define the same premium color palette as OrderDetailsPage for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// const kRadiusKm = 40.0; // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<String> _banners = [];

//   // UI
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;
//   int _currentBannerIndex = 0;
//   String? _userName; // To display user's name in the drawer

//   // ─── Helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty) return 1e9;
//     if (b['latitude'] == null || b['longitude'] == null) return 1e9;

//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     // If emulator still reports Mountain View, swap to Bengaluru so you see items.
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   // ─── Load Everything ──────────────────────────────────────────────────────
//   Future<void> _loadEverything() async {
//     final app = context.read<AppState>();

//     if (app.buyerLocation == null) return; // Wait for ensureBuyerLocation()
//     final buyer = _sanitiseCoords(app.buyerLocation!);

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       // Categories
//       _categories = (await _spb.from('categories').select().order('name').limit(6))
//           .cast<Map<String, dynamic>>();

//       // Banners
//       final files = await _spb.storage.from('banner-images').list(path: '');
//       _banners = files
//           .where((f) => f.name.endsWith('.png') || f.name.endsWith('.jpg'))
//           .map((f) => _spb.storage.from('banner-images').getPublicUrl(f.name))
//           .cast<String>()
//           .toList();

//       // Sellers near me
//       final sellers = (await _spb.from('sellers').select('id, latitude, longitude'))
//           .cast<Map<String, dynamic>>();

//       final nearIds = sellers
//           .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//           .map((s) => s['id'])
//           .toList();

//       // Products
//       if (nearIds.isNotEmpty) {
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .inFilter('seller_id', nearIds)
//                 .eq('is_approved', true))
//             .cast<Map<String, dynamic>>();
//       } else {
//         // Fallback: Show some items so the UI isn’t blank
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .eq('is_approved', true)
//                 .limit(20))
//             .cast<Map<String, dynamic>>();
//       }
//     } catch (e) {
//       setState(() => _error = 'Failed to load data: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Load user profile for drawer
//   Future<void> _loadUserProfile() async {
//     final app = context.read<AppState>();
//     if (app.session == null) return;

//     try {
//       final response = await _spb
//           .from('profiles')
//           .select('full_name')
//           .eq('id', app.session!.user.id)
//           .maybeSingle();
//       setState(() {
//         _userName = response?['full_name'] ?? 'User';
//       });
//     } catch (e) {
//       setState(() {
//         _userName = 'User';
//       });
//     }
//   }

//   // ─── Lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     context.read<AppState>().ensureBuyerLocation().then((_) {
//       _loadEverything();
//       _loadUserProfile();
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ─── UI Helpers ───────────────────────────────────────────────────────────
//   Widget _buildShimmer({required double height, required double width}) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         height: height,
//         width: width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.error_outline,
//             color: Colors.red,
//             size: 48,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _error ?? 'Something went wrong',
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.red,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadEverything,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               elevation: 4,
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
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//           hintText: 'Search products…',
//           hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         style: const TextStyle(color: premiumTextColor),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(
//             const Duration(milliseconds: 300),
//             () => setState(() => _search = txt.toLowerCase()),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBanners() {
//     if (_loading) {
//       return Shimmer.fromColors(
//         baseColor: Colors.grey[300]!,
//         highlightColor: Colors.grey[100]!,
//         child: Container(
//           height: 160,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     }

//     if (_banners.isEmpty) {
//       return Container(
//         height: 160,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(
//           child: Text(
//             'No banners available',
//             style: TextStyle(color: premiumSecondaryTextColor),
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [
//         CarouselSlider(
//           items: _banners
//               .map((u) => ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: CachedNetworkImage(
//                       imageUrl: u,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder: (context, url) => _buildShimmer(height: 160, width: double.infinity),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[300],
//                         child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                       ),
//                     ),
//                   ))
//               .toList(),
//           options: CarouselOptions(
//             height: 160,
//             autoPlay: true,
//             viewportFraction: 1,
//             autoPlayInterval: const Duration(seconds: 3),
//             onPageChanged: (index, reason) {
//               setState(() => _currentBannerIndex = index);
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _banners.asMap().entries.map((entry) {
//             return Container(
//               width: 8,
//               height: 8,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _currentBannerIndex == entry.key ? premiumPrimaryColor : Colors.grey[400],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories() {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           6,
//           (_) => _buildShimmer(height: 80, width: 80),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return const Text(
//         'No categories available.',
//         style: TextStyle(color: premiumSecondaryTextColor),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 3,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.8,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: _categories.map((c) {
//         return GestureDetector(
//           onTap: () => context.go('/categories/${c['id']}'), // Updated route to match main.dart
//           child: Column(
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: ClipOval(
//                     child: CachedNetworkImage(
//                       imageUrl: c['image_url'] ?? 'https://dummyimage.com/150',
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => _buildShimmer(height: 80, width: 80),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[300],
//                         child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 c['name'],
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: premiumTextColor,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProducts(List<Map<String, dynamic>> filtered) {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           4,
//           (_) => _buildShimmer(height: 200, width: double.infinity),
//         ),
//       );
//     }

//     if (filtered.isEmpty) {
//       return const Center(
//         child: Text(
//           'No products found.',
//           style: TextStyle(color: premiumSecondaryTextColor),
//         ),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.65,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: filtered.map((p) {
//         final isLowStock = (p['stock'] as int) <= 5;
//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           color: premiumCardColor,
//           child: InkWell(
//             onTap: () => context.go('/product/${p['id']}'),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                         child: CachedNetworkImage(
//                           imageUrl: (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://dummyimage.com/150',
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           placeholder: (context, url) => _buildShimmer(height: 120, width: double.infinity),
//                           errorWidget: (context, url, error) => Container(
//                             color: Colors.grey[300],
//                             child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             p['title'],
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: premiumTextColor,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '₹${p['price'].toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               ElevatedButton(
//                                 onPressed: context.read<AppState>().session == null
//                                     ? null
//                                     : () async {
//                                         try {
//                                           await _spb.from('cart').insert({
//                                             'user_id': context.read<AppState>().session!.user.id,
//                                             'product_id': p['id'],
//                                             'quantity': 1,
//                                             'price': p['price'],
//                                           });
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             const SnackBar(
//                                               content: Text('Added to cart'),
//                                               backgroundColor: Colors.green,
//                                             ),
//                                           );
//                                           await context.read<AppState>().refreshCartCount();
//                                         } catch (e) {
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(
//                                               content: Text('Error adding to cart: $e'),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                         }
//                                       },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: premiumPrimaryColor,
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                   elevation: 2,
//                                 ),
//                                 child: const Text(
//                                   'Add to cart',
//                                   style: TextStyle(fontSize: 12, color: Colors.white),
//                                 ),
//                               ),
//                               OutlinedButton(
//                                 onPressed: () => context.go('/cart'),
//                                 style: OutlinedButton.styleFrom(
//                                   side: const BorderSide(color: premiumPrimaryColor),
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                 ),
//                                 child: const Text(
//                                   'Buy now',
//                                   style: TextStyle(fontSize: 12, color: premiumPrimaryColor),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (isLowStock)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.redAccent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Text(
//                         'Low Stock',
//                         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // Drawer Options
//   Widget _buildDrawer() {
//     final app = context.watch<AppState>();
//     final isLoggedIn = app.session != null;

//     return Drawer(
//       backgroundColor: premiumCardColor,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [premiumPrimaryColor, premiumPrimaryColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.white,
//                   child: Icon(
//                     Icons.person,
//                     size: 50,
//                     color: premiumPrimaryColor,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (isLoggedIn)
//                   Text(
//                     app.session!.user.email ?? '',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.account_circle,
//             title: 'My Account',
//             onTap: () {
//               Navigator.pop(context); // Close drawer
//               context.go(isLoggedIn ? '/account' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.shopping_bag,
//             title: 'My Orders',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/orders' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.favorite,
//             title: 'Wishlist',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/wishlist' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.notifications,
//             title: 'Notifications',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/notifications' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.receipt,
//             title: 'Transactions',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/transactions' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.local_offer,
//             title: 'Coupons / Offers',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/coupons' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.category,
//             title: 'Categories',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/categories');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.support_agent,
//             title: 'Contact Support',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/support');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.settings,
//             title: 'Settings',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/settings');
//             },
//           ),
//           if (isLoggedIn)
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () async {
//                 Navigator.pop(context);
//                 final error = await context.read<AppState>().signOut();
//                 if (error != null) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(error),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 } else {
//                   context.go('/auth');
//                 }
//               },
//               color: Colors.redAccent,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//   required IconData icon,
//   required String title,
//   required VoidCallback onTap,
//   Color? color,
// }) {
//   return ListTile(
//     leading: Semantics(
//       label: title, // Provide accessibility label here
//       child: Icon(
//         icon,
//         color: color ?? premiumPrimaryColor,
//       ),
//     ),
//     title: Text(
//       title,
//       style: TextStyle(
//         color: color ?? premiumTextColor,
//         fontSize: 16,
//         fontWeight: FontWeight.w500,
//       ),
//     ),
//     onTap: onTap,
//     tileColor: Colors.white,
//     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//   );
// }

//   // ─── UI ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     if (!app.locationReady) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: const Center(child: CircularProgressIndicator(color: premiumPrimaryColor)),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         appBar: const Header(),
//         body: _buildErrorWidget(),
//         bottomNavigationBar: const FooterNav(),
//       );
//     }

//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: const Header(),
//       drawer: _buildDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _loadEverything,
//         color: premiumPrimaryColor,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // SEARCH
//               _buildSearchBar(),
//               const SizedBox(height: 24),

//               // BANNERS
//               _buildBanners(),
//               const SizedBox(height: 24),

//               // CATEGORIES
//               Text(
//                 'Categories',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 12),
//               _buildCategories(),
//               const SizedBox(height: 24),

//               // PRODUCTS
//               Text(
//                 'Products nearby',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 12),
//               _buildProducts(filtered),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: const FooterNav(),
//     );
//   }
// }



// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';
// import '../widgets/header.dart'; // Updated import path

// // Define the same premium color palette as OrderDetailsPage for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// const kRadiusKm = 40.0; // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<String> _banners = [];

//   // UI
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;
//   int _currentBannerIndex = 0;
//   String? _userName; // To display user's name in the drawer

//   // ─── Helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty) return 1e9;
//     if (b['latitude'] == null || b['longitude'] == null) return 1e9;

//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     // If emulator still reports Mountain View, swap to Bengaluru so you see items.
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   // ─── Load Everything ──────────────────────────────────────────────────────
//   Future<void> _loadEverything() async {
//     final app = context.read<AppState>();

//     if (app.buyerLocation == null) return; // Wait for ensureBuyerLocation()
//     final buyer = _sanitiseCoords(app.buyerLocation!);

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       // Categories
//       _categories = (await _spb.from('categories').select().order('name').limit(6))
//           .cast<Map<String, dynamic>>();

//       // Banners
//       final files = await _spb.storage.from('banner-images').list(path: '');
//       _banners = files
//           .where((f) => f.name.endsWith('.png') || f.name.endsWith('.jpg'))
//           .map((f) => _spb.storage.from('banner-images').getPublicUrl(f.name))
//           .cast<String>()
//           .toList();

//       // Sellers near me
//       final sellers = (await _spb.from('sellers').select('id, latitude, longitude'))
//           .cast<Map<String, dynamic>>();

//       final nearIds = sellers
//           .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//           .map((s) => s['id'])
//           .toList();

//       // Products
//       if (nearIds.isNotEmpty) {
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .inFilter('seller_id', nearIds)
//                 .eq('is_approved', true))
//             .cast<Map<String, dynamic>>();
//       } else {
//         // Fallback: Show some items so the UI isn’t blank
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .eq('is_approved', true)
//                 .limit(20))
//             .cast<Map<String, dynamic>>();
//       }
//     } catch (e) {
//       setState(() => _error = 'Failed to load data: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Load user profile for drawer
//   Future<void> _loadUserProfile() async {
//     final app = context.read<AppState>();
//     if (app.session == null) return;

//     try {
//       final response = await _spb
//           .from('profiles')
//           .select('full_name')
//           .eq('id', app.session!.user.id)
//           .maybeSingle();
//       setState(() {
//         _userName = response?['full_name'] ?? 'User';
//       });
//     } catch (e) {
//       setState(() {
//         _userName = 'User';
//       });
//     }
//   }

//   // ─── Lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     context.read<AppState>().ensureBuyerLocation().then((_) {
//       _loadEverything();
//       _loadUserProfile();
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ─── UI Helpers ───────────────────────────────────────────────────────────
//   Widget _buildShimmer({required double height, required double width}) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         height: height,
//         width: width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.error_outline,
//             color: Colors.red,
//             size: 48,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _error ?? 'Something went wrong',
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.red,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadEverything,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               elevation: 4,
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
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//           hintText: 'Search products…',
//           hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         ),
//         style: const TextStyle(color: premiumTextColor),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(
//             const Duration(milliseconds: 300),
//             () => setState(() => _search = txt.toLowerCase()),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBanners() {
//     if (_loading) {
//       return Shimmer.fromColors(
//         baseColor: Colors.grey[300]!,
//         highlightColor: Colors.grey[100]!,
//         child: Container(
//           height: 160,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     }

//     if (_banners.isEmpty) {
//       return Container(
//         height: 160,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(
//           child: Text(
//             'No banners available',
//             style: TextStyle(color: premiumSecondaryTextColor),
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [
//         CarouselSlider(
//           items: _banners
//               .map((u) => ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: CachedNetworkImage(
//                       imageUrl: u,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder: (context, url) => _buildShimmer(height: 160, width: double.infinity),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[300],
//                         child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                       ),
//                     ),
//                   ))
//               .toList(),
//           options: CarouselOptions(
//             height: 160,
//             autoPlay: true,
//             viewportFraction: 1,
//             autoPlayInterval: const Duration(seconds: 3),
//             onPageChanged: (index, reason) {
//               setState(() => _currentBannerIndex = index);
//             },
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _banners.asMap().entries.map((entry) {
//             return Container(
//               width: 8,
//               height: 8,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _currentBannerIndex == entry.key ? premiumPrimaryColor : Colors.grey[400],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories() {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           6,
//           (_) => _buildShimmer(height: 80, width: 80),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return const Text(
//         'No categories available.',
//         style: TextStyle(color: premiumSecondaryTextColor),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 3,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.8,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: _categories.map((c) {
//         return GestureDetector(
//           onTap: () => context.go('/categories/${c['id']}'),
//           child: Column(
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: ClipOval(
//                     child: CachedNetworkImage(
//                       imageUrl: c['image_url'] ?? 'https://dummyimage.com/150',
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => _buildShimmer(height: 80, width: 80),
//                       errorWidget: (context, url, error) => Container(
//                         color: Colors.grey[300],
//                         child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 c['name'],
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: premiumTextColor,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProducts(List<Map<String, dynamic>> filtered) {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           4,
//           (_) => _buildShimmer(height: 200, width: double.infinity),
//         ),
//       );
//     }

//     if (filtered.isEmpty) {
//       return const Center(
//         child: Text(
//           'No products found.',
//           style: TextStyle(color: premiumSecondaryTextColor),
//         ),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.65,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: filtered.map((p) {
//         final isLowStock = (p['stock'] as int) <= 5;
//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           color: premiumCardColor,
//           child: InkWell(
//             onTap: () => context.go('/product/${p['id']}'),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                         child: CachedNetworkImage(
//                           imageUrl: (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://dummyimage.com/150',
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           placeholder: (context, url) => _buildShimmer(height: 120, width: double.infinity),
//                           errorWidget: (context, url, error) => Container(
//                             color: Colors.grey[300],
//                             child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             p['title'],
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: premiumTextColor,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '₹${p['price'].toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               ElevatedButton(
//                                 onPressed: context.read<AppState>().session == null
//                                     ? null
//                                     : () async {
//                                         try {
//                                           await _spb.from('cart').insert({
//                                             'user_id': context.read<AppState>().session!.user.id,
//                                             'product_id': p['id'],
//                                             'quantity': 1,
//                                             'price': p['price'],
//                                           });
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             const SnackBar(
//                                               content: Text('Added to cart'),
//                                               backgroundColor: Colors.green,
//                                             ),
//                                           );
//                                           await context.read<AppState>().refreshCartCount();
//                                         } catch (e) {
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(
//                                               content: Text('Error adding to cart: $e'),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                         }
//                                       },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: premiumPrimaryColor,
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                   elevation: 2,
//                                 ),
//                                 child: const Text(
//                                   'Add to cart',
//                                   style: TextStyle(fontSize: 12, color: Colors.white),
//                                 ),
//                               ),
//                               OutlinedButton(
//                                 onPressed: () => context.go('/cart'),
//                                 style: OutlinedButton.styleFrom(
//                                   side: const BorderSide(color: premiumPrimaryColor),
//                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                 ),
//                                 child: const Text(
//                                   'Buy now',
//                                   style: TextStyle(fontSize: 12, color: premiumPrimaryColor),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (isLowStock)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.redAccent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Text(
//                         'Low Stock',
//                         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // Drawer Options
//   Widget _buildDrawer() {
//     final app = context.watch<AppState>();
//     final isLoggedIn = app.session != null;

//     return Drawer(
//       backgroundColor: premiumCardColor,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [premiumPrimaryColor, premiumPrimaryColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.white,
//                   child: Icon(
//                     Icons.person,
//                     size: 50,
//                     color: premiumPrimaryColor,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (isLoggedIn)
//                   Text(
//                     app.session!.user.email ?? '',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.account_circle,
//             title: 'My Account',
//             onTap: () {
//               Navigator.pop(context); // Close drawer
//               context.go(isLoggedIn ? '/account' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.shopping_bag,
//             title: 'My Orders',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/orders' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.favorite,
//             title: 'Wishlist',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/wishlist' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.notifications,
//             title: 'Notifications',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/notifications' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.receipt,
//             title: 'Transactions',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/transactions' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.local_offer,
//             title: 'Coupons / Offers',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/coupons' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.category,
//             title: 'Categories',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/categories');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.support_agent,
//             title: 'Contact Support',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/support');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.settings,
//             title: 'Settings',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/settings');
//             },
//           ),
//           if (isLoggedIn)
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () async {
//                 Navigator.pop(context);
//                 final error = await context.read<AppState>().signOut();
//                 if (error != null) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(error),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 } else {
//                   context.go('/auth');
//                 }
//               },
//               color: Colors.redAccent,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? color,
//   }) {
//     return ListTile(
//       leading: Semantics(
//         label: title,
//         child: Icon(
//           icon,
//           color: color ?? premiumPrimaryColor,
//         ),
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: color ?? premiumTextColor,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//       tileColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//     );
//   }

//   // ─── UI ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     if (!app.locationReady) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: const Center(child: CircularProgressIndicator(color: premiumPrimaryColor)),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         appBar: const Header(),
//         body: _buildErrorWidget(),
//       );
//     }

//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: const Header(),
//       drawer: _buildDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _loadEverything,
//         color: premiumPrimaryColor,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // SEARCH
//               _buildSearchBar(),
//               const SizedBox(height: 24),

//               // BANNERS
//               _buildBanners(),
//               const SizedBox(height: 24),

//               // CATEGORIES
//               Text(
//                 'Categories',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 12),
//               _buildCategories(),
//               const SizedBox(height: 24),

//               // PRODUCTS
//               Text(
//                 'Products nearby',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 12),
//               _buildProducts(filtered),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';
// import '../widgets/header.dart'; // Updated import path

// // Define the same premium color palette as OrderDetailsPage for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// const kRadiusKm = 40.0; // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<String> _banners = [];

//   // UI
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;
//   int _currentBannerIndex = 0;
//   String? _userName; // To display user's name in the drawer

//   // ─── Helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty) return 1e9;
//     if (b['latitude'] == null || b['longitude'] == null) return 1e9;

//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     // If emulator still reports Mountain View, swap to Bengaluru so you see items.
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   // ─── Load Everything ──────────────────────────────────────────────────────
//   Future<void> _loadEverything() async {
//     final app = context.read<AppState>();

//     if (app.buyerLocation == null) return; // Wait for ensureBuyerLocation()
//     final buyer = _sanitiseCoords(app.buyerLocation!);

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       // Categories
//       _categories = (await _spb.from('categories').select().order('name').limit(6))
//           .cast<Map<String, dynamic>>();

//       // Banners
//       final files = await _spb.storage.from('banner-images').list(path: '');
//       _banners = files
//           .where((f) => f.name.endsWith('.png') || f.name.endsWith('.jpg'))
//           .map((f) => _spb.storage.from('banner-images').getPublicUrl(f.name))
//           .cast<String>()
//           .toList();

//       // Sellers near me
//       final sellers = (await _spb.from('sellers').select('id, latitude, longitude'))
//           .cast<Map<String, dynamic>>();

//       final nearIds = sellers
//           .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//           .map((s) => s['id'])
//           .toList();

//       // Products
//       if (nearIds.isNotEmpty) {
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .inFilter('seller_id', nearIds)
//                 .eq('is_approved', true))
//             .cast<Map<String, dynamic>>();
//       } else {
//         // Fallback: Show some items so the UI isn’t blank
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .eq('is_approved', true)
//                 .limit(20))
//             .cast<Map<String, dynamic>>();
//       }
//     } catch (e) {
//       setState(() => _error = 'Failed to load data: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Load user profile for drawer
//   Future<void> _loadUserProfile() async {
//     final app = context.read<AppState>();
//     if (app.session == null) return;

//     try {
//       final response = await _spb
//           .from('profiles')
//           .select('full_name')
//           .eq('id', app.session!.user.id)
//           .maybeSingle();
//       setState(() {
//         _userName = response?['full_name'] ?? 'User';
//       });
//     } catch (e) {
//       setState(() {
//         _userName = 'User';
//       });
//     }
//   }

//   // ─── Lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     context.read<AppState>().ensureBuyerLocation().then((_) {
//       _loadEverything();
//       _loadUserProfile();
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ─── UI Helpers ───────────────────────────────────────────────────────────
//   Widget _buildShimmer({required double height, required double width}) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         height: height,
//         width: width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.error_outline,
//             color: Colors.red,
//             size: 48,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _error ?? 'Something went wrong',
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.red,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadEverything,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               elevation: 4,
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
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//           hintText: 'Search products…',
//           hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
//           ),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         style: const TextStyle(color: premiumTextColor),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(
//             const Duration(milliseconds: 300),
//             () => setState(() => _search = txt.toLowerCase()),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBanners() {
//     if (_loading) {
//       return _buildShimmer(height: 160, width: double.infinity);
//     }

//     if (_banners.isEmpty) {
//       return Container(
//         height: 160,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(
//           child: Text(
//             'No banners available',
//             style: TextStyle(color: premiumSecondaryTextColor),
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [
//         Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: CarouselSlider(
//             items: _banners
//                 .map((u) => ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: CachedNetworkImage(
//                         imageUrl: u,
//                         fit: BoxFit.cover,
//                         width: double.infinity,
//                         placeholder: (context, url) => _buildShimmer(height: 160, width: double.infinity),
//                         errorWidget: (context, url, error) => Container(
//                           color: Colors.grey[300],
//                           child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                         ),
//                       ),
//                     ))
//                 .toList(),
//             options: CarouselOptions(
//               height: 160,
//               autoPlay: true,
//               viewportFraction: 1,
//               autoPlayInterval: const Duration(seconds: 3),
//               onPageChanged: (index, reason) {
//                 setState(() => _currentBannerIndex = index);
//               },
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _banners.asMap().entries.map((entry) {
//             return Container(
//               width: 8,
//               height: 8,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _currentBannerIndex == entry.key ? premiumPrimaryColor : Colors.grey[400],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories() {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           6,
//           (_) => _buildShimmer(height: 100, width: 100),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return const Text(
//         'No categories available.',
//         style: TextStyle(color: premiumSecondaryTextColor),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 3,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.8,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: _categories.map((c) {
//         return InkWell(
//           onTap: () => context.go('/products?category=${c['id']}'), // Updated navigation
//           borderRadius: BorderRadius.circular(12),
//           child: Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             color: premiumCardColor,
//             child: Column(
//               children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: CachedNetworkImage(
//                       imageUrl: c['image_url'] ?? 'https://via.placeholder.com/150x150?text=Category',
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder: (context, url) => _buildShimmer(height: 80, width: double.infinity),
//                       errorWidget: (context, url, error) => const Icon(
//                         Icons.broken_image,
//                         color: premiumSecondaryTextColor,
//                         size: 40,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Text(
//                     (c['name'] as String).trim(),
//                     textAlign: TextAlign.center,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProducts(List<Map<String, dynamic>> filtered) {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           4,
//           (_) => _buildShimmer(height: 220, width: double.infinity),
//         ),
//       );
//     }

//     if (filtered.isEmpty) {
//       return const Center(
//         child: Text(
//           'No products found.',
//           style: TextStyle(color: premiumSecondaryTextColor),
//         ),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.65,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: filtered.map((p) {
//         final isLowStock = (p['stock'] as int) <= 5;
//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           color: premiumCardColor,
//           child: InkWell(
//             onTap: () => context.go('/products/${p['id']}'), // Updated navigation
//             borderRadius: BorderRadius.circular(12),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                         child: CachedNetworkImage(
//                           imageUrl: (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://via.placeholder.com/150x150?text=Product',
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           placeholder: (context, url) => _buildShimmer(height: 120, width: double.infinity),
//                           errorWidget: (context, url, error) => const Icon(
//                             Icons.broken_image,
//                             color: premiumSecondaryTextColor,
//                             size: 50,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             p['title'],
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: premiumTextColor,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '₹${p['price'].toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton(
//                                   onPressed: context.read<AppState>().session == null
//                                       ? () {
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             const SnackBar(
//                                               content: Text('Please log in to add items to your cart'),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                           context.go('/auth');
//                                         }
//                                       : () async {
//                                           try {
//                                             await _spb.from('cart').insert({
//                                               'user_id': context.read<AppState>().session!.user.id,
//                                               'product_id': p['id'],
//                                               'quantity': 1,
//                                               'price': p['price'],
//                                             });
//                                             ScaffoldMessenger.of(context).showSnackBar(
//                                               const SnackBar(
//                                                 content: Text('Added to cart'),
//                                                 backgroundColor: Colors.green,
//                                               ),
//                                             );
//                                             await context.read<AppState>().refreshCartCount();
//                                           } catch (e) {
//                                             ScaffoldMessenger.of(context).showSnackBar(
//                                               SnackBar(
//                                                 content: Text('Error adding to cart: $e'),
//                                                 backgroundColor: Colors.red,
//                                               ),
//                                             );
//                                           }
//                                         },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: premiumPrimaryColor,
//                                     padding: const EdgeInsets.symmetric(vertical: 10),
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                     elevation: 2,
//                                   ),
//                                   child: const Text(
//                                     'Add to Cart',
//                                     style: TextStyle(fontSize: 12, color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: OutlinedButton(
//                                   onPressed: () => context.go('/cart'),
//                                   style: OutlinedButton.styleFrom(
//                                     side: const BorderSide(color: premiumPrimaryColor, width: 1.5),
//                                     padding: const EdgeInsets.symmetric(vertical: 10),
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                   ),
//                                   child: const Text(
//                                     'Buy Now',
//                                     style: TextStyle(fontSize: 12, color: premiumPrimaryColor),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (isLowStock)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.redAccent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Text(
//                         'Low Stock',
//                         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // Drawer Options
//   Widget _buildDrawer() {
//     final app = context.watch<AppState>();
//     final isLoggedIn = app.session != null;

//     return Drawer(
//       backgroundColor: premiumCardColor,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [premiumPrimaryColor, premiumPrimaryColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.white,
//                   child: Icon(
//                     Icons.person,
//                     size: 50,
//                     color: premiumPrimaryColor,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (isLoggedIn)
//                   Text(
//                     app.session!.user.email ?? '',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.account_circle,
//             title: 'My Account',
//             onTap: () {
//               Navigator.pop(context); // Close drawer
//               context.go(isLoggedIn ? '/account' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.shopping_bag,
//             title: 'My Orders',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/orders' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.favorite,
//             title: 'Wishlist',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/wishlist' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.notifications,
//             title: 'Notifications',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/notifications' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.receipt,
//             title: 'Transactions',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/transactions' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.local_offer,
//             title: 'Coupons / Offers',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/coupons' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.category,
//             title: 'Categories',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/categories');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.support_agent,
//             title: 'Contact Support',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/support');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.settings,
//             title: 'Settings',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/settings');
//             },
//           ),
//           if (isLoggedIn)
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () {
//                 Navigator.pop(context);
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: const Text('Logout'),
//                     content: const Text('Are you sure you want to logout?'),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel', style: TextStyle(color: premiumSecondaryTextColor)),
//                       ),
//                       TextButton(
//                         onPressed: () async {
//                           Navigator.pop(context);
//                           final error = await context.read<AppState>().signOut();
//                           if (error != null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(error),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           } else {
//                             context.go('/auth');
//                           }
//                         },
//                         child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               color: Colors.redAccent,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? color,
//   }) {
//     return ListTile(
//       leading: Semantics(
//         label: title,
//         child: Icon(
//           icon,
//           color: color ?? premiumPrimaryColor,
//         ),
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: color ?? premiumTextColor,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//       tileColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//     );
//   }

//   // ─── UI ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     if (!app.locationReady) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: const Center(child: CircularProgressIndicator(color: premiumPrimaryColor)),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         appBar: const Header(),
//         body: _buildErrorWidget(),
//       );
//     }

//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: const Header(),
//       drawer: _buildDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _loadEverything,
//         color: premiumPrimaryColor,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // SEARCH
//               _buildSearchBar(),
//               const SizedBox(height: 24),

//               // BANNERS
//               _buildBanners(),
//               const SizedBox(height: 24),

//               // CATEGORIES
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Categories',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   TextButton(
//                     onPressed: () => context.go('/categories'),
//                     child: const Text(
//                       'See All',
//                       style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               _buildCategories(),
//               const SizedBox(height: 24),

//               // PRODUCTS
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Products nearby',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   TextButton(
//                     onPressed: () => context.go('/products'), // Navigate to all products
//                     child: const Text(
//                       'See All',
//                       style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               _buildProducts(filtered),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';
// import '../widgets/header.dart'; // Updated import path, now includes "My Orders" button

// // Define the same premium color palette as OrderDetailsPage for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// const kRadiusKm = 40.0; // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<String> _banners = [];

//   // UI
//   bool _loading = true;
//   String? _error;
//   String _search = '';
//   Timer? _debounce;
//   int _currentBannerIndex = 0;
//   String? _userName; // To display user's name in the drawer

//   // ─── Helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty) return 1e9;
//     if (b['latitude'] == null || b['longitude'] == null) return 1e9;

//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     // If emulator still reports Mountain View, swap to Bengaluru so you see items.
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   // ─── Load Everything ──────────────────────────────────────────────────────
//   Future<void> _loadEverything() async {
//     final app = context.read<AppState>();

//     if (app.buyerLocation == null) return; // Wait for ensureBuyerLocation()
//     final buyer = _sanitiseCoords(app.buyerLocation!);

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       // Categories
//       _categories = (await _spb.from('categories').select().order('name').limit(6))
//           .cast<Map<String, dynamic>>();

//       // Banners
//       final files = await _spb.storage.from('banner-images').list(path: '');
//       _banners = files
//           .where((f) => f.name.endsWith('.png') || f.name.endsWith('.jpg'))
//           .map((f) => _spb.storage.from('banner-images').getPublicUrl(f.name))
//           .cast<String>()
//           .toList();

//       // Sellers near me
//       final sellers = (await _spb.from('sellers').select('id, latitude, longitude'))
//           .cast<Map<String, dynamic>>();

//       final nearIds = sellers
//           .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//           .map((s) => s['id'])
//           .toList();

//       // Products
//       if (nearIds.isNotEmpty) {
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .inFilter('seller_id', nearIds)
//                 .eq('is_approved', true))
//             .cast<Map<String, dynamic>>();
//       } else {
//         // Fallback: Show some items so the UI isn’t blank
//         _products = (await _spb
//                 .from('products')
//                 .select('id, title, price, images, stock')
//                 .eq('is_approved', true)
//                 .limit(20))
//             .cast<Map<String, dynamic>>();
//       }
//     } catch (e) {
//       setState(() => _error = 'Failed to load data: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Load user profile for drawer
//   Future<void> _loadUserProfile() async {
//     final app = context.read<AppState>();
//     if (app.session == null) return;

//     try {
//       final response = await _spb
//           .from('profiles')
//           .select('full_name')
//           .eq('id', app.session!.user.id)
//           .maybeSingle();
//       setState(() {
//         _userName = response?['full_name'] ?? 'User';
//       });
//     } catch (e) {
//       setState(() {
//         _userName = 'User';
//       });
//     }
//   }

//   // ─── Lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     context.read<AppState>().ensureBuyerLocation().then((_) {
//       _loadEverything();
//       _loadUserProfile();
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ─── UI Helpers ───────────────────────────────────────────────────────────
//   Widget _buildShimmer({required double height, required double width}) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         height: height,
//         width: width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.error_outline,
//             color: Colors.red,
//             size: 48,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _error ?? 'Something went wrong',
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.red,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadEverything,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               elevation: 4,
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
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: TextField(
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
//           hintText: 'Search products…',
//           hintStyle: const TextStyle(color: premiumSecondaryTextColor),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: premiumPrimaryColor, width: 2),
//           ),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         style: const TextStyle(color: premiumTextColor),
//         onChanged: (txt) {
//           _debounce?.cancel();
//           _debounce = Timer(
//             const Duration(milliseconds: 300),
//             () => setState(() => _search = txt.toLowerCase()),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildBanners() {
//     if (_loading) {
//       return _buildShimmer(height: 160, width: double.infinity);
//     }

//     if (_banners.isEmpty) {
//       return Container(
//         height: 160,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Center(
//           child: Text(
//             'No banners available',
//             style: TextStyle(color: premiumSecondaryTextColor),
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [
//         Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: CarouselSlider(
//             items: _banners
//                 .map((u) => ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: CachedNetworkImage(
//                         imageUrl: u,
//                         fit: BoxFit.cover,
//                         width: double.infinity,
//                         placeholder: (context, url) => _buildShimmer(height: 160, width: double.infinity),
//                         errorWidget: (context, url, error) => Container(
//                           color: Colors.grey[300],
//                           child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                         ),
//                       ),
//                     ))
//                 .toList(),
//             options: CarouselOptions(
//               height: 160,
//               autoPlay: true,
//               viewportFraction: 1,
//               autoPlayInterval: const Duration(seconds: 3),
//               onPageChanged: (index, reason) {
//                 setState(() => _currentBannerIndex = index);
//               },
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _banners.asMap().entries.map((entry) {
//             return Container(
//               width: 8,
//               height: 8,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _currentBannerIndex == entry.key ? premiumPrimaryColor : Colors.grey[400],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories() {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           6,
//           (_) => _buildShimmer(height: 100, width: 100),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return const Text(
//         'No categories available.',
//         style: TextStyle(color: premiumSecondaryTextColor),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 3,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.8,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: _categories.map((c) {
//         return InkWell(
//           onTap: () => context.go('/products?category=${c['id']}'), // Updated navigation
//           borderRadius: BorderRadius.circular(12),
//           child: Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             color: premiumCardColor,
//             child: Column(
//               children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                     child: CachedNetworkImage(
//                       imageUrl: c['image_url'] ?? 'https://via.placeholder.com/150x150?text=Category',
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       placeholder: (context, url) => _buildShimmer(height: 80, width: double.infinity),
//                       errorWidget: (context, url, error) => const Icon(
//                         Icons.broken_image,
//                         color: premiumSecondaryTextColor,
//                         size: 40,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Text(
//                     (c['name'] as String).trim(),
//                     textAlign: TextAlign.center,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: premiumTextColor,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildProducts(List<Map<String, dynamic>> filtered) {
//     if (_loading) {
//       return GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: List.generate(
//           4,
//           (_) => _buildShimmer(height: 220, width: double.infinity),
//         ),
//       );
//     }

//     if (filtered.isEmpty) {
//       return const Center(
//         child: Text(
//           'No products found.',
//           style: TextStyle(color: premiumSecondaryTextColor),
//         ),
//       );
//     }

//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       childAspectRatio: 0.65,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: filtered.map((p) {
//         final isLowStock = (p['stock'] as int) <= 5;
//         return Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           color: premiumCardColor,
//           child: InkWell(
//             onTap: () => context.go('/products/${p['id']}'), // Updated navigation
//             borderRadius: BorderRadius.circular(12),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                         child: CachedNetworkImage(
//                           imageUrl: (p['images'] as List).isNotEmpty
//                               ? p['images'][0]
//                               : 'https://via.placeholder.com/150x150?text=Product',
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           placeholder: (context, url) => _buildShimmer(height: 120, width: double.infinity),
//                           errorWidget: (context, url, error) => const Icon(
//                             Icons.broken_image,
//                             color: premiumSecondaryTextColor,
//                             size: 50,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             p['title'],
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: premiumTextColor,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '₹${p['price'].toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton(
//                                   onPressed: context.read<AppState>().session == null
//                                       ? () {
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             const SnackBar(
//                                               content: Text('Please log in to add items to your cart'),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                           context.go('/auth');
//                                         }
//                                       : () async {
//                                           try {
//                                             await _spb.from('cart').insert({
//                                               'user_id': context.read<AppState>().session!.user.id,
//                                               'product_id': p['id'],
//                                               'quantity': 1,
//                                               'price': p['price'],
//                                             });
//                                             ScaffoldMessenger.of(context).showSnackBar(
//                                               const SnackBar(
//                                                 content: Text('Added to cart'),
//                                                 backgroundColor: Colors.green,
//                                               ),
//                                             );
//                                             await context.read<AppState>().refreshCartCount();
//                                           } catch (e) {
//                                             ScaffoldMessenger.of(context).showSnackBar(
//                                               SnackBar(
//                                                 content: Text('Error adding to cart: $e'),
//                                                 backgroundColor: Colors.red,
//                                               ),
//                                             );
//                                           }
//                                         },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: premiumPrimaryColor,
//                                     padding: const EdgeInsets.symmetric(vertical: 10),
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                     elevation: 2,
//                                   ),
//                                   child: const Text(
//                                     'Add to Cart',
//                                     style: TextStyle(fontSize: 12, color: Colors.white),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: OutlinedButton(
//                                   onPressed: () => context.go('/cart'),
//                                   style: OutlinedButton.styleFrom(
//                                     side: const BorderSide(color: premiumPrimaryColor, width: 1.5),
//                                     padding: const EdgeInsets.symmetric(vertical: 10),
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                   ),
//                                   child: const Text(
//                                     'Buy Now',
//                                     style: TextStyle(fontSize: 12, color: premiumPrimaryColor),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (isLowStock)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.redAccent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Text(
//                         'Low Stock',
//                         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // Drawer Options
//   Widget _buildDrawer() {
//     final app = context.watch<AppState>();
//     final isLoggedIn = app.session != null;

//     return Drawer(
//       backgroundColor: premiumCardColor,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [premiumPrimaryColor, premiumPrimaryColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.white,
//                   child: Icon(
//                     Icons.person,
//                     size: 50,
//                     color: premiumPrimaryColor,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (isLoggedIn)
//                   Text(
//                     app.session!.user.email ?? '',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 14,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.account_circle,
//             title: 'My Account',
//             onTap: () {
//               Navigator.pop(context); // Close drawer
//               context.go(isLoggedIn ? '/account' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.shopping_bag,
//             title: 'My Orders',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/orders' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.favorite,
//             title: 'Wishlist',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/wishlist' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.notifications,
//             title: 'Notifications',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/notifications' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.receipt,
//             title: 'Transactions',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/transactions' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.local_offer,
//             title: 'Coupons / Offers',
//             onTap: () {
//               Navigator.pop(context);
//               context.go(isLoggedIn ? '/coupons' : '/auth');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.category,
//             title: 'Categories',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/categories');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.support_agent,
//             title: 'Contact Support',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/support');
//             },
//           ),
//           _buildDrawerItem(
//             icon: Icons.settings,
//             title: 'Settings',
//             onTap: () {
//               Navigator.pop(context);
//               context.go('/settings');
//             },
//           ),
//           if (isLoggedIn)
//             _buildDrawerItem(
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () {
//                 Navigator.pop(context);
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: const Text('Logout'),
//                     content: const Text('Are you sure you want to logout?'),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel', style: TextStyle(color: premiumSecondaryTextColor)),
//                       ),
//                       TextButton(
//                         onPressed: () async {
//                           Navigator.pop(context);
//                           final error = await context.read<AppState>().signOut();
//                           if (error != null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(error),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           } else {
//                             context.go('/auth');
//                           }
//                         },
//                         child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               color: Colors.redAccent,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? color,
//   }) {
//     return ListTile(
//       leading: Semantics(
//         label: title,
//         child: Icon(
//           icon,
//           color: color ?? premiumPrimaryColor,
//         ),
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: color ?? premiumTextColor,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//       tileColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//     );
//   }

//   // ─── UI ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     if (!app.locationReady) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: const Center(child: CircularProgressIndicator(color: premiumPrimaryColor)),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         appBar: const Header(),
//         body: _buildErrorWidget(),
//       );
//     }

//     final filtered = _search.isEmpty
//         ? _products
//         : _products
//             .where((p) => (p['title'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: const Header(),
//       drawer: _buildDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _loadEverything,
//         color: premiumPrimaryColor,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // SEARCH
//               _buildSearchBar(),
//               const SizedBox(height: 24),

//               // BANNERS
//               _buildBanners(),
//               const SizedBox(height: 24),

//               // CATEGORIES
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Categories',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   TextButton(
//                     onPressed: () => context.go('/categories'),
//                     child: const Text(
//                       'See All',
//                       style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               _buildCategories(),
//               const SizedBox(height: 24),

//               // PRODUCTS
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Products nearby',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                   ),
//                   TextButton(
//                     onPressed: () => context.go('/products'), // Navigate to all products
//                     child: const Text(
//                       'See All',
//                       style: TextStyle(color: premiumPrimaryColor, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               _buildProducts(filtered),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// import '../state/app_state.dart';
// import '../widgets/header.dart';
// import '../widgets/footer.dart';

// // Define the same premium color palette as OrderDetailsPage for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumCardColor = Colors.white;
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey
// const premiumShadowColor = Color(0x1A000000);
// const premiumErrorColor = Color(0xFFEF4444);
// const premiumSuccessColor = Color(0xFF2ECC71);

// const kRadiusKm = 40.0; // <= change to 10000 while testing if you like
// const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   final _spb = Supabase.instance.client;

//   // Data
//   List<Map<String, dynamic>> _products = [];
//   List<Map<String, dynamic>> _categories = [];
//   List<Map<String, dynamic>> _banners = [];
//   List<Map<String, dynamic>> _suggestions = [];

//   // UI
//   bool _loadingProducts = true;
//   bool _loadingBanners = true;
//   bool _loadingCategories = true;
//   String? _error;
//   String _search = '';
//   bool _isSearchFocused = false;
//   Timer? _debounce;
//   int _currentBannerIndex = 0;
//   String? _userName;
//   final _searchController = TextEditingController();
//   final _searchFocusNode = FocusNode();

//   // ─── Helpers ──────────────────────────────────────────────────────────────
//   double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
//     if (a == null || a.isEmpty || b['latitude'] == null || b['longitude'] == null) return 1e9;
//     const R = 6371;
//     final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
//     final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
//     final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(a['lat']! * math.pi / 180) *
//             math.cos(b['latitude'] * math.pi / 180) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
//   }

//   Map<String, double> _sanitiseCoords(Map<String, double> loc) {
//     if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
//     return loc;
//   }

//   bool _checkNetworkStatus() {
//     return true; // Replace with actual network check if needed
//   }

//   // ─── Load Data ────────────────────────────────────────────────────────────
//   Future<void> _loadCategories() async {
//     if (!_checkNetworkStatus()) {
//       setState(() => _loadingCategories = false);
//       Fluttertoast.showToast(
//         msg: 'No internet connection. Please check your network and try again.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       return;
//     }
//     setState(() => _loadingCategories = true);
//     try {
//       final data = (await _spb
//               .from('categories')
//               .select('id, name, image_url, is_restricted')
//               .order('name')
//               .limit(6))
//           .cast<Map<String, dynamic>>();
//       setState(() {
//         _categories = data;
//         _error = null;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to load categories. Please try again.';
//         _categories = [];
//       });
//       Fluttertoast.showToast(
//         msg: 'Failed to load categories',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//     } finally {
//       setState(() => _loadingCategories = false);
//     }
//   }

//   Future<void> _loadBanners() async {
//     if (!_checkNetworkStatus()) {
//       setState(() => _loadingBanners = false);
//       Fluttertoast.showToast(
//         msg: 'No internet connection. Please check your network and try again.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       return;
//     }
//     setState(() => _loadingBanners = true);
//     try {
//       final files = await _spb.storage.from('banner-images').list(path: '');
//       final banners = files
//           .where((f) => f.name.endsWith('.jpg') || f.name.endsWith('.jpeg') || f.name.endsWith('.png') || f.name.endsWith('.gif'))
//           .map((f) => {'url': _spb.storage.from('banner-images').getPublicUrl(f.name), 'name': f.name})
//           .toList();
//       setState(() {
//         _banners = banners.isNotEmpty ? banners : [{'url': 'https://via.placeholder.com/1200x300', 'name': 'default'}];
//       });
//     } catch (e) {
//       setState(() {
//         _banners = [{'url': 'https://via.placeholder.com/1200x300', 'name': 'default'}];
//       });
//       Fluttertoast.showToast(
//         msg: 'Failed to load banners',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//     } finally {
//       setState(() => _loadingBanners = false);
//     }
//   }

//   Future<void> _loadProducts() async {
//     final app = context.read<AppState>();
//     if (app.buyerLocation == null) {
//       setState(() => _loadingProducts = false);
//       return;
//     }
//     if (!_checkNetworkStatus()) {
//       setState(() => _loadingProducts = false);
//       Fluttertoast.showToast(
//         msg: 'No internet connection. Please check your network and try again.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       return;
//     }
//     setState(() => _loadingProducts = true);
//     final buyer = _sanitiseCoords(app.buyerLocation!);
//     try {
//       final sellers = (await _spb
//               .from('sellers')
//               .select('id, latitude, longitude')
//               .not('latitude', 'is', null)
//               .not('longitude', 'is', null))
//           .cast<Map<String, dynamic>>();

//       final nearIds = sellers
//           .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
//           .map((s) => s['id'])
//           .toList();

//       final nonRestrictedCategories = (await _spb
//               .from('categories')
//               .select('id')
//               .eq('is_restricted', false))
//           .cast<Map<String, dynamic>>();
//       final nonRestrictedCategoryIds = nonRestrictedCategories.map((cat) => cat['id']).toList();

//       if (nonRestrictedCategoryIds.isEmpty) {
//         setState(() => _products = []);
//         return;
//       }

//       final productData = (await _spb
//               .from('products')
//               .select('''
//                 id, title, price, original_price, discount_amount, images, seller_id, stock, category_id, delivery_radius_km,
//                 categories (id, max_delivery_radius_km, is_restricted)
//               ''')
//               .eq('is_approved', true)
//               .eq('status', 'active')
//               .inFilter('category_id', nonRestrictedCategoryIds))
//           .cast<Map<String, dynamic>>();

//       final filteredProductData = productData.where((p) => p['categories'] != null && p['categories']['is_restricted'] == false).toList();

//       final filteredProductIds = filteredProductData
//           .where((product) {
//             final seller = sellers.firstWhere((s) => s['id'] == product['seller_id'], orElse: () => {});
//             if (seller.isEmpty) return false;
//             final distance = _distanceKm(buyer, seller);
//             final effectiveRadius = product['delivery_radius_km'] ?? product['categories']['max_delivery_radius_km'] ?? kRadiusKm;
//             return distance <= effectiveRadius;
//           })
//           .map((p) => p['id'])
//           .toList();

//       if (filteredProductIds.isEmpty) {
//         setState(() => _products = []);
//         return;
//       }

//       final variantData = (await _spb
//               .from('product_variants')
//               .select('id, product_id, price, original_price, stock, attributes, images')
//               .eq('status', 'active')
//               .inFilter('product_id', filteredProductIds))
//           .cast<Map<String, dynamic>>();

//       final mappedProducts = filteredProductData.where((p) => filteredProductIds.contains(p['id'])).map((product) {
//         final variants = variantData
//             .where((v) => v['product_id'] == product['id'])
//             .map((v) => {
//                   'id': v['id'],
//                   'price': (v['price'] as num?)?.toDouble() ?? 0.0,
//                   'original_price': (v['original_price'] as num?)?.toDouble(),
//                   'stock': v['stock'] ?? 0,
//                   'attributes': v['attributes'] ?? {},
//                   'images': v['images'] != null && (v['images'] as List).isNotEmpty ? v['images'] : product['images'],
//                 })
//             .toList();

//         final validImages = (product['images'] as List).isNotEmpty
//             ? (product['images'] as List).where((img) => img is String && img.trim().isNotEmpty).toList()
//             : ['https://via.placeholder.com/150'];

//         return {
//           'id': product['id'],
//           'name': product['title'] ?? 'Unnamed Product',
//           'images': validImages,
//           'price': (product['price'] as num?)?.toDouble() ?? 0.0,
//           'original_price': (product['original_price'] as num?)?.toDouble(),
//           'discount_amount': (product['discount_amount'] as num?)?.toDouble() ?? 0.0,
//           'stock': product['stock'] ?? 0,
//           'category_id': product['category_id'],
//           'variants': variants,
//           'display_price': variants.isNotEmpty
//               ? variants.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b)
//               : (product['price'] as num?)?.toDouble() ?? 0.0,
//           'display_original_price': variants.isNotEmpty
//               ? variants.firstWhere(
//                   (v) => v['price'] == variants.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b),
//                   orElse: () => {'original_price': product['original_price']})['original_price']
//               : product['original_price'],
//           'distance': _distanceKm(buyer, sellers.firstWhere((s) => s['id'] == product['seller_id'], orElse: () => {})),
//           'delivery_radius': product['delivery_radius_km'] ?? product['categories']['max_delivery_radius_km'] ?? kRadiusKm,
//         };
//       }).toList()
//         ..sort((a, b) => a['display_price'].compareTo(b['display_price']));

//       setState(() {
//         _products = mappedProducts;
//         _error = null;
//       });
//     } catch (e) {
//       final errorMessage = e.toString().contains('Network') ? 'Network error. Please check your connection.' : 'Failed to load products. Please try again.';
//       setState(() {
//         _error = errorMessage;
//         _products = [];
//       });
//       Fluttertoast.showToast(
//         msg: errorMessage,
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//     } finally {
//       setState(() => _loadingProducts = false);
//     }
//   }

//   Future<void> _loadUserProfile() async {
//     final app = context.read<AppState>();
//     if (app.session == null) return;
//     try {
//       final response = await _spb
//           .from('profiles')
//           .select('full_name')
//           .eq('id', app.session!.user.id)
//           .maybeSingle();
//       setState(() {
//         _userName = response?['full_name'] ?? 'User';
//       });
//     } catch (e) {
//       setState(() {
//         _userName = 'User';
//       });
//     }
//   }

//   Future<bool> _validateVariant(int? variantId) async {
//     if (variantId == null) return true;
//     try {
//       final data = await _spb
//           .from('product_variants')
//           .select('id')
//           .eq('id', variantId)
//           .eq('status', 'active')
//           .maybeSingle();
//       if (data == null) {
//         Fluttertoast.showToast(
//           msg: 'Selected variant is not available.',
//           backgroundColor: premiumErrorColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//         return false;
//       }
//       return true;
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Error validating variant.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       return false;
//     }
//   }

//   Future<void> _addToCart(Map<String, dynamic> product, {bool isBuyNow = false}) async {
//     if (product['id'] == null || product['name'] == null || product['display_price'] == null) {
//       Fluttertoast.showToast(
//         msg: 'Invalid product.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       return;
//     }
//     if (product['stock'] <= 0 || (product['variants'].isNotEmpty && product['variants'].every((v) => v['stock'] <= 0))) {
//       Fluttertoast.showToast(
//         msg: 'Out of stock.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       return;
//     }
//     final app = context.read<AppState>();
//     if (app.session == null) {
//       Fluttertoast.showToast(
//         msg: isBuyNow ? 'Please log in to proceed to checkout.' : 'Please log in to add items to cart.',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//       context.go('/auth');
//       return;
//     }
//     if (!_checkNetworkStatus()) return;

//     try {
//       final categoryData = await _spb
//           .from('categories')
//           .select('is_restricted')
//           .eq('id', product['category_id'])
//           .maybeSingle();
//       if (categoryData?['is_restricted'] == true) {
//         Fluttertoast.showToast(
//           msg: 'Please select this category from the categories page to ${isBuyNow ? 'proceed.' : 'add products to cart.'}',
//           backgroundColor: premiumErrorColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//         context.go('/categories');
//         return;
//       }

//       final productData = await _spb
//           .from('products')
//           .select('id, seller_id, delivery_radius_km, category_id')
//           .eq('id', product['id'])
//           .eq('is_approved', true)
//           .eq('status', 'active')
//           .maybeSingle();
//       if (productData == null) {
//         Fluttertoast.showToast(
//           msg: 'Product is not available.',
//           backgroundColor: premiumErrorColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//         return;
//       }

//       final sellerData = await _spb
//           .from('sellers')
//           .select('id, latitude, longitude')
//           .eq('id', productData['seller_id'])
//           .maybeSingle();
//       if (sellerData == null) {
//         Fluttertoast.showToast(
//           msg: 'Seller information not available.',
//           backgroundColor: premiumErrorColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//         return;
//       }

//       final distance = _distanceKm(app.buyerLocation, sellerData);
//       final effectiveRadius = productData['delivery_radius_km'] ?? categoryData?['max_delivery_radius_km'] ?? kRadiusKm;
//       if (distance > effectiveRadius) {
//         Fluttertoast.showToast(
//           msg: 'Product is not available in your area (${distance.toStringAsFixed(2)}km > ${effectiveRadius}km).',
//           backgroundColor: premiumErrorColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//         return;
//       }

//       Map<String, dynamic> itemToAdd = product;
//       int? variantId;

//       if (product['variants'].isNotEmpty) {
//         final validVariants = product['variants'].where((v) => v['stock'] > 0 && v['price'] != null).toList();
//         if (validVariants.isEmpty) {
//           Fluttertoast.showToast(
//             msg: 'No available variants in stock.',
//             backgroundColor: premiumErrorColor,
//             textColor: Colors.white,
//             fontSize: 15,
//             toastLength: Toast.LENGTH_LONG,
//             gravity: ToastGravity.TOP,
//           );
//           return;
//         }
//         itemToAdd = validVariants.reduce((a, b) => a['price'] < b['price'] ? a : b);
//         variantId = itemToAdd['id'] as int?;

//         final isValidVariant = await _validateVariant(variantId);
//         if (!isValidVariant) return;
//       }

//       final query = _spb
//           .from('cart')
//           .select('id, quantity, variant_id')
//           .eq('user_id', app.session!.user.id)
//           .eq('product_id', product['id']);

//       if (variantId == null) {
//         query.isFilter('variant_id', null);
//       } else {
//         query.eq('variant_id', variantId);
//       }

//       final existingCartItem = await query.maybeSingle();

//       if (existingCartItem != null) {
//         final newQuantity = existingCartItem['quantity'] + 1;
//         final stockLimit = itemToAdd['stock'] as int? ?? product['stock'] as int;
//         if (newQuantity > stockLimit) {
//           Fluttertoast.showToast(
//             msg: 'Exceeds stock.',
//             backgroundColor: premiumErrorColor,
//             textColor: Colors.white,
//             fontSize: 15,
//             toastLength: Toast.LENGTH_LONG,
//             gravity: ToastGravity.TOP,
//           );
//           return;
//         }
//         await _spb
//             .from('cart')
//             .update({'quantity': newQuantity})
//             .eq('id', existingCartItem['id']);
//         Fluttertoast.showToast(
//           msg: '${product['name']} quantity updated in cart!',
//           backgroundColor: premiumSuccessColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//       } else {
//         await _spb.from('cart').insert({
//           'user_id': app.session!.user.id,
//           'product_id': product['id'],
//           'variant_id': variantId,
//           'quantity': 1,
//           'price': itemToAdd['price'] as double? ?? product['display_price'] as double,
//           'title': product['name'],
//         });
//         app.refreshCartCount();
//         Fluttertoast.showToast(
//           msg: '${product['name']} added to cart!',
//           backgroundColor: premiumSuccessColor,
//           textColor: Colors.white,
//           fontSize: 15,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.TOP,
//         );
//         if (isBuyNow) {
//           await Future.delayed(const Duration(seconds: 2));
//           context.go('/cart');
//         }
//       }
//       await app.refreshCartCount();
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Failed to add to cart: $e',
//         backgroundColor: premiumErrorColor,
//         textColor: Colors.white,
//         fontSize: 15,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.TOP,
//       );
//     }
//   }

//   Future<void> _loadEverything() async {
//     setState(() {
//       _loadingProducts = true;
//       _loadingBanners = true;
//       _loadingCategories = true;
//     });
//     await Future.wait([
//       _loadCategories(),
//       _loadBanners(),
//       _loadProducts(),
//       _loadUserProfile(),
//     ]);
//   }

//   // ─── Lifecycle ────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     final app = context.read<AppState>();
//     app.ensureBuyerLocation().then((_) => _loadEverything());
//     _searchFocusNode.addListener(() {
//       setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
//       if (!_isSearchFocused) {
//         setState(() => _suggestions = []);
//       } else if (_search.isNotEmpty) {
//         setState(() {
//           _suggestions = _products
//               .where((p) => p['name'].toString().toLowerCase().contains(_search.toLowerCase()))
//               .take(5)
//               .toList();
//         });
//       }
//     });
//     _searchController.addListener(() {
//       _debounce?.cancel();
//       _debounce = Timer(
//         const Duration(milliseconds: 300),
//         () {
//           setState(() {
//             _search = _searchController.text.toLowerCase();
//             if (_isSearchFocused && _search.isNotEmpty) {
//               _suggestions = _products
//                   .where((p) => p['name'].toString().toLowerCase().contains(_search))
//                   .take(5)
//                   .toList();
//             } else {
//               _suggestions = [];
//             }
//           });
//         },
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   // ─── UI Helpers ───────────────────────────────────────────────────────────
//   Widget _buildShimmer({required double height, required double width}) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       period: const Duration(milliseconds: 1500),
//       child: Container(
//         height: height,
//         width: width,
//         decoration: BoxDecoration(
//           color: premiumCardColor,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(color: premiumShadowColor, blurRadius: 6, offset: const Offset(0, 2)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.error_outline,
//             color: premiumErrorColor,
//             size: 48,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             _error ?? 'Something went wrong',
//             style: GoogleFonts.roboto(
//               fontSize: 16,
//               color: premiumErrorColor,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadEverything,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: premiumPrimaryColor,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               elevation: 3,
//               shadowColor: premiumShadowColor,
//             ),
//             child: Text(
//               'Retry',
//               style: GoogleFonts.roboto(
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
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: premiumCardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _isSearchFocused ? Colors.transparent : premiumSecondaryTextColor.withOpacity(0.3),
//           width: 1.5,
//         ),
//         gradient: _isSearchFocused
//             ? LinearGradient(
//                 colors: [premiumPrimaryColor, premiumAccentColor],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               )
//             : null,
//         boxShadow: [
//           BoxShadow(
//             color: premiumShadowColor,
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           TextField(
//             controller: _searchController,
//             focusNode: _searchFocusNode,
//             decoration: InputDecoration(
//               prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor, size: 24),
//               hintText: 'Search electronics, fashion, jewellery...',
//               hintStyle: GoogleFonts.roboto(
//                 color: premiumSecondaryTextColor.withOpacity(0.7),
//                 fontSize: 16,
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               fillColor: Colors.white,
//               filled: true,
//             ),
//             style: GoogleFonts.roboto(
//               color: premiumTextColor,
//               fontSize: 16,
//             ),
//           ),
//           if (_isSearchFocused && _suggestions.isNotEmpty)
//             Positioned(
//               top: 68,
//               left: 16,
//               right: 16,
//               child: Material(
//                 elevation: 4,
//                 borderRadius: BorderRadius.circular(8),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: premiumCardColor,
//                     borderRadius: BorderRadius.circular(8),
//                     boxShadow: [
//                       BoxShadow(
//                         color: premiumShadowColor,
//                         blurRadius: 6,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: _suggestions.map((suggestion) {
//                       return ListTile(
//                         title: Text(
//                           suggestion['name'],
//                           style: GoogleFonts.roboto(
//                             fontSize: 14,
//                             color: premiumTextColor,
//                           ),
//                         ),
//                         onTap: () {
//                           setState(() {
//                             _searchController.text = suggestion['name'];
//                             _search = suggestion['name'];
//                             _isSearchFocused = false;
//                             _suggestions = [];
//                             _searchFocusNode.unfocus();
//                           });
//                           context.go('/products/${suggestion['id']}');
//                         },
//                       );
//                     }).toList().cast<Widget>(),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBanners() {
//     if (_loadingBanners) {
//       return _buildShimmer(height: 200, width: double.infinity);
//     }
//     if (_banners.isEmpty) {
//       return Container(
//         height: 200,
//         margin: const EdgeInsets.symmetric(horizontal: 16),
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(color: premiumShadowColor, blurRadius: 6, offset: const Offset(0, 2)),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             'No banners available',
//             style: GoogleFonts.roboto(color: premiumSecondaryTextColor, fontSize: 16),
//           ),
//         ),
//       );
//     }
//     return Column(
//       children: [
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(color: premiumShadowColor, blurRadius: 8, offset: const Offset(0, 3)),
//             ],
//           ),
//           child: CarouselSlider(
//             items: _banners
//                 .map((banner) => Stack(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: CachedNetworkImage(
//                             imageUrl: banner['url'],
//                             fit: BoxFit.cover,
//                             width: double.infinity,
//                             height: 200,
//                             placeholder: (context, url) => _buildShimmer(height: 200, width: double.infinity),
//                             errorWidget: (context, url, error) => Container(
//                               color: Colors.grey[300],
//                               child: const Center(child: Icon(Icons.broken_image, color: premiumSecondaryTextColor)),
//                             ),
//                           ),
//                         ),
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             gradient: LinearGradient(
//                               colors: [Colors.black.withOpacity(0.3), Colors.transparent],
//                               begin: Alignment.bottomCenter,
//                               end: Alignment.topCenter,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 15,
//                           right: 15,
//                           child: ElevatedButton(
//                             onPressed: () => context.go('/categories'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: premiumAccentColor,
//                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                               elevation: 3,
//                               shadowColor: premiumShadowColor,
//                             ),
//                             child: Text(
//                               'View Offers',
//                               style: GoogleFonts.roboto(
//                                 fontSize: 14,
//                                 color: premiumTextColor,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ))
//                 .toList(),
//             options: CarouselOptions(
//               height: 200,
//               autoPlay: true,
//               viewportFraction: 1,
//               autoPlayInterval: const Duration(seconds: 3),
//               autoPlayAnimationDuration: const Duration(milliseconds: 800),
//               autoPlayCurve: Curves.easeInOut,
//               onPageChanged: (index, reason) {
//                 setState(() => _currentBannerIndex = index);
//               },
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: _banners.asMap().entries.map((entry) {
//             return Container(
//               width: 8,
//               height: 8,
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _currentBannerIndex == entry.key ? premiumPrimaryColor : Colors.grey[400],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildCategories() {
//     if (_loadingCategories) {
//       return AnimationLimiter(
//         child: GridView.count(
//           crossAxisCount: 3,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.8,
//           crossAxisSpacing: 15,
//           mainAxisSpacing: 15,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           children: List.generate(
//             6,
//             (index) => AnimationConfiguration.staggeredGrid(
//               position: index,
//               columnCount: 3,
//               duration: const Duration(milliseconds: 600),
//               child: ScaleAnimation(
//                 child: FadeInAnimation(
//                   child: _buildShimmer(height: 100, width: 140),
//                 ),
//               ),
//             ),
//           ).cast<Widget>(),
//         ),
//       );
//     }
//     if (_categories.isEmpty) {
//       return Center(
//         child: Text(
//           'No categories available.',
//           style: GoogleFonts.roboto(color: premiumSecondaryTextColor, fontSize: 16),
//         ),
//       );
//     }
//     return AnimationLimiter(
//       child: GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 15,
//         mainAxisSpacing: 15,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         children: _categories.asMap().entries.map((entry) {
//           final c = entry.value;
//           return AnimationConfiguration.staggeredGrid(
//             position: entry.key,
//             columnCount: 3,
//             duration: const Duration(milliseconds: 600),
//             child: ScaleAnimation(
//               child: FadeInAnimation(
//                 child: InkWell(
//                   onTap: () => context.go('/products?category=${c['id']}&fromCategories=true'),
//                   borderRadius: BorderRadius.circular(12),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     color: premiumCardColor,
//                     child: Column(
//                       children: [
//                         Expanded(
//                           child: ClipRRect(
//                             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//                             child: CachedNetworkImage(
//                               imageUrl: c['image_url'] ?? 'https://via.placeholder.com/150x150?text=Category',
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                               placeholder: (context, url) => _buildShimmer(height: 70, width: double.infinity),
//                               errorWidget: (context, url, error) => const Icon(
//                                 Icons.broken_image,
//                                 color: premiumSecondaryTextColor,
//                                 size: 40,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(6),
//                           child: Text(
//                             c['name'].toString().trim(),
//                             textAlign: TextAlign.center,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.roboto(
//                               color: premiumTextColor,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList().cast<Widget>(),
//       ),
//     );
//   }

//   Widget _buildProducts(List<Map<String, dynamic>> filtered) {
//     if (_loadingProducts) {
//       return AnimationLimiter(
//         child: GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           childAspectRatio: 0.65,
//           crossAxisSpacing: 20,
//           mainAxisSpacing: 20,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           children: List.generate(
//             4,
//             (index) => AnimationConfiguration.staggeredGrid(
//               position: index,
//               columnCount: 2,
//               duration: const Duration(milliseconds: 600),
//               child: ScaleAnimation(
//                 child: FadeInAnimation(
//                   child: _buildShimmer(height: 280, width: double.infinity),
//                 ),
//               ),
//             ),
//           ).cast<Widget>(),
//         ),
//       );
//     }
//     if (filtered.isEmpty) {
//       return Center(
//         child: Text(
//           'No products found.',
//           style: GoogleFonts.roboto(color: premiumSecondaryTextColor, fontSize: 16),
//         ),
//       );
//     }
//     return AnimationLimiter(
//       child: GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 0.65,
//         crossAxisSpacing: 20,
//         mainAxisSpacing: 20,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         children: filtered.asMap().entries.map((entry) {
//           final p = entry.value;
//           final isLowStock = p['stock'] <= 5;
//           return AnimationConfiguration.staggeredGrid(
//             position: entry.key,
//             columnCount: 2,
//             duration: const Duration(milliseconds: 600),
//             child: ScaleAnimation(
//               child: FadeInAnimation(
//                 child: Card(
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   color: premiumCardColor,
//                   child: InkWell(
//                     onTap: () => context.go('/products/${p['id']}'),
//                     borderRadius: BorderRadius.circular(12),
//                     splashColor: premiumPrimaryColor.withValues(alpha: 0.1),
//                     child: Stack(
//                       children: [
//                         if (p['discount_amount'] > 0)
//                           Positioned(
//                             top: 8,
//                             left: 8,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(12),
//                                 gradient: LinearGradient(
//                                   colors: [premiumAccentColor, premiumErrorColor],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                               ),
//                               child: Column(
//                                 children: [
//                                   Text(
//                                     'Offer!',
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   Text(
//                                     'Save ₹${p['discount_amount'].toStringAsFixed(2)}',
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 10,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         if (isLowStock)
//                           Positioned(
//                             top: 8,
//                             right: 8,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: premiumErrorColor,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 'Low Stock',
//                                 style: GoogleFonts.roboto(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               child: ClipRRect(
//                                 borderRadius: const BorderRadius.only(
//                                   topLeft: Radius.circular(12),
//                                   topRight: Radius.circular(12),
//                                 ),
//                                 child: CachedNetworkImage(
//                                   imageUrl: p['images'][0],
//                                   fit: BoxFit.contain,
//                                   width: double.infinity,
//                                   placeholder: (context, url) => _buildShimmer(height: 120, width: double.infinity),
//                                   errorWidget: (context, url, error) => const Icon(
//                                     Icons.broken_image,
//                                     color: premiumSecondaryTextColor,
//                                     size: 50,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(10),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     p['name'],
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w600,
//                                       color: premiumTextColor,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 6),
//                                   Row(
//                                     children: [
//                                       Text(
//                                         '₹${p['display_price'].toStringAsFixed(2)}',
//                                         style: GoogleFonts.roboto(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w600,
//                                           color: premiumSuccessColor,
//                                         ),
//                                       ),
//                                       if (p['display_original_price'] != null && p['display_original_price'] > p['display_price'])
//                                         Padding(
//                                           padding: const EdgeInsets.only(left: 8),
//                                           child: Text(
//                                             '₹${p['display_original_price'].toStringAsFixed(2)}',
//                                             style: GoogleFonts.roboto(
//                                               fontSize: 12,
//                                               color: premiumSecondaryTextColor,
//                                               decoration: TextDecoration.lineThrough,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: ElevatedButton(
//                                           onPressed: () => _addToCart(p),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: premiumPrimaryColor,
//                                             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                             elevation: 3,
//                                             shadowColor: premiumShadowColor,
//                                           ),
//                                           child: Row(
//                                             mainAxisAlignment: MainAxisAlignment.center,
//                                             children: [
//                                               const Icon(Icons.shopping_cart, size: 12, color: Colors.white),
//                                               const SizedBox(width: 6),
//                                               Text(
//                                                 'Add to Cart',
//                                                 style: GoogleFonts.roboto(
//                                                   fontSize: 12,
//                                                   color: Colors.white,
//                                                   fontWeight: FontWeight.w500,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: OutlinedButton(
//                                           onPressed: () => _addToCart(p, isBuyNow: true),
//                                           style: OutlinedButton.styleFrom(
//                                             side: const BorderSide(color: premiumPrimaryColor, width: 1.5),
//                                             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                           ),
//                                           child: Text(
//                                             'Buy Now',
//                                             style: GoogleFonts.roboto(
//                                               fontSize: 12,
//                                               color: premiumPrimaryColor,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList().cast<Widget>(),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     final app = context.watch<AppState>();
//     final isLoggedIn = app.session != null;
//     return Drawer(
//       backgroundColor: premiumCardColor,
//       child: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [premiumBackgroundColor, premiumCardColor],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [premiumPrimaryColor, premiumPrimaryColor.withOpacity(0.8)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.white,
//                     child: Icon(
//                       Icons.person,
//                       size: 50,
//                       color: premiumPrimaryColor,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   if (isLoggedIn)
//                     Text(
//                       app.session!.user.email ?? '',
//                       style: GoogleFonts.roboto(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               icon: Icons.account_circle,
//               title: 'My Account',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go(isLoggedIn ? '/account' : '/auth');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.shopping_bag,
//               title: 'My Orders',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go(isLoggedIn ? '/orders' : '/auth');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.favorite,
//               title: 'Wishlist',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go(isLoggedIn ? '/wishlist' : '/auth');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.notifications,
//               title: 'Notifications',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go(isLoggedIn ? '/notifications' : '/auth');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.receipt,
//               title: 'Transactions',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go(isLoggedIn ? '/transactions' : '/auth');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.local_offer,
//               title: 'Coupons / Offers',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go(isLoggedIn ? '/coupons' : '/auth');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.category,
//               title: 'Categories',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go('/categories');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.support_agent,
//               title: 'Contact Support',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go('/support');
//               },
//             ),
//             _buildDrawerItem(
//               icon: Icons.settings,
//               title: 'Settings',
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go('/settings');
//               },
//             ),
//             if (isLoggedIn)
//               _buildDrawerItem(
//                 icon: Icons.logout,
//                 title: 'Logout',
//                 color: premiumErrorColor,
//                 onTap: () {
//                   Navigator.pop(context);
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: Text('Logout', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
//                       content: Text('Are you sure you want to logout?', style: GoogleFonts.roboto()),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: Text('Cancel', style: GoogleFonts.roboto(color: premiumSecondaryTextColor)),
//                         ),
//                         TextButton(
//                           onPressed: () async {
//                             Navigator.pop(context);
//                             final error = await context.read<AppState>().signOut();
//                             if (error != null) {
//                               Fluttertoast.showToast(
//                                 msg: error,
//                                 backgroundColor: premiumErrorColor,
//                                 textColor: Colors.white,
//                                 fontSize: 15,
//                                 toastLength: Toast.LENGTH_LONG,
//                                 gravity: ToastGravity.TOP,
//                               );
//                             } else {
//                               context.go('/auth');
//                             }
//                           },
//                           child: Text('Logout', style: GoogleFonts.roboto(color: premiumErrorColor)),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? color,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: ScaleTransition(
//         scale: Tween<double>(begin: 1.0, end: 0.95).animate(
//           CurvedAnimation(
//             parent: AnimationController(
//               duration: const Duration(milliseconds: 200),
//               vsync: this,
//             )..forward(),
//             curve: Curves.easeInOut,
//           ),
//         ),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Row(
//             children: [
//               Icon(
//                 icon,
//                 color: color ?? premiumPrimaryColor,
//                 size: 24,
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 title,
//                 style: GoogleFonts.roboto(
//                   color: color ?? premiumTextColor,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ─── Main UI ──────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();
//     final filtered = _search.isEmpty
//         ? _products
//         : _products.where((p) => p['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();

//     if (!app.locationReady) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.location_on,
//                 size: 40,
//                 color: premiumPrimaryColor,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Finding the best deals for you...',
//                 style: GoogleFonts.roboto(
//                   fontSize: 20,
//                   color: premiumTextColor,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const CircularProgressIndicator(color: premiumPrimaryColor),
//             ],
//           ),
//         ),
//         bottomNavigationBar: const Footer(),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: premiumBackgroundColor,
//         appBar: const Header(),
//         drawer: _buildDrawer(),
//         body: _buildErrorWidget(),
//         bottomNavigationBar: const Footer(),
//       );
//     }

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: const Header(),
//       drawer: _buildDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _loadEverything,
//         color: premiumPrimaryColor,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.only(bottom: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSearchBar(),
//               const SizedBox(height: 20),
//               _buildBanners(),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Categories',
//                       style: GoogleFonts.roboto(
//                         fontSize: 20,
//                         color: premiumTextColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () => context.go('/categories'),
//                       child: Text(
//                         'See All',
//                         style: GoogleFonts.roboto(
//                           color: premiumPrimaryColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               _buildCategories(),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Products Nearby',
//                       style: GoogleFonts.roboto(
//                         fontSize: 20,
//                         color: premiumTextColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () => context.go('/products'),
//                       child: Text(
//                         'See All',
//                         style: GoogleFonts.roboto(
//                           color: premiumPrimaryColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               _buildProducts(filtered),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: const Footer(),
//     );
//   }
// }



import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../utils/supabase_utils.dart';

// Define the same premium color palette as OrderDetailsPage for consistency
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumAccentColor = Color(0xFFFFD740); // Gold
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey
const premiumShadowColor = Color(0x1A000000);
const premiumErrorColor = Color(0xFFEF4444);
const premiumSuccessColor = Color(0xFF2ECC71);

const kRadiusKm = 40.0; // Change to 10000 for testing if needed
const _bengaluru = {'lat': 12.9753, 'lon': 77.591};

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _spb = Supabase.instance.client;

  // Data
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _suggestions = [];

  // UI
  bool _loadingProducts = true;
  bool _loadingBanners = true;
  bool _loadingCategories = true;
  String? _error;
  String _search = '';
  bool _isSearchFocused = false;
  Timer? _debounce;
  int _currentBannerIndex = 0;
  String? _userName;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Animation controllers for drawer items
  final List<AnimationController> _drawerAnimationControllers = [];

  // ─── Helpers ──────────────────────────────────────────────────────────────
  double _distanceKm(Map<String, double>? a, Map<String, dynamic> b) {
    if (a == null || a.isEmpty || b['latitude'] == null || b['longitude'] == null) return 1e9;
    const R = 6371;
    final dLat = (b['latitude'] - a['lat']!) * math.pi / 180;
    final dLon = (b['longitude'] - a['lon']!) * math.pi / 180;
    final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a['lat']! * math.pi / 180) *
            math.cos(b['latitude'] * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
  }

  Map<String, double> _sanitiseCoords(Map<String, double> loc) {
    if (loc['lat']! < 5 || loc['lat']! > 40) return _bengaluru;
    return loc;
  }

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  Future<bool> _checkNetworkStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      if (!isOnline && mounted) {
        Fluttertoast.showToast(
          msg: 'No internet connection. Please check your network and try again.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
      return isOnline;
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error checking network status.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
      return false;
    }
  }

  // ─── Load Data ────────────────────────────────────────────────────────────
  Future<void> _loadCategories() async {
    if (!(await _checkNetworkStatus())) {
      setState(() => _loadingCategories = false);
      return;
    }
    setState(() => _loadingCategories = true);
    try {
      final data = (await _spb
              .from('categories')
              .select('id, name, image_url, is_restricted')
              .order('name')
              .limit(6))
          .cast<Map<String, dynamic>>();
      setState(() {
        _categories = data;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load categories. Please try again.';
        _categories = [];
      });
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load categories',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    } finally {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadBanners() async {
    if (!(await _checkNetworkStatus())) {
      setState(() => _loadingBanners = false);
      return;
    }
    setState(() => _loadingBanners = true);
    try {
      final files = await _spb.storage.from('banner-images').list(path: '');
      final banners = files
          .where((f) => f.name.endsWith('.jpg') || f.name.endsWith('.jpeg') || f.name.endsWith('.png') || f.name.endsWith('.gif'))
          .map((f) => {'url': _spb.storage.from('banner-images').getPublicUrl(f.name), 'name': f.name})
          .toList();
      setState(() {
        _banners = banners.isNotEmpty ? banners : [{'url': 'https://via.placeholder.com/1200x300', 'name': 'default'}];
      });
    } catch (e) {
      setState(() {
        _banners = [{'url': 'https://via.placeholder.com/1200x300', 'name': 'default'}];
      });
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load banners',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    } finally {
      setState(() => _loadingBanners = false);
    }
  }

  Future<void> _loadProducts() async {
    final app = context.read<AppState>();
    if (app.buyerLocation == null) {
      setState(() => _loadingProducts = false);
      return;
    }
    if (!(await _checkNetworkStatus())) {
      setState(() => _loadingProducts = false);
      return;
    }
    setState(() => _loadingProducts = true);
    final buyer = _sanitiseCoords(app.buyerLocation!);
    try {
      final sellers = (await retry(() => _spb
              .from('sellers')
              .select('id, latitude, longitude, store_name')
              .not('latitude', 'is', null)
              .not('longitude', 'is', null)))
          .cast<Map<String, dynamic>>();

      // Calculate distances and filter nearby sellers
      final nearbySellers = sellers
          .where((s) => _distanceKm(buyer, s) <= kRadiusKm)
          .map((s) => {
                ...s,
                'distance': _distanceKm(buyer, s),
              })
          .toList()
        ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      if (nearbySellers.isEmpty) {
        setState(() => _products = []);
        return;
      }

      final nearbySellerIds = nearbySellers.map((s) => s['id']).toList();

      final nonRestrictedCategories = (await _spb
              .from('categories')
              .select('id')
              .eq('is_restricted', false))
          .cast<Map<String, dynamic>>();
      final nonRestrictedCategoryIds = nonRestrictedCategories.map((cat) => cat['id']).toList();

      if (nonRestrictedCategoryIds.isEmpty) {
        setState(() => _products = []);
        return;
      }

      final productData = (await retry(() => _spb
              .from('products')
              .select('''
                id, title, price, original_price, discount_amount, images, seller_id, stock, category_id, delivery_radius_km,
                categories (id, max_delivery_radius_km, is_restricted)
              ''')
              .eq('is_approved', true)
              .eq('status', 'active')
              .inFilter('seller_id', nearbySellerIds)))
          .cast<Map<String, dynamic>>();

      final filteredProductData = productData.where((p) => p['categories'] != null && p['categories']['is_restricted'] == false).toList();

      final filteredProductIds = filteredProductData
          .where((product) {
            final seller = sellers.firstWhere((s) => s['id'] == product['seller_id'], orElse: () => {});
            if (seller.isEmpty) return false;
            final distance = _distanceKm(buyer, seller);
            final effectiveRadius = product['delivery_radius_km'] ?? product['categories']['max_delivery_radius_km'] ?? kRadiusKm;
            return distance <= effectiveRadius;
          })
          .map((p) => p['id'])
          .toList();

      if (filteredProductIds.isEmpty) {
        setState(() => _products = []);
        return;
      }

      final variantData = (await _spb
              .from('product_variants')
              .select('id, product_id, price, original_price, stock, attributes, images')
              .eq('status', 'active')
              .inFilter('product_id', filteredProductIds))
          .cast<Map<String, dynamic>>();

      final mappedProducts = filteredProductData.where((p) => filteredProductIds.contains(p['id'])).map((product) {
        final variants = variantData
            .where((v) => v['product_id'] == product['id'])
            .map((v) => {
                  'id': v['id'],
                  'price': (v['price'] as num?)?.toDouble() ?? 0.0,
                  'original_price': (v['original_price'] as num?)?.toDouble(),
                  'stock': v['stock'] ?? 0,
                  'attributes': v['attributes'] ?? {},
                  'images': v['images'] != null && (v['images'] as List).isNotEmpty ? v['images'] : product['images'],
                })
            .toList();

        final validImages = (product['images'] as List).isNotEmpty
            ? (product['images'] as List).where((img) => img is String && img.trim().isNotEmpty).toList()
            : ['https://via.placeholder.com/150'];

        return {
          'id': product['id'],
          'name': product['title'] ?? 'Unnamed Product',
          'images': validImages,
          'price': (product['price'] as num?)?.toDouble() ?? 0.0,
          'original_price': (product['original_price'] as num?)?.toDouble(),
          'discount_amount': (product['discount_amount'] as num?)?.toDouble() ?? 0.0,
          'stock': product['stock'] ?? 0,
          'category_id': product['category_id'],
          'variants': variants,
          'display_price': variants.isNotEmpty
              ? variants.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b)
              : (product['price'] as num?)?.toDouble() ?? 0.0,
          'display_original_price': variants.isNotEmpty
              ? variants.firstWhere(
                  (v) => v['price'] == variants.map((v) => v['price'] as double).reduce((a, b) => a < b ? a : b),
                  orElse: () => {'original_price': product['original_price']})['original_price']
              : product['original_price'],
          'distance': _distanceKm(buyer, sellers.firstWhere((s) => s['id'] == product['seller_id'], orElse: () => {})),
          'delivery_radius': product['delivery_radius_km'] ?? product['categories']['max_delivery_radius_km'] ?? kRadiusKm,
        };
      }).toList()
        ..sort((a, b) => a['display_price'].compareTo(b['display_price']));

      setState(() {
        _products = mappedProducts;
        _error = null;
      });
    } catch (e) {
      final errorMessage = e.toString().contains('Network') ? 'Network error. Please check your connection.' : 'Failed to load products. Please try again.';
      setState(() {
        _error = errorMessage;
        _products = [];
      });
      if (mounted) {
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    } finally {
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadUserProfile() async {
    final app = context.read<AppState>();
    if (app.session == null) return;
    try {
      final response = await _spb
          .from('profiles')
          .select('full_name')
          .eq('id', app.session!.user.id)
          .maybeSingle();
      setState(() {
        _userName = response?['full_name'] ?? 'User';
      });
    } catch (e) {
      setState(() {
        _userName = 'User';
      });
    }
  }

  Future<bool> _validateVariant(int? variantId) async {
    if (variantId == null) return true;
    try {
      final data = await _spb
          .from('product_variants')
          .select('id')
          .eq('id', variantId)
          .eq('status', 'active')
          .maybeSingle();
      if (data == null) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Selected variant is not available.',
            backgroundColor: premiumErrorColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error validating variant.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
      return false;
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product, {bool isBuyNow = false}) async {
    if (product['id'] == null || product['name'] == null || product['display_price'] == null) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Invalid product.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
      return;
    }
    if (product['stock'] <= 0 || (product['variants'].isNotEmpty && product['variants'].every((v) => v['stock'] <= 0))) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Out of stock.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
      return;
    }
    final app = context.read<AppState>();
    if (app.session == null) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: isBuyNow ? 'Please log in to proceed to checkout.' : 'Please log in to add items to cart.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
        context.go('/auth');
      }
      return;
    }
    if (!(await _checkNetworkStatus())) return;

    try {
      final categoryData = await _spb
          .from('categories')
          .select('is_restricted, max_delivery_radius_km')
          .eq('id', product['category_id'])
          .maybeSingle();
      if (categoryData?['is_restricted'] == true) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Please select this category from the categories page to ${isBuyNow ? 'proceed.' : 'add products to cart.'}',
            backgroundColor: premiumErrorColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
          context.go('/categories');
        }
        return;
      }

      final productData = await _spb
          .from('products')
          .select('id, seller_id, delivery_radius_km, category_id')
          .eq('id', product['id'])
          .eq('is_approved', true)
          .eq('status', 'active')
          .maybeSingle();
      if (productData == null) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Product is not available.',
            backgroundColor: premiumErrorColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
        }
        return;
      }

      final sellerData = await _spb
          .from('sellers')
          .select('id, latitude, longitude')
          .eq('id', productData['seller_id'])
          .maybeSingle();
      if (sellerData == null) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Seller information not available.',
            backgroundColor: premiumErrorColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
        }
        return;
      }

      final distance = _distanceKm(app.buyerLocation, sellerData);
      final effectiveRadius = productData['delivery_radius_km'] ?? categoryData?['max_delivery_radius_km'] ?? kRadiusKm;
      if (distance > effectiveRadius) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Product is not available in your area (${distance.toStringAsFixed(2)}km > ${effectiveRadius}km).',
            backgroundColor: premiumErrorColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
        }
        return;
      }

      Map<String, dynamic> itemToAdd = product;
      int? variantId;

      if (product['variants'].isNotEmpty) {
        final validVariants = product['variants'].where((v) => v['stock'] > 0 && v['price'] != null).toList();
        if (validVariants.isEmpty) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'No available variants in stock.',
              backgroundColor: premiumErrorColor,
              textColor: Colors.white,
              fontSize: 15,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
            );
          }
          return;
        }
        itemToAdd = validVariants.reduce((a, b) => a['price'] < b['price'] ? a : b);
        variantId = itemToAdd['id'] as int?;

        final isValidVariant = await _validateVariant(variantId);
        if (!isValidVariant) return;
      }

      final query = _spb
          .from('cart')
          .select('id, quantity, variant_id')
          .eq('user_id', app.session!.user.id)
          .eq('product_id', product['id']);

      if (variantId == null) {
        query.isFilter('variant_id', null);
      } else {
        query.eq('variant_id', variantId);
      }

      final existingCartItem = await query.maybeSingle();

      if (existingCartItem != null) {
        final newQuantity = existingCartItem['quantity'] + 1;
        final stockLimit = itemToAdd['stock'] as int? ?? product['stock'] as int;
        if (newQuantity > stockLimit) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Exceeds stock.',
              backgroundColor: premiumErrorColor,
              textColor: Colors.white,
              fontSize: 15,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
            );
          }
          return;
        }
        await _spb
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingCartItem['id']);
        if (mounted) {
          Fluttertoast.showToast(
            msg: '${product['name']} quantity updated in cart!',
            backgroundColor: premiumSuccessColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
        }
      } else {
        final response = await _spb.from('cart').insert({
          'user_id': app.session!.user.id,
          'product_id': product['id'],
          'variant_id': variantId,
          'quantity': 1,
          'price': itemToAdd['price'] as double? ?? product['display_price'] as double,
          'title': product['name'],
        }).select('id').maybeSingle();
        if (response == null) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Failed to add item to cart.',
              backgroundColor: premiumErrorColor,
              textColor: Colors.white,
              fontSize: 15,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
            );
          }
          return;
        }
        if (mounted) {
          Fluttertoast.showToast(
            msg: '${product['name']} added to cart!',
            backgroundColor: premiumSuccessColor,
            textColor: Colors.white,
            fontSize: 15,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
          if (isBuyNow) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              context.go('/cart');
            }
          }
        }
      }
      await app.refreshCartCount();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to add to cart: $e',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    }
  }

  Future<void> _loadEverything() async {
    setState(() {
      _loadingProducts = true;
      _loadingBanners = true;
      _loadingCategories = true;
    });
    await Future.wait([
      _loadCategories(),
      _loadBanners(),
      _loadProducts(),
      _loadUserProfile(),
    ]);
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    app.ensureBuyerLocation().then((_) => _loadEverything());
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      if (!_isSearchFocused) {
        setState(() => _suggestions = []);
      } else if (_search.isNotEmpty) {
        setState(() {
          _suggestions = _products
              .where((p) => p['name'].toString().toLowerCase().contains(_search.toLowerCase()))
              .take(5)
              .toList();
        });
      }
    });
    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () {
          setState(() {
            _search = _searchController.text.toLowerCase();
            if (_isSearchFocused && _search.isNotEmpty) {
              _suggestions = _products
                  .where((p) => p['name'].toString().toLowerCase().contains(_search))
                  .take(5)
                  .toList();
            } else {
              _suggestions = [];
            }
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (var controller in _drawerAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ─── UI Helpers ───────────────────────────────────────────────────────────
  Widget _buildShimmer({required double height, required double width}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: premiumCardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: premiumShadowColor, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: premiumErrorColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: premiumErrorColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEverything,
            style: ElevatedButton.styleFrom(
              backgroundColor: premiumPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              shadowColor: premiumShadowColor,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.roboto(
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: premiumCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearchFocused ? Colors.transparent : premiumSecondaryTextColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        gradient: _isSearchFocused
            ? LinearGradient(
                colors: [premiumPrimaryColor, premiumAccentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: premiumShadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor, size: 24),
              hintText: 'Search electronics, fashion, jewellery...',
              hintStyle: GoogleFonts.roboto(
                color: premiumSecondaryTextColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: Colors.white,
              filled: true,
            ),
            style: GoogleFonts.roboto(
              color: premiumTextColor,
              fontSize: 16,
            ),
          ),
          if (_isSearchFocused && _suggestions.isNotEmpty)
            Positioned(
              top: 68,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: premiumCardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: premiumShadowColor,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _suggestions.map((suggestion) {
                      return ListTile(
                        title: Text(
                          suggestion['name'],
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: premiumTextColor,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _searchController.text = suggestion['name'];
                            _search = suggestion['name'];
                            _isSearchFocused = false;
                            _suggestions = [];
                            _searchFocusNode.unfocus();
                          });
                          if (mounted) {
                            context.go('/products/${suggestion['id']}');
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBanners() {
    if (_loadingBanners) {
      return _buildShimmer(height: 200, width: double.infinity);
    }
    if (_banners.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: premiumShadowColor, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            'No banners available',
            style: GoogleFonts.roboto(color: premiumSecondaryTextColor, fontSize: 16),
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: premiumShadowColor, blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: CarouselSlider(
            items: _banners
                .map((banner) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: banner['url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            placeholder: (context, url) => _buildShimmer(height: 200, width: double.infinity),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.broken_image, color: premiumSecondaryTextColor)),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 15,
                          right: 15,
                          child: ElevatedButton(
                            onPressed: () => context.go('/categories'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: premiumAccentColor,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 3,
                              shadowColor: premiumShadowColor,
                            ),
                            child: Text(
                              'View Offers',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: premiumTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))
                .toList(),
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              viewportFraction: 1,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              onPageChanged: (index, reason) {
                setState(() => _currentBannerIndex = index);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == entry.key ? premiumPrimaryColor : Colors.grey[400],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    if (_loadingCategories) {
      return AnimationLimiter(
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(
            6,
            (index) => AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: 3,
              duration: const Duration(milliseconds: 600),
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _buildShimmer(height: 100, width: 140),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Text(
          'No categories available.',
          style: GoogleFonts.roboto(color: premiumSecondaryTextColor, fontSize: 16),
        ),
      );
    }
    return AnimationLimiter(
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _categories.asMap().entries.map((entry) {
          final c = entry.value;
          return AnimationConfiguration.staggeredGrid(
            position: entry.key,
            columnCount: 3,
            duration: const Duration(milliseconds: 600),
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: InkWell(
                  onTap: () => context.go('/products?category=${c['id']}&fromCategories=true'),
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: premiumCardColor,
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: c['image_url'] ?? 'https://via.placeholder.com/150x150?text=Category',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => _buildShimmer(height: 70, width: double.infinity),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: premiumSecondaryTextColor,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            c['name'].toString().trim(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              color: premiumTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProducts(List<Map<String, dynamic>> filtered) {
    if (_loadingProducts) {
      return AnimationLimiter(
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(
            6,
            (index) => AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: 2,
              duration: const Duration(milliseconds: 600),
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: premiumSecondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found nearby',
              style: GoogleFonts.roboto(
                color: premiumTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try expanding your search radius or check back later',
              style: GoogleFonts.roboto(
                color: premiumSecondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: premiumPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Browse All Products',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AnimationLimiter(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filtered.map((product) => _buildEnhancedProductCard(product)).toList(),
      ),
    );
  }

  Widget _buildDrawer() {
    final app = context.watch<AppState>();
    final isLoggedIn = app.session != null;
    return Drawer(
      backgroundColor: premiumCardColor,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [premiumBackgroundColor, premiumCardColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [premiumPrimaryColor, premiumPrimaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: premiumPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoggedIn ? 'Hello, $_userName!' : 'Welcome, Guest!',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isLoggedIn)
                    Text(
                      app.session!.user.email ?? '',
                      style: GoogleFonts.roboto(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.account_circle,
              title: 'My Account',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/account' : '/auth');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'My Orders',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/orders' : '/auth');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'Wishlist',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/wishlist' : '/auth');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/notifications' : '/auth');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.receipt,
              title: 'Transactions',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/transactions' : '/auth');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.local_offer,
              title: 'Coupons / Offers',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/coupons' : '/auth');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.category,
              title: 'Categories',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go('/categories');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.support_agent,
              title: 'Contact Support',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go('/support');
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go('/settings');
                }
              },
            ),
            if (isLoggedIn)
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                color: premiumErrorColor,
                onTap: () {
                  if (mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to logout?', style: GoogleFonts.roboto()),
                        actions: [
                          TextButton(
                            onPressed: () {
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Text('Cancel', style: GoogleFonts.roboto(color: premiumSecondaryTextColor)),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (mounted) {
                                Navigator.pop(context);
                                final error = await context.read<AppState>().signOut();
                                if (error != null) {
                                  if (mounted) {
                                    Fluttertoast.showToast(
                                      msg: error,
                                      backgroundColor: premiumErrorColor,
                                      textColor: Colors.white,
                                      fontSize: 15,
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.TOP,
                                    );
                                  }
                                } else if (mounted) {
                                  context.go('/auth');
                                }
                              }
                            },
                            child: Text('Logout', style: GoogleFonts.roboto(color: premiumErrorColor)),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _drawerAnimationControllers.add(controller);
    return InkWell(
      onTap: () {
        controller.forward().then((_) => controller.reverse());
        onTap();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOut,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: color ?? premiumPrimaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.roboto(
                  color: color ?? premiumTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Main UI ──────────────────────────────────────────────────────────────
  // ─── Enhanced UI Components ────────────────────────────────────────────────
  Widget _buildEnhancedProductCard(Map<String, dynamic> product) {
    final hasDiscount = product['original_price'] != null && product['original_price'] > product['display_price'];
    final discountPercentage = hasDiscount 
        ? ((product['original_price'] - product['display_price']) / product['original_price'] * 100).round()
        : 0;

    return AnimationConfiguration.staggeredGrid(
      position: _products.indexOf(product),
      duration: const Duration(milliseconds: 600),
      columnCount: 2,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () => context.go('/products/${product['id']}'),
            child: Container(
              decoration: BoxDecoration(
                color: premiumCardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: product['images'][0],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: premiumPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Icon(
                              Icons.image,
                              color: premiumPrimaryColor,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      if (hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: premiumErrorColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-$discountPercentage%',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (product['distance'] != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: premiumSuccessColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDistance(product['distance']),
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: GoogleFonts.roboto(
                            color: premiumTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (product['seller_name'] != null)
                          Text(
                            product['seller_name'],
                            style: GoogleFonts.roboto(
                              color: premiumSecondaryTextColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatCurrency(product['display_price']),
                              style: GoogleFonts.roboto(
                                color: premiumPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 4),
                              Text(
                                _formatCurrency(product['original_price']),
                                style: GoogleFonts.roboto(
                                  color: premiumSecondaryTextColor,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _addToCart(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: premiumPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              'Add to Cart',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final filtered = _search.isEmpty
        ? _products
        : _products.where((p) => p['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();

    if (!app.locationReady) {
      return Scaffold(
        backgroundColor: premiumBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 40,
                color: premiumPrimaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Finding the best deals for you...',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: premiumTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: premiumPrimaryColor),
            ],
          ),
        ),
        bottomNavigationBar: const Footer(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: premiumBackgroundColor,
        appBar: const Header(),
        drawer: _buildDrawer(),
        body: _buildErrorWidget(),
        bottomNavigationBar: const Footer(),
      );
    }

    return Scaffold(
      backgroundColor: premiumBackgroundColor,
      appBar: const Header(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadEverything,
        color: premiumPrimaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildBanners(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: premiumTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/categories'),
                      child: Text(
                        'See All',
                        style: GoogleFonts.roboto(
                          color: premiumPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildCategories(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Products Nearby',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: premiumTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/products'),
                      child: Text(
                        'See All',
                        style: GoogleFonts.roboto(
                          color: premiumPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildProducts(filtered),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
