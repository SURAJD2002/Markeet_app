// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'state/app_state.dart';

// /* ───────── shared chrome ───────── */
// import 'widgets/header.dart';
// import 'widgets/footer.dart';

// /* ───────── concrete pages ───────── */
// import 'pages/home_page.dart';
// import 'pages/product_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/categories_page.dart';
// import 'pages/checkout_page.dart';
// import 'pages/account_page.dart';
// import 'pages/auth_page.dart';
// import 'pages/seller_page.dart';
// import 'pages/add_product_page.dart';
// import 'pages/order_details_page.dart';
// import 'pages/apply_emi_page.dart';
// import 'pages/placeholder_page.dart';
// import 'pages/cancel_order_page.dart'; // Added import for CancelOrderPage

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   /* .env */
//   await dotenv.load(fileName: ".env");

//   /* Supabase */
//   try {
//     await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL']!,
//       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
//       debug: true, // Enable debug logs for troubleshooting
//     );
//   } catch (e) {
//     debugPrint('Failed to initialize Supabase: $e');
//   }

//   runApp(const MarkeetApp());
// }

// class MarkeetApp extends StatelessWidget {
//   const MarkeetApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppState(),
//       child: Consumer<AppState>(
//         builder: (context, app, _) => MaterialApp.router(
//           title: 'Markeet',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(useMaterial3: true),
//           routerConfig: _router(app),
//         ),
//       ),
//     );
//   }

//   /* ─────────────── Router ─────────────── */

//   GoRouter _router(AppState app) => GoRouter(
//         refreshListenable: app,
//         initialLocation: '/',
//         redirect: (_, state) {
//           final loggedIn = app.session != null;
//           final onAuthPage = state.matchedLocation == '/auth';
//           debugPrint('Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
//           if (!loggedIn && !onAuthPage) {
//             debugPrint('Redirecting to /auth');
//             return '/auth';
//           }
//           if (loggedIn && onAuthPage) {
//             debugPrint('Redirecting to /');
//             return '/';
//           }
//           return null;
//         },
//         routes: [
//           /* HOME */
//           GoRoute(
//             path: '/',
//             name: 'home',
//             pageBuilder: (_, __) => _chrome(const HomePage()),
//           ),

//           /* PRODUCT DETAILS */
//           GoRoute(
//             path: '/product/:id',
//             name: 'product',
//             pageBuilder: (ctx, st) =>
//                 _chrome(ProductPage(id: st.pathParameters['id']!)),
//           ),

//           /* CART */
//           GoRoute(
//             path: '/cart',
//             name: 'cart',
//             pageBuilder: (_, __) => _chrome(const CartPage()),
//           ),

//           /* CATEGORIES */
//           GoRoute(
//             path: '/categories',
//             name: 'categories',
//             pageBuilder: (_, __) => _chrome(const CategoriesPage()),
//           ),

//           /* CHECKOUT */
//           GoRoute(
//             path: '/checkout',
//             name: 'checkout',
//             pageBuilder: (_, __) => _chrome(const CheckoutPage()),
//           ),

//           /* ACCOUNT */
//           GoRoute(
//             path: '/account',
//             name: 'account',
//             pageBuilder: (_, __) => _chrome(const AccountPage()),
//           ),

//           /* ORDERS */
//           GoRoute(
//             path: '/orders',
//             name: 'orders',
//             pageBuilder: _ph('Orders'),
//           ),

//           /* CANCEL ORDER */
//           GoRoute(
//             path: '/orders/cancel/:id',
//             name: 'cancel-order',
//             pageBuilder: (ctx, st) =>
//                 _chrome(CancelOrderPage(id: st.pathParameters['id']!)),
//           ),

//           /* AUTH (no chrome) */
//           GoRoute(
//             path: '/auth',
//             name: 'auth',
//             pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
//           ),

//           /* SELLER DASHBOARD */
//           GoRoute(
//             path: '/seller',
//             name: 'seller',
//             pageBuilder: (_, __) => _chrome(const SellerPage()),
//           ),

//           /* ADD PRODUCT */
//           GoRoute(
//             path: '/seller/add-product',
//             name: 'add-product',
//             pageBuilder: (_, __) => _chrome(const AddProductPage()),
//           ),

//           /* ORDER DETAILS */
//           GoRoute(
//             path: '/order-details/:id',
//             name: 'order-details',
//             pageBuilder: (ctx, st) =>
//                 _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
//           ),

//           /* APPLY EMI */
//           GoRoute(
//             path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
//             name: 'apply-emi',
//             pageBuilder: (ctx, st) => _chrome(
//               ApplyEMIPage(
//                 productId: st.pathParameters['productId']!,
//                 productName: Uri.decodeComponent(st.pathParameters['productName']!),
//                 productPrice: double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
//                 sellerId: st.pathParameters['sellerId']!,
//               ),
//             ),
//           ),
//         ],
//       );

//   /* ───────── chrome helpers ───────── */

//   /// Wrap every “normal” page with AppBar & Bottom nav.
//   Page<dynamic> _chrome(Widget child) => MaterialPage(
//         child: Scaffold(
//           appBar: const Header(),
//           body: child,
//           bottomNavigationBar: const FooterNav(),
//         ),
//       );

//   /// Quick helper for placeholder pages.
//   Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
//       (_, __) => _chrome(PlaceholderPage(title));
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'state/app_state.dart';

// /* ───────── shared chrome ───────── */
// import 'widgets/header.dart';
// import 'widgets/footer.dart';

// /* ───────── concrete pages ───────── */
// import 'pages/home_page.dart';
// import 'pages/product_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/categories_page.dart';
// import 'pages/checkout_page.dart';
// import 'pages/account_page.dart';
// import 'pages/auth_page.dart';
// import 'pages/seller_page.dart';
// import 'pages/add_product_page.dart';
// import 'pages/order_details_page.dart';
// import 'pages/apply_emi_page.dart';
// import 'pages/placeholder_page.dart';
// import 'pages/cancel_order_page.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   /* .env */
//   await dotenv.load(fileName: ".env");

//   /* Supabase */
//   try {
//     await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL']!,
//       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
//       debug: true,
//     );
//   } catch (e) {
//     debugPrint('Failed to initialize Supabase: $e');
//   }

//   runApp(const MarkeetApp());
// }

