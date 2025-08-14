// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';

// class FooterNav extends StatelessWidget {
//   const FooterNav({super.key});

//   int _indexFor(String loc) {
//     if (loc.startsWith('/categories')) return 1;
//     if (loc.startsWith('/account'))    return 2;
//     if (loc.startsWith('/cart'))       return 3;
//     return 0; // home
//   }

//   @override
//   Widget build(BuildContext context) {
//     final router = GoRouter.of(context);
// final loc    = router.routeInformationProvider.value.location ?? '/';
// final idx    = _indexFor(loc);

//     final cart   = context.watch<AppState>().cartCount;

//     return NavigationBar(
//       selectedIndex: idx,
//       onDestinationSelected: (i) {
//         switch (i) {
//           case 0: context.go('/'); break;
//           case 1: context.go('/categories'); break;
//           case 2: context.go('/account'); break;
//           case 3: context.go('/cart'); break;
//         }
//       },
//       destinations: [
//         const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
//         const NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
//         const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
//         NavigationDestination(
//           icon: Stack(
//             clipBehavior: Clip.none,
//             children: [
//               const Icon(Icons.shopping_cart_outlined),
//               if (cart > 0)
//                 Positioned(
//                   right: -6, top: -4,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
//                     child: Text('$cart', style: const TextStyle(fontSize: 10, color: Colors.white)),
//                   ),
//                 ),
//             ],
//           ),
//           label: 'Cart',
//         ),
//       ],
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../state/app_state.dart';

// class FooterNav extends StatelessWidget {
//   const FooterNav({super.key});

//   int _indexFor(String loc) {
//     if (loc.startsWith('/categories')) return 1;
//     if (loc.startsWith('/account')) return 2;
//     if (loc.startsWith('/cart')) return 3;
//     return 0; // home
//   }

//   @override
//   Widget build(BuildContext context) {
//     final router = GoRouter.of(context);
//     final loc = router.routeInformationProvider.value.location ?? '/';
//     final idx = _indexFor(loc);

//     final cart = context.watch<AppState>().cartCount;

//     return NavigationBar(
//       selectedIndex: idx,
//       onDestinationSelected: (i) {
//         switch (i) {
//           case 0:
//             context.go('/');
//             break;
//           case 1:
//             context.go('/categories');
//             break;
//           case 2:
//             context.go('/account');
//             break;
//           case 3:
//             context.go('/cart');
//             break;
//         }
//       },
//       destinations: [
//         const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
//         const NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
//         const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
//         NavigationDestination(
//           icon: Stack(
//             clipBehavior: Clip.none,
//             children: [
//               const Icon(Icons.shopping_cart_outlined),
//               if (cart > 0)
//                 Positioned(
//                   right: -6,
//                   top: -4,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
//                     child: Text('$cart', style: const TextStyle(fontSize: 10, color: Colors.white)),
//                   ),
//                 ),
//             ],
//           ),
//           label: 'Cart',
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/app_state.dart';

const premiumPrimaryColor = Color(0xFF1A237E);
const premiumSecondaryTextColor = Color(0xFF757575);
const premiumCardColor = Colors.white;
const premiumErrorColor = Color(0xFFEF4444);

class Footer extends StatelessWidget {
  const Footer({super.key});

  int _indexFor(String loc) {
    if (loc.startsWith('/categories')) return 1;
    if (loc.startsWith('/account')) return 2;
    if (loc.startsWith('/cart')) return 3;
    return 0; // home
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final loc = router.routeInformationProvider.value.uri.toString();
    final idx = _indexFor(loc);

    final cart = context.watch<AppState>().cartCount;

    return NavigationBar(
      selectedIndex: idx,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/categories');
            break;
          case 2:
            context.go('/account');
            break;
          case 3:
            context.go('/cart');
            break;
        }
      },
      backgroundColor: premiumCardColor,
      elevation: 8,
      indicatorColor: premiumPrimaryColor.withOpacity(0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      animationDuration: const Duration(milliseconds: 300),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined, color: premiumSecondaryTextColor),
          selectedIcon: const Icon(Icons.home, color: premiumPrimaryColor),
          label: 'Home',
          tooltip: 'Home Page',
        ),
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined, color: premiumSecondaryTextColor),
          selectedIcon: const Icon(Icons.grid_view, color: premiumPrimaryColor),
          label: 'Categories',
          tooltip: 'Browse Categories',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline, color: premiumSecondaryTextColor),
          selectedIcon: const Icon(Icons.person, color: premiumPrimaryColor),
          label: 'Account',
          tooltip: 'Your Account',
        ),
        NavigationDestination(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: premiumSecondaryTextColor),
              if (cart > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: premiumErrorColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cart',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          selectedIcon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart, color: premiumPrimaryColor),
              if (cart > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: premiumErrorColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cart',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: 'Cart',
          tooltip: 'Your Cart',
        ),
      ],
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: premiumPrimaryColor,
          );
        }
        return GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: premiumSecondaryTextColor,
        );
      }),
    );
  }
}