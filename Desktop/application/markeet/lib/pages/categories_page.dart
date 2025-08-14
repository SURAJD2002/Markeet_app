// // lib/pages/categories_page.dart
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';

// class CategoriesPage extends StatefulWidget {
//   const CategoriesPage({super.key});
//   @override
//   State<CategoriesPage> createState() => _CategoriesPageState();
// }

// class _CategoriesPageState extends State<CategoriesPage> {
//   final _spb = Supabase.instance.client;

//   // data
//   List<Map<String, dynamic>> _cats = [];

//   // ui
//   bool _loading = true;
//   String _search = '';
//   Map<String, dynamic>? _selected;
//   Timer? _debounce;

//   // ────────── fetch ──────────────────────────────────────────────────────────
//   Future<void> _loadCats() async {
//     setState(() {
//       _loading = true;
//     });
//     final res =
//         await _spb.from('categories').select().order('name'); // * SELECT *
//     _cats = res.cast<Map<String, dynamic>>();
//     if (mounted) setState(() => _loading = false);
//   }

//   // ────────── lifecycle ──────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     _loadCats();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ────────── ui ─────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final filtered = _search.isEmpty
//         ? _cats
//         : _cats
//             .where((c) =>
//                 (c['name'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Shop by Category')),
//       body: RefreshIndicator(
//         onRefresh: _loadCats,
//         child: _loading
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//                 children: [
//                   // search bar
//                   Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: TextField(
//                       decoration: const InputDecoration(
//                         prefixIcon: Icon(Icons.search),
//                         hintText: 'Search categories…',
//                       ),
//                       onChanged: (txt) {
//                         _debounce?.cancel();
//                         _debounce = Timer(const Duration(milliseconds: 300),
//                             () => setState(() => _search = txt.toLowerCase()));
//                       },
//                     ),
//                   ),
//                   Expanded(
//                     child: filtered.isEmpty
//                         ? const Center(child: Text('No categories found.'))
//                         : GridView.count(
//                             crossAxisCount: 2,
//                             padding: const EdgeInsets.all(12),
//                             childAspectRatio: .78,
//                             children: filtered
//                                 .map(
//                                   (c) => InkWell(
//                                     onTap: () {
//                                       setState(() => _selected = c);
//                                       context.go('/products?category=${c['id']}');
//                                     },
//                                     borderRadius: BorderRadius.circular(12),
//                                     child: Card(
//                                       color: _selected?['id'] == c['id']
//                                           ? Colors.blue.shade50
//                                           : null,
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Expanded(
//                                             child: ClipRRect(
//                                               borderRadius:
//                                                   const BorderRadius.vertical(
//                                                       top: Radius.circular(12)),
//                                               child: Image.network(
//                                                 c['image_url'] ??
//                                                     'https://via.placeholder.com/150x150?text=Category',
//                                                 fit: BoxFit.cover,
//                                                 errorBuilder:
//                                                     (_, __, ___) => Image.network(
//                                                         'https://via.placeholder.com/150x150?text=Category',
//                                                         fit: BoxFit.cover),
//                                               ),
//                                             ),
//                                           ),
//                                           Padding(
//                                             padding: const EdgeInsets.all(8),
//                                             child: Text(
//                                               (c['name'] as String).trim(),
//                                               textAlign: TextAlign.center,
//                                               maxLines: 2,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: const TextStyle(
//                                                   fontWeight: FontWeight.w600),
//                                             ),
//                                           ),
//                                           TextButton(
//                                             onPressed: () => context.go(
//                                                 '/products?category=${c['id']}'),
//                                             child: const Text('View products'),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                           ),
//                   ),
//                 ],
//               ),
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

// class CategoriesPage extends StatefulWidget {
//   const CategoriesPage({super.key});
//   @override
//   State<CategoriesPage> createState() => _CategoriesPageState();
// }

// class _CategoriesPageState extends State<CategoriesPage> {
//   final _spb = Supabase.instance.client;

//   // data
//   List<Map<String, dynamic>> _cats = [];

//   // ui
//   bool _loading = true;
//   String _search = '';
//   Map<String, dynamic>? _selected;
//   Timer? _debounce;

//   // ────────── fetch ──────────────────────────────────────────────────────────
//   Future<void> _loadCats() async {
//     setState(() {
//       _loading = true;
//     });
//     try {
//       final res = await _spb.from('categories').select().order('name');
//       _cats = res.cast<Map<String, dynamic>>();
//     } catch (e) {
//       if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Network error: Unable to connect to the server. Please check your internet connection and try again.')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error fetching categories: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ────────── lifecycle ──────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     _loadCats();
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ────────── ui ─────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final filtered = _search.isEmpty
//         ? _cats
//         : _cats
//             .where((c) =>
//                 (c['name'] as String).toLowerCase().contains(_search))
//             .toList();

//     return Scaffold(
//       appBar: AppBar(title: const Text('Shop by Category')),
//       body: RefreshIndicator(
//         onRefresh: _loadCats,
//         child: _loading
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//                 children: [
//                   // search bar
//                   Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: TextField(
//                       decoration: const InputDecoration(
//                         prefixIcon: Icon(Icons.search),
//                         hintText: 'Search categories…',
//                       ),
//                       onChanged: (txt) {
//                         _debounce?.cancel();
//                         _debounce = Timer(const Duration(milliseconds: 300),
//                             () => setState(() => _search = txt.toLowerCase()));
//                       },
//                     ),
//                   ),
//                   Expanded(
//                     child: filtered.isEmpty
//                         ? const Center(child: Text('No categories found.'))
//                         : GridView.count(
//                             crossAxisCount: 2,
//                             padding: const EdgeInsets.all(12),
//                             childAspectRatio: .78,
//                             children: filtered
//                                 .map(
//                                   (c) => InkWell(
//                                     onTap: () {
//                                       setState(() => _selected = c);
//                                       context.go('/products?category=${c['id']}');
//                                     },
//                                     borderRadius: BorderRadius.circular(12),
//                                     child: Card(
//                                       color: _selected?['id'] == c['id']
//                                           ? Colors.blue.shade50
//                                           : null,
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Expanded(
//                                             child: ClipRRect(
//                                               borderRadius:
//                                                   const BorderRadius.vertical(
//                                                       top: Radius.circular(12)),
//                                               child: Image.network(
//                                                 c['image_url'] ??
//                                                     'https://via.placeholder.com/150x150?text=Category',
//                                                 fit: BoxFit.cover,
//                                                 errorBuilder:
//                                                     (_, __, ___) => const Icon(Icons.broken_image, size: 50),
//                                               ),
//                                             ),
//                                           ),
//                                           Padding(
//                                             padding: const EdgeInsets.all(8),
//                                             child: Text(
//                                               (c['name'] as String).trim(),
//                                               textAlign: TextAlign.center,
//                                               maxLines: 2,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: const TextStyle(
//                                                   fontWeight: FontWeight.w600),
//                                             ),
//                                           ),
//                                           TextButton(
//                                             onPressed: () => context.go(
//                                                 '/products?category=${c['id']}'),
//                                             child: const Text('View products'),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                           ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define the premium color palette
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumAccentColor = Color(0xFFFFD740); // Gold
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _spb = Supabase.instance.client;

  // Data
  List<Map<String, dynamic>> _cats = [];
  bool _loading = true;
  String _search = '';
  Map<String, dynamic>? _selected;
  Timer? _debounce;
  String? _error;

  Future<void> _loadCats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _spb.from('categories').select().order('name');
      setState(() {
        _cats = res.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        setState(() => _error = 'Network error: Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        setState(() => _error = 'Error fetching categories: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _cats
        : _cats.where((c) => (c['name'] as String).toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: premiumBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Shop by Category',
          style: TextStyle(
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadCats,
        color: premiumPrimaryColor,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: premiumPrimaryColor))
            : _error != null
                ? Center(
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
                          onPressed: _loadCats,
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
                  )
                : Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor),
                            hintText: 'Search categories…',
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
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No categories found.', style: TextStyle(color: premiumTextColor)))
                            : GridView.count(
                                crossAxisCount: 2,
                                padding: const EdgeInsets.all(12),
                                childAspectRatio: 0.78,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                children: filtered.map((c) {
                                  final isSelected = _selected?['id'] == c['id'];
                                  return InkWell(
                                    onTap: () {
                                      setState(() => _selected = c);
                                      context.go('/products?category=${c['id']}');
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      color: isSelected ? premiumPrimaryColor.withOpacity(0.1) : premiumCardColor,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                              child: Image.network(
                                                c['image_url'] ?? 'https://via.placeholder.com/150x150?text=Category',
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
                                                  size: 50,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              (c['name'] as String).trim(),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isSelected ? premiumPrimaryColor : premiumTextColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: OutlinedButton(
                                              onPressed: () => context.go('/products?category=${c['id']}'),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: isSelected ? premiumPrimaryColor : premiumSecondaryTextColor,
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                'View Products',
                                                style: TextStyle(
                                                  color: isSelected ? premiumPrimaryColor : premiumSecondaryTextColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}