// class MarkeetApp extends StatelessWidget {
//   const MarkeetApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppState(),
//       child: Consumer<AppState>(
//         builder: (context, app, _) => MaterialApp.router(
//           title: 'Markeet',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             useMaterial3: true,
//             primaryColor: const Color(0xFF1A237E), // Deep Indigo
//             scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey
//             cardColor: Colors.white,
//             textTheme: const TextTheme(
//               titleLarge: TextStyle(
//                 color: Color(0xFF212121), // Dark Grey
//                 fontWeight: FontWeight.bold,
//               ),
//               bodyMedium: TextStyle(color: Color(0xFF757575)), // Medium Grey
//             ),
//             elevatedButtonTheme: ElevatedButtonThemeData(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1A237E), // Deep Indigo
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             outlinedButtonTheme: OutlinedButtonThemeData(
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Color(0xFF1A237E)),
//                 foregroundColor: const Color(0xFF1A237E),
//               ),
//             ),
//           ),
//           routerConfig: _router(app),
//         ),
//       ),
//     );
//   }

//   /* ─────────────── Router ─────────────── */

//   GoRouter _router(AppState app) => GoRouter(
//         refreshListenable: app,
//         initialLocation: '/',
//         redirect: (_, state) {
//           final loggedIn = app.session != null;
//           final onAuthPage = state.matchedLocation == '/auth';
//           debugPrint(
//               'Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
//           if (!loggedIn && !onAuthPage) {
//             debugPrint('Redirecting to /auth');
//             return '/auth';
//           }
//           if (loggedIn && onAuthPage) {
//             debugPrint('Redirecting to /');
//             return '/';
//           }
//           return null;
//         },
//         routes: [
//           /* HOME */
//           GoRoute(
//             path: '/',
//             name: 'home',
//             pageBuilder: (_, __) => const MaterialPage(child: HomePage()), // No _chrome for HomePage
//           ),

//           /* PRODUCT DETAILS */
//           GoRoute(
//             path: '/product/:id',
//             name: 'product',
//             pageBuilder: (ctx, st) =>
//                 _chrome(ProductPage(id: st.pathParameters['id']!)),
//           ),

//           /* CART */
//           GoRoute(
//             path: '/cart',
//             name: 'cart',
//             pageBuilder: (_, __) => _chrome(const CartPage()),
//           ),

//           /* CATEGORIES */
//           GoRoute(
//             path: '/categories',
//             name: 'categories',
//             pageBuilder: (_, __) => _chrome(const CategoriesPage()),
//           ),

//           /* CATEGORY DETAIL */
//           GoRoute(
//             path: '/categories/:id',
//             name: 'category-detail',
//             pageBuilder: (ctx, st) => _chrome(
//               PlaceholderPage('Category: ${st.pathParameters['id']}'),
//             ),
//           ),

//           /* CHECKOUT */
//           GoRoute(
//             path: '/checkout',
//             name: 'checkout',
//             pageBuilder: (_, __) => _chrome(const CheckoutPage()),
//           ),

//           /* ACCOUNT */
//           GoRoute(
//             path: '/account',
//             name: 'account',
//             pageBuilder: (_, __) => _chrome(const AccountPage()),
//           ),

//           /* ORDERS */
//           GoRoute(
//             path: '/orders',
//             name: 'orders',
//             pageBuilder: _ph('Orders'),
//           ),

//           /* CANCEL ORDER */
//           GoRoute(
//             path: '/orders/cancel/:id',
//             name: 'cancel-order',
//             pageBuilder: (ctx, st) =>
//                 _chrome(CancelOrderPage(id: st.pathParameters['id']!)),
//           ),

//           /* WISHLIST */
//           GoRoute(
//             path: '/wishlist',
//             name: 'wishlist',
//             pageBuilder: _ph('Wishlist'),
//           ),

//           /* NOTIFICATIONS */
//           GoRoute(
//             path: '/notifications',
//             name: 'notifications',
//             pageBuilder: _ph('Notifications'),
//           ),

//           /* TRANSACTIONS */
//           GoRoute(
//             path: '/transactions',
//             name: 'transactions',
//             pageBuilder: _ph('Transactions'),
//           ),

//           /* COUPONS / OFFERS */
//           GoRoute(
//             path: '/coupons',
//             name: 'coupons',
//             pageBuilder: _ph('Coupons / Offers'),
//           ),

//           /* SUPPORT */
//           GoRoute(
//             path: '/support',
//             name: 'support',
//             pageBuilder: _ph('Contact Support'),
//           ),

//           /* SETTINGS */
//           GoRoute(
//             path: '/settings',
//             name: 'settings',
//             pageBuilder: _ph('Settings'),
//           ),

//           /* AUTH (no chrome) */
//           GoRoute(
//             path: '/auth',
//             name: 'auth',
//             pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
//           ),

//           /* SELLER DASHBOARD */
//           GoRoute(
//             path: '/seller',
//             name: 'seller',
//             pageBuilder: (_, __) => _chrome(const SellerPage()),
//           ),

//           /* ADD PRODUCT */
//           GoRoute(
//             path: '/seller/add-product',
//             name: 'add-product',
//             pageBuilder: (_, __) => _chrome(const AddProductPage()),
//           ),

//           /* ORDER DETAILS */
//           GoRoute(
//             path: '/order-details/:id',
//             name: 'order-details',
//             pageBuilder: (ctx, st) =>
//                 _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
//           ),

//           /* APPLY EMI */
//           GoRoute(
//             path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
//             name: 'apply-emi',
//             pageBuilder: (ctx, st) => _chrome(
//               ApplyEMIPage(
//                 productId: st.pathParameters['productId']!,
//                 productName: Uri.decodeComponent(st.pathParameters['productName']!),
//                 productPrice:
//                     double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
//                 sellerId: st.pathParameters['sellerId']!,
//               ),
//             ),
//           ),
//         ],
//       );

//   /* ───────── chrome helpers ───────── */

//   /// Wrap every “normal” page with AppBar & Bottom nav, except for HomePage.
//   Page<dynamic> _chrome(Widget child) => MaterialPage(
//         child: Scaffold(
//           appBar: const Header(),
//           body: child,
//           bottomNavigationBar: const FooterNav(),
//         ),
//       );

//   /// Quick helper for placeholder pages.
//   Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
//       (_, __) => _chrome(PlaceholderPage(title));
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'state/app_state.dart';

