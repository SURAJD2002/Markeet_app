// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';

// class Header extends StatelessWidget implements PreferredSizeWidget {
//   const Header({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     return AppBar(
//       titleSpacing: 0,
//       elevation: 4,
//       shadowColor: Colors.grey.withOpacity(0.3),
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.black,
//       automaticallyImplyLeading: false,
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blueAccent, Colors.cyanAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//       title: InkWell(
//         onTap: () => context.go('/'),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Image.asset(
//             'assets/markeet.png',
//             height: 55, // Adjust height to fit the AppBar
//             fit: BoxFit.contain,
//           ),
//         ),
//       ),
//       actions: [
//         IconButton(
//           tooltip: 'Categories',
//           icon: const Icon(Icons.category_outlined, color: Colors.white),
//           onPressed: () => context.push('/categories'),
//           padding: const EdgeInsets.all(12),
//           splashRadius: 24,
//         ),
//         if (app.session == null) ...[
//           OutlinedButton(
//             onPressed: () => context.push('/auth'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.white,
//               side: const BorderSide(color: Colors.white),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             child: const Text(
//               'Sign Up',
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//             ),
//           ),
//           const SizedBox(width: 8),
//           OutlinedButton(
//             onPressed: () => context.push('/auth'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.white,
//               side: const BorderSide(color: Colors.white),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             child: const Text(
//               'Login',
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ] else ...[
//           Stack(
//             alignment: Alignment.center,
//             children: [
//               IconButton(
//                 tooltip: 'Cart',
//                 icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
//                 onPressed: () => context.push('/cart'),
//                 padding: const EdgeInsets.all(12),
//                 splashRadius: 24,
//               ),
//               if (app.cartCount > 0)
//                 Positioned(
//                   right: 6,
//                   top: 6,
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(10),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.red.withOpacity(0.4),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Text(
//                       '${app.cartCount}',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           IconButton(
//             tooltip: 'Account',
//             icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
//             onPressed: () => context.push('/account'),
//             padding: const EdgeInsets.all(12),
//             splashRadius: 24,
//           ),
//         ],
//         const SizedBox(width: 8),
//       ],
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';

// class Header extends StatelessWidget implements PreferredSizeWidget {
//   const Header({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();

//     return AppBar(
//       titleSpacing: 0,
//       elevation: 6,
//       shadowColor: Colors.black.withOpacity(0.2),
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.black,
//       automaticallyImplyLeading: false,
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blueAccent, Colors.cyanAccent],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//       leading: Builder(
//         builder: (context) => IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white, size: 28),
//           onPressed: () => Scaffold.of(context).openDrawer(),
//           tooltip: 'Menu',
//           padding: const EdgeInsets.all(12),
//           splashRadius: 24,
//         ),
//       ),
//       title: InkWell(
//         onTap: () => context.go('/'),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Image.asset(
//             'assets/markeet.png',
//             height: 40, // Slightly reduced height for better balance
//             fit: BoxFit.contain,
//           ),
//         ),
//       ),
//       actions: [
//         if (app.session == null) ...[
//           OutlinedButton(
//             onPressed: () => context.push('/auth'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.white,
//               side: const BorderSide(color: Colors.white, width: 1.5),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               elevation: 2,
//               shadowColor: Colors.black.withOpacity(0.2),
//             ),
//             child: const Text(
//               'Sign Up',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           OutlinedButton(
//             onPressed: () => context.push('/auth'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.white,
//               side: const BorderSide(color: Colors.white, width: 1.5),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               elevation: 2,
//               shadowColor: Colors.black.withOpacity(0.2),
//             ),
//             child: const Text(
//               'Login',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//         if (app.session != null) ...[
//           Stack(
//             alignment: Alignment.center,
//             children: [
//               IconButton(
//                 tooltip: 'Cart',
//                 icon: const Icon(
//                   Icons.shopping_cart_outlined,
//                   color: Colors.white,
//                   size: 28,
//                 ),
//                 onPressed: () => context.push('/cart'),
//                 padding: const EdgeInsets.all(12),
//                 splashRadius: 24,
//                 splashColor: Colors.white.withOpacity(0.2),
//               ),
//               if (app.cartCount > 0)
//                 Positioned(
//                   right: 6,
//                   top: 6,
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.redAccent,
//                       borderRadius: BorderRadius.circular(10),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.redAccent.withOpacity(0.4),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Text(
//                       '${app.cartCount}',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//         const SizedBox(width: 12), // Slightly increased spacing for better padding
//       ],
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import '../state/app_state.dart';

// class Header extends StatelessWidget implements PreferredSizeWidget {
//   const Header({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   Drawer buildDrawer(BuildContext context) { // Made public by removing underscore
//     final app = Provider.of<AppState>(context, listen: false);
//     final profile = app.profile;

//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: const BoxDecoration(
//               color: Color(0xFF1A237E), // Deep Indigo
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Markeet',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   profile?['email'] ?? 'Guest',
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.home),
//             title: const Text('Home'),
//             onTap: () {
//               context.go('/');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.person),
//             title: const Text('Account'),
//             onTap: () {
//               context.go('/account');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.shopping_cart),
//             title: const Text('Cart'),
//             onTap: () {
//               context.go('/cart');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.category),
//             title: const Text('Categories'),
//             onTap: () {
//               context.go('/categories');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.receipt),
//             title: const Text('My Orders'),
//             onTap: () {
//               context.go('/orders');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.favorite),
//             title: const Text('Wishlist'),
//             onTap: () {
//               context.go('/wishlist');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.notifications),
//             title: const Text('Notifications'),
//             onTap: () {
//               context.go('/notifications');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.payment),
//             title: const Text('Transactions'),
//             onTap: () {
//               context.go('/transactions');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.local_offer),
//             title: const Text('Coupons / Offers'),
//             onTap: () {
//               context.go('/coupons');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.support),
//             title: const Text('Contact Support'),
//             onTap: () {
//               context.go('/support');
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text('Settings'),
//             onTap: () {
//               context.go('/settings');
//               Navigator.pop(context);
//             },
//           ),
//           if (profile?['is_seller'] == true)
//             ListTile(
//               leading: const Icon(Icons.store),
//               title: const Text('Seller Dashboard'),
//               onTap: () {
//                 context.go('/seller');
//                 Navigator.pop(context);
//               },
//             ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final app = context.watch<AppState>();
//     final isLoggedIn = app.session != null;