// /* ───────── shared chrome ───────── */
// import 'widgets/header.dart';
// import 'widgets/footer.dart';

// /* ───────── concrete pages ───────── */
// import 'pages/home_page.dart';
// import 'pages/products_page.dart'; // Import the new ProductsPage
// import 'pages/product_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/categories_page.dart';
// import 'pages/checkout_page.dart';
// import 'pages/account_page.dart';
// import 'pages/auth_page.dart';
// import 'pages/seller_page.dart';
// import 'pages/add_product_page.dart';
// import 'pages/order_details_page.dart';
// import 'pages/apply_emi_page.dart';
// import 'pages/placeholder_page.dart';
// import 'pages/cancel_order_page.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   /* .env */
//   await dotenv.load(fileName: ".env");

//   /* Supabase */
//   try {
//     await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL']!,
//       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
//       debug: true,
//     );
//   } catch (e) {
//     debugPrint('Failed to initialize Supabase: $e');
//   }

//   runApp(const MarkeetApp());
// }

// class MarkeetApp extends StatelessWidget {
//   const MarkeetApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppState(),
//       child: Consumer<AppState>(
//         builder: (context, app, _) => MaterialApp.router(
//           title: 'Markeet',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             useMaterial3: true,
//             primaryColor: const Color(0xFF1A237E), // Deep Indigo
//             scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey
//             cardColor: Colors.white,
//             textTheme: const TextTheme(
//               titleLarge: TextStyle(
//                 color: Color(0xFF212121), // Dark Grey
//                 fontWeight: FontWeight.bold,
//               ),
//               bodyMedium: TextStyle(color: Color(0xFF757575)), // Medium Grey
//             ),
//             elevatedButtonTheme: ElevatedButtonThemeData(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1A237E), // Deep Indigo
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             outlinedButtonTheme: OutlinedButtonThemeData(
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Color(0xFF1A237E)),
//                 foregroundColor: const Color(0xFF1A237E),
//               ),
//             ),
//           ),
//           routerConfig: _router(app),
//         ),
//       ),
//     );
//   }

//   /* ─────────────── Router ─────────────── */

//   GoRouter _router(AppState app) => GoRouter(
//         refreshListenable: app,
//         initialLocation: '/',
//         redirect: (_, state) {
//           final loggedIn = app.session != null;
//           final onAuthPage = state.matchedLocation == '/auth';
//           debugPrint(
//               'Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
//           if (!loggedIn && !onAuthPage) {
//             debugPrint('Redirecting to /auth');
//             return '/auth';
//           }
//           if (loggedIn && onAuthPage) {
//             debugPrint('Redirecting to /');
//             return '/';
//           }
//           return null;
//         },
//         routes: [
//           /* HOME */
//           GoRoute(
//             path: '/',
//             name: 'home',
//             pageBuilder: (_, __) => const MaterialPage(child: HomePage()), // No _chrome for HomePage
//           ),

//           /* PRODUCTS (Category-specific product listing) */
//           GoRoute(
//             path: '/products',
//             name: 'products',
//             pageBuilder: (ctx, st) {
//               final categoryId = st.uri.queryParameters['category'];
//               return _chrome(ProductsPage(categoryId: categoryId));
//             },
//           ),

//           /* PRODUCT DETAILS */
//           GoRoute(
//             path: '/products/:id',
//             name: 'product',
//             pageBuilder: (ctx, st) =>
//                 _chrome(ProductPage(id: st.pathParameters['id']!)),
//           ),

//           /* CART */
//           GoRoute(
//             path: '/cart',
//             name: 'cart',
//             pageBuilder: (_, __) => _chrome(const CartPage()),
//           ),

//           /* CATEGORIES */
//           GoRoute(
//             path: '/categories',
//             name: 'categories',
//             pageBuilder: (_, __) => _chrome(const CategoriesPage()),
//           ),

//           /* CHECKOUT */
//           GoRoute(
//             path: '/checkout',
//             name: 'checkout',
//             pageBuilder: (_, __) => _chrome(const CheckoutPage()),
//           ),

//           /* ACCOUNT */
//           GoRoute(
//             path: '/account',
//             name: 'account',
//             pageBuilder: (_, __) => _chrome(const AccountPage()),
//           ),

//           /* ORDERS */
//           GoRoute(
//             path: '/orders',
//             name: 'orders',
//             pageBuilder: _ph('Orders'),
//           ),

//           /* CANCEL ORDER */
//           GoRoute(
//             path: '/orders/cancel/:id',
//             name: 'cancel-order',
//             pageBuilder: (ctx, st) =>
//                 _chrome(CancelOrderPage(id: st.pathParameters['id']!)),
//           ),

//           /* WISHLIST */
//           GoRoute(
//             path: '/wishlist',
//             name: 'wishlist',
//             pageBuilder: _ph('Wishlist'),
//           ),

//           /* NOTIFICATIONS */
//           GoRoute(
//             path: '/notifications',
//             name: 'notifications',
//             pageBuilder: _ph('Notifications'),
//           ),

//           /* TRANSACTIONS */
//           GoRoute(
//             path: '/transactions',
//             name: 'transactions',
//             pageBuilder: _ph('Transactions'),
//           ),

//           /* COUPONS / OFFERS */
//           GoRoute(
//             path: '/coupons',
//             name: 'coupons',
//             pageBuilder: _ph('Coupons / Offers'),
//           ),

//           /* SUPPORT */
//           GoRoute(
//             path: '/support',
//             name: 'support',
//             pageBuilder: _ph('Contact Support'),
//           ),

//           /* SETTINGS */
//           GoRoute(
//             path: '/settings',
//             name: 'settings',
//             pageBuilder: _ph('Settings'),
//           ),

//           /* AUTH (no chrome) */
//           GoRoute(
//             path: '/auth',
//             name: 'auth',
//             pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
//           ),

//           /* SELLER DASHBOARD */
//           GoRoute(
//             path: '/seller',
//             name: 'seller',
//             pageBuilder: (_, __) => _chrome(const SellerPage()),
//           ),

//           /* ADD PRODUCT */
//           GoRoute(
//             path: '/seller/add-product',
//             name: 'add-product',
//             pageBuilder: (_, __) => _chrome(const AddProductPage()),
//           ),

//           /* ORDER DETAILS */
//           GoRoute(
//             path: '/order-details/:id',
//             name: 'order-details',
//             pageBuilder: (ctx, st) =>
//                 _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
//           ),

//           /* APPLY EMI */
//           GoRoute(
//             path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
//             name: 'apply-emi',
//             pageBuilder: (ctx, st) => _chrome(
//               ApplyEMIPage(
//                 productId: st.pathParameters['productId']!,
//                 productName: Uri.decodeComponent(st.pathParameters['productName']!),
//                 productPrice:
//                     double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
//                 sellerId: st.pathParameters['sellerId']!,
//               ),
//             ),
//           ),
//         ],
//       );

//   /* ───────── chrome helpers ───────── */

//   /// Wrap every “normal” page with AppBar & Bottom nav, except for HomePage.
//   Page<dynamic> _chrome(Widget child) => MaterialPage(
//         child: Scaffold(
//           appBar: const Header(),
//           body: child,
//           bottomNavigationBar: const FooterNav(),
//         ),
//       );

//   /// Quick helper for placeholder pages.
//   Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
//       (_, __) => _chrome(PlaceholderPage(title));
// }


// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'state/app_state.dart';

// /* ───────── shared chrome ───────── */
// import 'widgets/header.dart';
// import 'widgets/footer.dart';

// /* ───────── concrete pages ───────── */
// import 'pages/home_page.dart';
// import 'pages/products_page.dart';
// import 'pages/product_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/categories_page.dart';
// import 'pages/checkout_page.dart';
// import 'pages/account_page.dart';
// import 'pages/auth_page.dart';
// import 'pages/seller_page.dart';
// import 'pages/add_product_page.dart';
// import 'pages/order_details_page.dart';
// import 'pages/apply_emi_page.dart';
// import 'pages/placeholder_page.dart';
// import 'pages/orders_page.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   /* .env */
//   await dotenv.load(fileName: ".env");

//   /* Supabase */
//   try {
//     await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL']!,
//       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
//       debug: true,
//     );
//   } catch (e) {
//     debugPrint('Failed to initialize Supabase: $e');
//   }

//   runApp(const MarkeetApp());
// }

// class MarkeetApp extends StatelessWidget {
//   const MarkeetApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppState(),
//       child: Consumer<AppState>(
//         builder: (context, app, _) => MaterialApp.router(
//           title: 'Markeet',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             useMaterial3: true,
//             primaryColor: const Color(0xFF1A237E), // Deep Indigo
//             scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey
//             cardColor: Colors.white,
//             textTheme: const TextTheme(
//               titleLarge: TextStyle(
//                 color: Color(0xFF212121), // Dark Grey
//                 fontWeight: FontWeight.bold,
//               ),
//               bodyMedium: TextStyle(color: Color(0xFF757575)), // Medium Grey
//             ),
//             elevatedButtonTheme: ElevatedButtonThemeData(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1A237E), // Deep Indigo
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             outlinedButtonTheme: OutlinedButtonThemeData(
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Color(0xFF1A237E)),
//                 foregroundColor: const Color(0xFF1A237E),
//               ),
//             ),
//           ),
//           routerConfig: _router(app),
//         ),
//       ),
//     );
//   }

//   /* ─────────────── Router ─────────────── */

//   GoRouter _router(AppState app) => GoRouter(
//         refreshListenable: app,
//         initialLocation: '/',
//         redirect: (_, state) {
//           final loggedIn = app.session != null;
//           final onAuthPage = state.matchedLocation == '/auth';
//           debugPrint(
//               'Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
//           if (!loggedIn && !onAuthPage) {
//             debugPrint('Redirecting to /auth');
//             return '/auth';
//           }
//           if (loggedIn && onAuthPage) {
//             debugPrint('Redirecting to /');
//             return '/';
//           }
//           return null;
//         },
//         routes: [
//           /* HOME */
//           GoRoute(
//             path: '/',
//             name: 'home',
//             pageBuilder: (_, __) => const MaterialPage(child: HomePage()),
//           ),

//           /* PRODUCTS (Category-specific product listing) */
//           GoRoute(
//             path: '/products',
//             name: 'products',
//             pageBuilder: (ctx, st) {
//               final categoryId = st.uri.queryParameters['category'];
//               return _chrome(ProductsPage(categoryId: categoryId));
//             },
//           ),

//           /* PRODUCT DETAILS */
//           GoRoute(
//             path: '/products/:id',
//             name: 'product',
//             pageBuilder: (ctx, st) =>
//                 _chrome(ProductPage(id: st.pathParameters['id']!)),
//           ),

//           /* CART */
//           GoRoute(
//             path: '/cart',
//             name: 'cart',
//             pageBuilder: (_, __) => _chrome(const CartPage()),
//           ),

//           /* CATEGORIES */
//           GoRoute(
//             path: '/categories',
//             name: 'categories',
//             pageBuilder: (_, __) => _chrome(const CategoriesPage()),
//           ),

//           /* CHECKOUT */
//           GoRoute(
//             path: '/checkout',
//             name: 'checkout',
//             pageBuilder: (_, __) => _chrome(const CheckoutPage()),
//           ),

//           /* ACCOUNT */
//           GoRoute(
//             path: '/account',
//             name: 'account',
//             pageBuilder: (_, __) => _chrome(const AccountPage()),
//           ),

//           /* ORDERS */
//           GoRoute(
//             path: '/orders',
//             name: 'orders',
//             pageBuilder: (_, __) => _chrome(const OrdersPage()),
//           ),

//           /* CANCEL ORDER */
//           GoRoute(
//             path: '/orders/cancel/:id',
//             name: 'cancel-order',
//             pageBuilder: (ctx, st) => _chrome(const OrdersPage()),
//           ),

//           /* WISHLIST */
//           GoRoute(
//             path: '/wishlist',
//             name: 'wishlist',
//             pageBuilder: _ph('Wishlist'),
//           ),

//           /* NOTIFICATIONS */
//           GoRoute(
//             path: '/notifications',
//             name: 'notifications',
//             pageBuilder: _ph('Notifications'),
//           ),

//           /* TRANSACTIONS */
//           GoRoute(
//             path: '/transactions',
//             name: 'transactions',
//             pageBuilder: _ph('Transactions'),
//           ),

//           /* COUPONS / OFFERS */
//           GoRoute(
//             path: '/coupons',
//             name: 'coupons',
//             pageBuilder: _ph('Coupons / Offers'),
//           ),