//     return AppBar(
//       title: const Text('Markeet'),
//       elevation: 4,
//       shadowColor: Colors.grey.withOpacity(0.3),
//       backgroundColor: Colors.white,
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.search),
//           onPressed: () {
//             // Implement search functionality
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.receipt),
//           tooltip: 'My Orders',
//           onPressed: () {
//             if (isLoggedIn) {
//               context.go('/orders');
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Please log in to view your orders'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//               context.go('/auth');
//             }
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.notifications),
//           onPressed: () {
//             context.go('/notifications');
//           },
//         ),
//       ],
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../state/app_state.dart';

// Reuse premium color palette from home_page.dart
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumAccentColor = Color(0xFFFFD740); // Gold
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumCardColor = Colors.white;
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey
const premiumShadowColor = Color(0x1A000000);
const premiumErrorColor = Color(0xFFEF4444);
const premiumSuccessColor = Color(0xFF2ECC71);

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildSearchBar(BuildContext context, TextEditingController controller, FocusNode focusNode, Function(String) onSearch) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: premiumCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus ? Colors.transparent : premiumSecondaryTextColor.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: focusNode.hasFocus
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
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: premiumSecondaryTextColor, size: 24),
          hintText: 'Search electronics, fashion, jewellery...',
          hintStyle: GoogleFonts.roboto(
            color: premiumSecondaryTextColor.withOpacity(0.7),
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
        onSubmitted: (value) {
          onSearch(value);
        },
      ),
    );
  }

  Drawer buildDrawer(BuildContext context) {
    final app = context.watch<AppState>();
    final isLoggedIn = app.session != null;
    final profile = app.profile;

    // Animation controllers for drawer items
    final List<AnimationController> animationControllers = [];

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
                  colors: [premiumPrimaryColor, premiumPrimaryColor.withOpacity(0.8)],
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
                    isLoggedIn ? 'Hello, ${profile?['full_name'] ?? 'User'}!' : 'Welcome, Guest!',
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
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              title: 'Account',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/account' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.shopping_cart,
              title: 'Cart',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/cart' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.category,
              title: 'Categories',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/categories');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.receipt,
              title: 'My Orders',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/orders' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.favorite,
              title: 'Wishlist',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/wishlist' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/notifications' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.payment,
              title: 'Transactions',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/transactions' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.local_offer,
              title: 'Coupons / Offers',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go(isLoggedIn ? '/coupons' : '/auth');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.support_agent,
              title: 'Contact Support',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/support');
                }
              },
              controllers: animationControllers,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/settings');
                }
              },
              controllers: animationControllers,
            ),
            if (profile?['is_seller'] == true)
              _buildDrawerItem(
                context: context,
                icon: Icons.store,
                title: 'Seller Dashboard',
                onTap: () {
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.go(isLoggedIn ? '/seller' : '/auth');
                  }
                },
                controllers: animationControllers,
              ),
            if (isLoggedIn)
              _buildDrawerItem(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                color: premiumErrorColor,
                onTap: () {
                  if (context.mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to logout?', style: GoogleFonts.roboto()),
                        actions: [
                          TextButton(
                            onPressed: () {
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Text('Cancel', style: GoogleFonts.roboto(color: premiumSecondaryTextColor)),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (context.mounted) {
                                Navigator.pop(context);
                                final error = await context.read<AppState>().signOut();
                                if (error != null) {
                                  if (context.mounted) {
                                    Fluttertoast.showToast(
                                      msg: error,
                                      backgroundColor: premiumErrorColor,
                                      textColor: Colors.white,
                                      fontSize: 15,
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.TOP,
                                    );
                                  }
                                } else if (context.mounted) {
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
                controllers: animationControllers,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    required List<AnimationController> controllers,
  }) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: context as TickerProvider,
    );
    controllers.add(controller);
    return AnimationConfiguration.staggeredList(
      position: controllers.length - 1,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: InkWell(
            onTap: () {
              controller.forward().then((_) => controller.reverse());
              onTap();
            },
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isLoggedIn = app.session != null;

    return AppBar(
      title: Text(
        'Markeet',
        style: GoogleFonts.roboto(
          color: premiumTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 4,
      shadowColor: premiumShadowColor,
      backgroundColor: premiumCardColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: premiumPrimaryColor),
          tooltip: 'Search',
          onPressed: () {
            final controller = TextEditingController();
            final focusNode = FocusNode();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: premiumCardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: _buildSearchBar(
                  context,
                  controller,
                  focusNode,
                  (value) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.go('/products?search=$value');
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(color: premiumSecondaryTextColor),
                    ),
                  ),
                ],
              ),
            ).then((_) {
              controller.dispose();
              focusNode.dispose();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.receipt, color: premiumPrimaryColor),
          tooltip: 'My Orders',
          onPressed: () {
            if (isLoggedIn) {
              if (context.mounted) {
                context.go('/orders');
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please log in to view your orders',
                      style: GoogleFonts.roboto(color: Colors.white),
                    ),
                    backgroundColor: premiumErrorColor,
                  ),
                );
                context.go('/auth');
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: premiumPrimaryColor),
          tooltip: 'Notifications',
          onPressed: () {
            if (context.mounted) {
              context.go('/notifications');
            }
          },
        ),
      ],
    );
  }
}