//           /* SUPPORT */
//           GoRoute(
//             path: '/support',
//             name: 'support',
//             pageBuilder: _ph('Contact Support'),
//           ),

//           /* SETTINGS */
//           GoRoute(
//             path: '/settings',
//             name: 'settings',
//             pageBuilder: _ph('Settings'),
//           ),

//           /* AUTH (no chrome) */
//           GoRoute(
//             path: '/auth',
//             name: 'auth',
//             pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
//           ),

//           /* SELLER DASHBOARD */
//           GoRoute(
//             path: '/seller',
//             name: 'seller',
//             pageBuilder: (_, __) => _chrome(const SellerPage()),
//           ),

//           /* ADD PRODUCT */
//           GoRoute(
//             path: '/seller/add-product',
//             name: 'add-product',
//             pageBuilder: (_, __) => _chrome(const AddProductPage()),
//           ),

//           /* ORDER DETAILS */
//           GoRoute(
//             path: '/order-details/:id',
//             name: 'order-details',
//             pageBuilder: (ctx, st) =>
//                 _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
//           ),

//           /* APPLY EMI */
//           GoRoute(
//             path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
//             name: 'apply-emi',
//             pageBuilder: (ctx, st) => _chrome(
//               ApplyEMIPage(
//                 productId: st.pathParameters['productId']!,
//                 productName: Uri.decodeComponent(st.pathParameters['productName']!),
//                 productPrice:
//                     double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
//                 sellerId: st.pathParameters['sellerId']!,
//               ),
//             ),
//           ),
//         ],
//       );

//   /* ───────── chrome helpers ───────── */

//   /// Wrap every “normal” page with AppBar, Drawer & Bottom nav, except for HomePage.
//   Page<dynamic> _chrome(Widget child) => MaterialPage(
//         child: _ScaffoldWithDrawer(
//           child: child,
//         ),
//       );

//   /// Quick helper for placeholder pages.
//   Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
//       (_, __) => _chrome(PlaceholderPage(title));
// }

// class _ScaffoldWithDrawer extends StatelessWidget {
//   final Widget child;

//   const _ScaffoldWithDrawer({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const Header(),
//       drawer: const Header().buildDrawer(context), // Updated to use public method
//       body: child,
//       bottomNavigationBar: const FooterNav(),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'state/app_state.dart';

// /* ───────── shared chrome ───────── */
// import 'widgets/header.dart';
// import 'widgets/footer.dart';

// /* ───────── concrete pages ───────── */
// import 'pages/home_page.dart';
// import 'pages/products_page.dart';
// import 'pages/product_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/categories_page.dart';
// import 'pages/checkout_page.dart';
// import 'pages/account_page.dart';
// import 'pages/auth_page.dart';
// import 'pages/seller_page.dart';
// import 'pages/add_product_page.dart';
// import 'pages/order_details_page.dart';
// import 'pages/apply_emi_page.dart';
// import 'pages/placeholder_page.dart';
// import 'pages/orders_page.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   /* .env */
//   await dotenv.load(fileName: ".env");

//   /* Supabase */
//   try {
//     await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL']!,
//       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
//       debug: true,
//     );
//   } catch (e) {
//     debugPrint('Failed to initialize Supabase: $e');
//   }

//   runApp(const MarkeetApp());
// }

// class MarkeetApp extends StatelessWidget {
//   const MarkeetApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppState(),
//       child: Consumer<AppState>(
//         builder: (context, app, _) => MaterialApp.router(
//           title: 'Markeet',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             useMaterial3: true,
//             primaryColor: const Color(0xFF1A237E), // Deep Indigo
//             scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey
//             cardColor: Colors.white,
//             textTheme: const TextTheme(
//               titleLarge: TextStyle(
//                 color: Color(0xFF212121), // Dark Grey
//                 fontWeight: FontWeight.bold,
//               ),
//               bodyMedium: TextStyle(color: Color(0xFF757575)), // Medium Grey
//             ),
//             elevatedButtonTheme: ElevatedButtonThemeData(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1A237E), // Deep Indigo
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             outlinedButtonTheme: OutlinedButtonThemeData(
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Color(0xFF1A237E)),
//                 foregroundColor: const Color(0xFF1A237E),
//               ),
//             ),
//           ),
//           routerConfig: _router(app),
//         ),
//       ),
//     );
//   }

//   /* ─────────────── Router ─────────────── */

//   GoRouter _router(AppState app) => GoRouter(
//         refreshListenable: app,
//         initialLocation: '/',
//         redirect: (_, state) {
//           final loggedIn = app.session != null;
//           final onAuthPage = state.matchedLocation == '/auth';
//           debugPrint(
//               'Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
//           if (!loggedIn && !onAuthPage && state.matchedLocation != '/auth') {
//             debugPrint('Redirecting to /auth');
//             return '/auth';
//           }
//           if (loggedIn && onAuthPage) {
//             debugPrint('Redirecting to /');
//             return '/';
//           }
//           return null;
//         },
//         routes: [
//           /* HOME */
//           GoRoute(
//             path: '/',
//             name: 'home',
//             pageBuilder: (_, __) => const MaterialPage(child: HomePage()),
//           ),

//           /* PRODUCTS (Category-specific product listing) */
//           GoRoute(
//             path: '/products',
//             name: 'products',
//             pageBuilder: (ctx, st) {
//               final categoryId = st.uri.queryParameters['category'];
//               return _chrome(ProductsPage(categoryId: categoryId));
//             },
//           ),

//           /* PRODUCT DETAILS */
//           GoRoute(
//             path: '/products/:id',
//             name: 'product',
//             pageBuilder: (ctx, st) =>
//                 _chrome(ProductPage(id: st.pathParameters['id']!)),
//           ),

//           /* CART */
//           GoRoute(
//             path: '/cart',
//             name: 'cart',
//             pageBuilder: (_, __) => _chrome(const CartPage()),
//           ),

//           /* CATEGORIES */
//           GoRoute(
//             path: '/categories',
//             name: 'categories',
//             pageBuilder: (_, __) => _chrome(const CategoriesPage()),
//           ),

//           /* CHECKOUT */
//           GoRoute(
//             path: '/checkout',
//             name: 'checkout',
//             pageBuilder: (_, __) => _chrome(const CheckoutPage()),
//           ),

//           /* ACCOUNT */
//           GoRoute(
//             path: '/account',
//             name: 'account',
//             pageBuilder: (_, __) => _chrome(const AccountPage()),
//           ),

//           /* ORDERS */
//           GoRoute(
//             path: '/orders',
//             name: 'orders',
//             pageBuilder: (_, __) => _chrome(const OrdersPage()),
//           ),

//           /* CANCEL ORDER */
//           GoRoute(
//             path: '/orders/cancel/:id',
//             name: 'cancel-order',
//             pageBuilder: (ctx, st) => _chrome(const OrdersPage()),
//           ),

//           /* WISHLIST */
//           GoRoute(
//             path: '/wishlist',
//             name: 'wishlist',
//             pageBuilder: _ph('Wishlist'),
//           ),

//           /* NOTIFICATIONS */
//           GoRoute(
//             path: '/notifications',
//             name: 'notifications',
//             pageBuilder: _ph('Notifications'),
//           ),

//           /* TRANSACTIONS */
//           GoRoute(
//             path: '/transactions',
//             name: 'transactions',
//             pageBuilder: _ph('Transactions'),
//           ),

//           /* COUPONS / OFFERS */
//           GoRoute(
//             path: '/coupons',
//             name: 'coupons',
//             pageBuilder: _ph('Coupons / Offers'),
//           ),

//           /* SUPPORT */
//           GoRoute(
//             path: '/support',
//             name: 'support',
//             pageBuilder: _ph('Contact Support'),
//           ),

//           /* SETTINGS */
//           GoRoute(
//             path: '/settings',
//             name: 'settings',
//             pageBuilder: _ph('Settings'),
//           ),

//           /* AUTH (no chrome) */
//           GoRoute(
//             path: '/auth',
//             name: 'auth',
//             pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
//           ),

//           /* SELLER DASHBOARD */
//           GoRoute(
//             path: '/seller',
//             name: 'seller',
//             pageBuilder: (_, __) => _chrome(const SellerPage()),
//           ),

//           /* ADD PRODUCT */
//           GoRoute(
//             path: '/seller/add-product',
//             name: 'add-product',
//             pageBuilder: (_, __) => _chrome(const AddProductPage()),
//           ),

//           /* ORDER DETAILS */
//           GoRoute(
//             path: '/order-details/:id',
//             name: 'order-details',
//             pageBuilder: (ctx, st) =>
//                 _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
//           ),

//           /* APPLY EMI */
//           GoRoute(
//             path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
//             name: 'apply-emi',
//             pageBuilder: (ctx, st) => _chrome(
//               ApplyEMIPage(
//                 productId: st.pathParameters['productId']!,
//                 productName: Uri.decodeComponent(st.pathParameters['productName']!),
//                 productPrice:
//                     double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
//                 sellerId: st.pathParameters['sellerId']!,
//               ),
//             ),
//           ),
//         ],
//       );

//   /* ───────── chrome helpers ───────── */

//   /// Wrap every “normal” page with AppBar, Drawer & Bottom nav, except for HomePage.
//   Page<dynamic> _chrome(Widget child) => MaterialPage(
//         child: _ScaffoldWithDrawer(
//           child: child,
//         ),
//       );

//   /// Quick helper for placeholder pages.
//   Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
//       (_, __) => _chrome(PlaceholderPage(title));
// }

// class _ScaffoldWithDrawer extends StatelessWidget {
//   final Widget child;

//   const _ScaffoldWithDrawer({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const Header(),
//       drawer: const Header().buildDrawer(context),
//       body: child,
//       bottomNavigationBar: const FooterNav(),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'state/app_state.dart';

// /* ───────── shared chrome ───────── */
// import 'widgets/header.dart';
// import 'widgets/footer.dart';

// /* ───────── concrete pages ───────── */
// import 'pages/home_page.dart';
// import 'pages/products_page.dart';
// import 'pages/product_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/categories_page.dart';
// import 'pages/checkout_page.dart';
// import 'pages/account_page.dart';
// import 'pages/auth_page.dart';
// import 'pages/seller_page.dart';
// import 'pages/add_product_page.dart';
// import 'pages/order_details_page.dart';
// import 'pages/apply_emi_page.dart';
// import 'pages/placeholder_page.dart';
// import 'pages/orders_page.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   /* .env */
//   try {
//     await dotenv.load(fileName: ".env");
//   } catch (e) {
//     debugPrint('Failed to load .env file: $e');
//   }

//   /* Supabase */
//   try {
//     await Supabase.initialize(
//       url: dotenv.env['SUPABASE_URL'] ?? '',
//       anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
//       debug: true,
//     );
//   } catch (e) {
//     debugPrint('Failed to initialize Supabase: $e');
//   }

//   runApp(const MarkeetApp());
// }

// class MarkeetApp extends StatelessWidget {
//   const MarkeetApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppState(),
//       child: Consumer<AppState>(
//         builder: (context, app, _) => MaterialApp.router(
//           title: 'Markeet',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             useMaterial3: true,
//             primaryColor: const Color(0xFF1A237E), // Deep Indigo
//             scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey
//             cardColor: Colors.white,
//             textTheme: const TextTheme(
//               titleLarge: TextStyle(
//                 color: Color(0xFF212121), // Dark Grey
//                 fontWeight: FontWeight.bold,
//               ),
//               bodyMedium: TextStyle(color: Color(0xFF757575)), // Medium Grey
//             ),
//             elevatedButtonTheme: ElevatedButtonThemeData(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1A237E), // Deep Indigo
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             outlinedButtonTheme: OutlinedButtonThemeData(
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Color(0xFF1A237E)),
//                 foregroundColor: const Color(0xFF1A237E),
//               ),
//             ),
//           ),
//           routerConfig: _router(app),
//         ),
//       ),
//     );
//   }

//   /* ─────────────── Router ─────────────── */

//   GoRouter _router(AppState app) => GoRouter(
//         refreshListenable: app,
//         initialLocation: '/',
//         redirect: (context, state) async {
//           final loggedIn = app.session != null;
//           final onAuthPage = state.matchedLocation == '/auth';
//           debugPrint(
//               'Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
//           if (!loggedIn && !onAuthPage && state.matchedLocation != '/auth') {
//             debugPrint('Redirecting to /auth');
//             return '/auth';
//           }
//           if (loggedIn && onAuthPage) {
//             debugPrint('Redirecting to /');
//             return '/';
//           }
//           return null;
//         },
//         routes: [
//           /* HOME */
//           GoRoute(
//             path: '/',
//             name: 'home',
//             pageBuilder: (_, __) => const MaterialPage(child: HomePage()),
//           ),

//           /* PRODUCTS (Category-specific product listing) */
//           GoRoute(
//             path: '/products',
//             name: 'products',
//             pageBuilder: (ctx, st) {
//               final categoryId = st.uri.queryParameters['category'];
//               return _chrome(ProductsPage(categoryId: categoryId));
//             },
//           ),

//           /* PRODUCT DETAILS */
//           GoRoute(
//             path: '/products/:id',
//             name: 'product',
//             pageBuilder: (ctx, st) =>
//                 _chrome(ProductPage(id: st.pathParameters['id']!)),
//           ),

//           /* CART */
//           GoRoute(
//             path: '/cart',
//             name: 'cart',
//             pageBuilder: (_, __) => _chrome(const CartPage()),
//           ),

//           /* CATEGORIES */
//           GoRoute(
//             path: '/categories',
//             name: 'categories',
//             pageBuilder: (_, __) => _chrome(const CategoriesPage()),
//           ),

//           /* CHECKOUT */
//           GoRoute(
//             path: '/checkout',
//             name: 'checkout',
//             pageBuilder: (_, __) => _chrome(const CheckoutPage()),
//           ),

//           /* ACCOUNT */
//           GoRoute(
//             path: '/account',
//             name: 'account',
//             pageBuilder: (_, __) => _chrome(const AccountPage()),
//           ),

//           /* ORDERS */
//           GoRoute(
//             path: '/orders',
//             name: 'orders',
//             pageBuilder: (_, __) => _chrome(const OrdersPage()),
//           ),

//           /* CANCEL ORDER */
//           GoRoute(
//             path: '/orders/cancel/:id',
//             name: 'cancel-order',
//             pageBuilder: (ctx, st) => _chrome(const OrdersPage()),
//           ),

//           /* WISHLIST */
//           GoRoute(
//             path: '/wishlist',
//             name: 'wishlist',
//             pageBuilder: _ph('Wishlist'),
//           ),

//           /* NOTIFICATIONS */
//           GoRoute(
//             path: '/notifications',
//             name: 'notifications',
//             pageBuilder: _ph('Notifications'),
//           ),

//           /* TRANSACTIONS */
//           GoRoute(
//             path: '/transactions',
//             name: 'transactions',
//             pageBuilder: _ph('Transactions'),
//           ),

//           /* COUPONS / OFFERS */
//           GoRoute(
//             path: '/coupons',
//             name: 'coupons',
//             pageBuilder: _ph('Coupons / Offers'),
//           ),

//           /* SUPPORT */
//           GoRoute(
//             path: '/support',
//             name: 'support',
//             pageBuilder: _ph('Contact Support'),
//           ),

//           /* SETTINGS */
//           GoRoute(
//             path: '/settings',
//             name: 'settings',
//             pageBuilder: _ph('Settings'),
//           ),

//           /* AUTH (no chrome) */
//           GoRoute(
//             path: '/auth',
//             name: 'auth',
//             pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
//           ),

//           /* SELLER DASHBOARD */
//           GoRoute(
//             path: '/seller',
//             name: 'seller',
//             pageBuilder: (_, __) => _chrome(const SellerPage()),
//           ),

//           /* ADD PRODUCT */
//           GoRoute(
//             path: '/seller/add-product',
//             name: 'add-product',
//             pageBuilder: (_, __) => _chrome(const AddProductPage()),
//           ),

//           /* ORDER DETAILS */
//           GoRoute(
//             path: '/order-details/:id',
//             name: 'order-details',
//             pageBuilder: (ctx, st) =>
//                 _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
//           ),

//           /* APPLY EMI */
//           GoRoute(
//             path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
//             name: 'apply-emi',
//             pageBuilder: (ctx, st) => _chrome(
//               ApplyEMIPage(
//                 productId: st.pathParameters['productId']!,
//                 productName: Uri.decodeComponent(st.pathParameters['productName']!),
//                 productPrice:
//                     double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
//                 sellerId: st.pathParameters['sellerId']!,
//               ),
//             ),
//           ),

//           /* POLICY */
//           GoRoute(
//             path: '/policy',
//             name: 'policy',
//             pageBuilder: (_, __) => _chrome(const PlaceholderPage('Policy')),
//           ),

//           /* PRIVACY */
//           GoRoute(
//             path: '/privacy',
//             name: 'privacy',
//             pageBuilder: (_, __) => _chrome(const PlaceholderPage('Privacy')),
//           ),
//         ],
//       );

//   /* ───────── chrome helpers ───────── */

//   /// Wrap every “normal” page with AppBar, Drawer & Bottom nav, except for HomePage.
//   Page<dynamic> _chrome(Widget child) => MaterialPage(
//         child: _ScaffoldWithDrawer(
//           child: child,
//         ),
//       );

//   /// Quick helper for placeholder pages.
//   Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
//       (_, __) => _chrome(PlaceholderPage(title));
// }

// class _ScaffoldWithDrawer extends StatelessWidget {
//   final Widget child;

//   const _ScaffoldWithDrawer({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const Header(),
//       drawer: const Header().buildDrawer(context),
//       body: child,
//       bottomNavigationBar: const FooterNav(),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'state/app_state.dart';

/* ───────── shared chrome ───────── */
import 'widgets/header.dart';
import 'widgets/footer.dart';

/* ───────── concrete pages ───────── */
import 'pages/home_page.dart';
import 'pages/products_page.dart';
import 'pages/product_page.dart';
import 'pages/cart_page.dart';
import 'pages/categories_page.dart';
import 'pages/checkout_page.dart';
import 'pages/account_page.dart';
import 'pages/auth_page.dart';
import 'pages/seller_page.dart';
import 'pages/add_product_page.dart';
import 'pages/order_details_page.dart';
import 'pages/apply_emi_page.dart';
import 'pages/placeholder_page.dart';
import 'pages/orders_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* .env */
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
    // Optionally, show a UI error in production
  }

  /* Supabase */
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY missing in .env');
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
    // Optionally, show a UI error in production
  }

  runApp(const MarkeetApp());
}

class MarkeetApp extends StatelessWidget {
  const MarkeetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp.router(
          title: 'Markeet',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF1A237E), // Deep Indigo
            scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light Grey
            cardColor: Colors.white,
            textTheme: const TextTheme(
              titleLarge: TextStyle(
                color: Color(0xFF212121), // Dark Grey
                fontWeight: FontWeight.bold,
              ),
              bodyMedium: TextStyle(color: Color(0xFF757575)), // Medium Grey
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), // Deep Indigo
                foregroundColor: Colors.white,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A237E)),
                foregroundColor: const Color(0xFF1A237E),
              ),
            ),
          ),
          routerConfig: _router(app),
        ),
      ),
    );
  }

  /* ─────────────── Router ─────────────── */

  GoRouter _router(AppState app) => GoRouter(
        refreshListenable: app,
        initialLocation: '/',
        redirect: (context, state) async {
          final loggedIn = app.session != null;
          final onAuthPage = state.matchedLocation == '/auth';
          debugPrint(
              'Redirect check: loggedIn=$loggedIn, onAuthPage=$onAuthPage, location=${state.matchedLocation}');
          if (!loggedIn && !onAuthPage && state.matchedLocation != '/auth') {
            debugPrint('Redirecting to /auth');
            return '/auth';
          }
          if (loggedIn && onAuthPage) {
            debugPrint('Redirecting to /');
            return '/';
          }
          return null;
        },
        routes: [
          /* HOME */
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (_, __) => const MaterialPage(child: HomePage()),
          ),

          /* PRODUCTS (Category-specific product listing) */
          GoRoute(
            path: '/products',
            name: 'products',
            pageBuilder: (ctx, st) {
              final categoryId = st.uri.queryParameters['category'];
              return _chrome(ProductsPage(categoryId: categoryId));
            },
          ),

          /* PRODUCT DETAILS */
          GoRoute(
            path: '/products/:id',
            name: 'product',
            pageBuilder: (ctx, st) =>
                _chrome(ProductPage(id: st.pathParameters['id']!)),
          ),

          /* CART */
          GoRoute(
            path: '/cart',
            name: 'cart',
            pageBuilder: (_, __) => _chrome(const CartPage()),
          ),

          /* CATEGORIES */
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (_, __) => _chrome(const CategoriesPage()),
          ),

          /* CHECKOUT */
          GoRoute(
            path: '/checkout',
            name: 'checkout',
            pageBuilder: (_, __) => _chrome(const CheckoutPage()),
          ),

          /* ACCOUNT */
          GoRoute(
            path: '/account',
            name: 'account',
            pageBuilder: (_, __) => _chrome(const AccountPage()),
          ),

          /* ORDERS */
          GoRoute(
            path: '/orders',
            name: 'orders',
            pageBuilder: (_, __) => _chrome(const OrdersPage()),
          ),

          /* CANCEL ORDER */
          GoRoute(
            path: '/orders/cancel/:id',
            name: 'cancel-order',
            pageBuilder: (ctx, st) => _chrome(const OrdersPage()),
          ),

          /* WISHLIST */
          GoRoute(
            path: '/wishlist',
            name: 'wishlist',
            pageBuilder: _ph('Wishlist'),
          ),

          /* NOTIFICATIONS */
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: _ph('Notifications'),
          ),

          /* TRANSACTIONS */
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: _ph('Transactions'),
          ),

          /* COUPONS / OFFERS */
          GoRoute(
            path: '/coupons',
            name: 'coupons',
            pageBuilder: _ph('Coupons / Offers'),
          ),

          /* SUPPORT */
          GoRoute(
            path: '/support',
            name: 'support',
            pageBuilder: _ph('Contact Support'),
          ),

          /* SETTINGS */
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: _ph('Settings'),
          ),

          /* AUTH (no chrome) */
          GoRoute(
            path: '/auth',
            name: 'auth',
            pageBuilder: (_, __) => const MaterialPage(child: AuthPage()),
          ),

          /* SELLER DASHBOARD */
          GoRoute(
            path: '/seller',
            name: 'seller',
            pageBuilder: (_, __) => _chrome(const SellerPage()),
          ),

          /* ADD PRODUCT */
          GoRoute(
            path: '/seller/add-product',
            name: 'add-product',
            pageBuilder: (_, __) => _chrome(const AddProductPage()),
          ),

          /* ORDER DETAILS */
          GoRoute(
            path: '/order-details/:id',
            name: 'order-details',
            pageBuilder: (ctx, st) =>
                _chrome(OrderDetailsPage(id: st.pathParameters['id']!)),
          ),

          /* APPLY EMI */
          GoRoute(
            path: '/apply-emi/:productId/:productName/:productPrice/:sellerId',
            name: 'apply-emi',
            pageBuilder: (ctx, st) => _chrome(
              ApplyEMIPage(
                productId: st.pathParameters['productId']!,
                productName: Uri.decodeComponent(st.pathParameters['productName']!),
                productPrice:
                    double.tryParse(st.pathParameters['productPrice']!) ?? 0.0,
                sellerId: st.pathParameters['sellerId']!,
              ),
            ),
          ),

          /* POLICY */
          GoRoute(
            path: '/policy',
            name: 'policy',
            pageBuilder: (_, __) => _chrome(const PlaceholderPage('Policy')),
          ),

          /* PRIVACY */
          GoRoute(
            path: '/privacy',
            name: 'privacy',
            pageBuilder: (_, __) => _chrome(const PlaceholderPage('Privacy')),
          ),
        ],
      );

  /* ───────── chrome helpers ───────── */

  /// Wrap every “normal” page with AppBar, Drawer & Bottom nav, except for HomePage.
  Page<dynamic> _chrome(Widget child) => MaterialPage(
        child: _ScaffoldWithDrawer(
          child: child,
        ),
      );

  /// Quick helper for placeholder pages.
  Page<dynamic> Function(BuildContext, GoRouterState) _ph(String title) =>
      (_, __) => _chrome(PlaceholderPage(title));
}

class _ScaffoldWithDrawer extends StatelessWidget {
  final Widget child;

  const _ScaffoldWithDrawer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      drawer: const Drawer(), // Replaced Header().buildDrawer(context) due to unknown method
      body: child,
      bottomNavigationBar: const Footer(), // Fixed: Replaced FooterNav with Footer
    );
  }
}