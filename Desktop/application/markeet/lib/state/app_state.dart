// // lib/state/app_state.dart
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AppState extends ChangeNotifier {
//   AppState() {
//     _init();
//   }

//   // ────────────────────────────── auth ──────────────────────────────
//   Session? session;
//   bool isSeller = false;

//   // ────────────────────────────── cart ──────────────────────────────
//   int cartCount = 0;

//   // ──────────────────────────── location ────────────────────────────
//   Map<String, double>? buyerLocation;     // {'lat': …, 'lon': …}
//   bool locationReady = false;

//   void _setBuyerLoc(Map<String, double> loc) {
//     buyerLocation = loc;
//     locationReady = true;
//     notifyListeners();
//   }

//   // ────────────────────────── Supabase client ───────────────────────
//   final _spb = Supabase.instance.client;

//   Future<void> _init() async {
//     session = _spb.auth.currentSession;

//     _spb.auth.onAuthStateChange.listen((evt) async {
//       session = evt.session;
//       await _refreshUserData();
//       notifyListeners();
//     });

//     await _refreshUserData();
//   }

//   // ───────────────────────── public helpers ─────────────────────────
//   Future<void> signOut() async => _spb.auth.signOut();

//   Future<void> refreshCartCount() async {
//     if (session == null) return;
//     final rows = await _spb
//         .from('cart')
//         .select('id')
//         .eq('user_id', session!.user.id);

//     cartCount = rows.length;
//     notifyListeners();
//   }

//   /// Ensure we have buyerLocation; asks permission once.
//   Future<void> ensureBuyerLocation() async {
//     if (buyerLocation != null) return;

//     try {
//       var perm = await Geolocator.checkPermission();
//       if (perm == LocationPermission.denied) {
//         perm = await Geolocator.requestPermission();
//       }
//       if (perm == LocationPermission.denied ||
//           perm == LocationPermission.deniedForever) {
//         // fallback to Bengaluru
//         _setBuyerLoc({'lat': 12.9753, 'lon': 77.591});
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//       _setBuyerLoc({'lat': pos.latitude, 'lon': pos.longitude});
//     } catch (_) {
//       // any failure -> fallback
//       _setBuyerLoc({'lat': 12.9753, 'lon': 77.591});
//     }
//   }

//   // ───────────────────────── internal ───────────────────────────────
//   Future<void> _refreshUserData() async {
//     if (session == null) {
//       isSeller = false;
//       cartCount = 0;
//       return;
//     }

//     final prof = await _spb
//         .from('profiles')
//         .select('is_seller')
//         .eq('id', session!.user.id);

//     isSeller = prof.isNotEmpty && prof.first['is_seller'] == true;

//     await refreshCartCount();
//   }
// }




// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AppState extends ChangeNotifier {
//   Session? _session;
//   Map<String, double>? _buyerLocation;
//   Map<String, double>? _sellerLocation;
//   bool _locationReady = false;
//   int _cartCount = 0;

//   Session? get session => _session;
//   Map<String, double>? get buyerLocation => _buyerLocation;
//   Map<String, double>? get sellerLocation => _sellerLocation;
//   bool get locationReady => _locationReady;
//   int get cartCount => _cartCount;

//   final _spb = Supabase.instance.client;

//   AppState() {
//     // Listen to auth state changes
//     _spb.auth.onAuthStateChange.listen((data) {
//       _session = data.session;
//       if (_session == null) {
//         _cartCount = 0;
//         _buyerLocation = null;
//         _sellerLocation = null;
//         _locationReady = false;
//       } else {
//         refreshCartCount();
//       }
//       notifyListeners();
//     });

//     // Initialize cart count from shared preferences
//     _loadCartCount();
//   }

//   Future<void> ensureBuyerLocation() async {
//     if (_locationReady) return;
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         _locationReady = false;
//         notifyListeners();
//         return;
//       }
//       final position = await Geolocator.getCurrentPosition();
//       _buyerLocation = {'lat': position.latitude, 'lon': position.longitude};
//       _locationReady = true;
//       notifyListeners();
//     } catch (e) {
//       _locationReady = false;
//       notifyListeners();
//     }
//   }

//   void setBuyerLocation(double lat, double lon) {
//     _buyerLocation = {'lat': lat, 'lon': lon};
//     _locationReady = true;
//     notifyListeners();
//   }

//   void setSellerLocation(double lat, double lon) {
//     _sellerLocation = {'lat': lat, 'lon': lon};
//     notifyListeners();
//   }

//   void clearLocations() {
//     _buyerLocation = null;
//     _sellerLocation = null;
//     _locationReady = false;
//     notifyListeners();
//   }

//   Future<void> refreshCartCount() async {
//     if (_session == null) {
//       _cartCount = 0;
//       notifyListeners();
//       return;
//     }
//     try {
//       final response = await _spb
//           .from('cart')
//           .select('id')
//           .eq('user_id', _session!.user.id);
//       _cartCount = response.length;
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setInt('cartCount_${_session!.user.id}', _cartCount);
//       notifyListeners();
//     } catch (e) {
//       // Fallback to shared preferences if Supabase fails
//       await _loadCartCount();
//       // Log the error for debugging (in a real app, use a proper logging solution)
//       debugPrint('Error refreshing cart count: $e');
//     }
//   }

//   Future<void> _loadCartCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (_session != null) {
//       _cartCount = prefs.getInt('cartCount_${_session!.user.id}') ?? 0;
//     } else {
//       _cartCount = 0;
//     }
//     notifyListeners();
//   }

//   Future<String?> signOut() async {
//     try {
//       await _spb.auth.signOut();
//       _cartCount = 0;
//       _buyerLocation = null;
//       _sellerLocation = null;
//       _locationReady = false;
//       final prefs = await SharedPreferences.getInstance();
//       if (_session != null) {
//         await prefs.remove('cartCount_${_session!.user.id}');
//       }
//       notifyListeners();
//       return null;
//     } catch (e) {
//       notifyListeners();
//       return 'Error signing out: $e';
//     }
//   }
// }


// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AppState extends ChangeNotifier {
//   Session? _session;
//   Map<String, double>? _buyerLocation;
//   Map<String, double>? _sellerLocation;
//   bool _locationReady = false;
//   int _cartCount = 0;

//   Session? get session => _session;
//   Map<String, double>? get buyerLocation => _buyerLocation;
//   Map<String, double>? get sellerLocation => _sellerLocation;
//   bool get locationReady => _locationReady;
//   int get cartCount => _cartCount;

//   final _spb = Supabase.instance.client;

//   AppState() {
//     // Listen to auth state changes
//     _spb.auth.onAuthStateChange.listen((data) {
//       updateSession(data.session);
//     });

//     // Initialize cart count from shared preferences
//     _loadCartCount();
//   }

//   Future<void> ensureBuyerLocation() async {
//     if (_locationReady) return;
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         _locationReady = false;
//         notifyListeners();
//         return;
//       }
//       final position = await Geolocator.getCurrentPosition();
//       _buyerLocation = {'lat': position.latitude, 'lon': position.longitude};
//       _locationReady = true;
//       notifyListeners();
//     } catch (e) {
//       _locationReady = false;
//       notifyListeners();
//     }
//   }

//   void setBuyerLocation(double lat, double lon) {
//     _buyerLocation = {'lat': lat, 'lon': lon};
//     _locationReady = true;
//     notifyListeners();
//   }

//   void setSellerLocation(double lat, double lon) {
//     _sellerLocation = {'lat': lat, 'lon': lon};
//     notifyListeners();
//   }

//   void clearLocations() {
//     _buyerLocation = null;
//     _sellerLocation = null;
//     _locationReady = false;
//     notifyListeners();
//   }

//   Future<void> refreshCartCount() async {
//     if (_session == null) {
//       _cartCount = 0;
//       notifyListeners();
//       return;
//     }
//     try {
//       final response = await _spb
//           .from('cart')
//           .select('id')
//           .eq('user_id', _session!.user.id);
//       _cartCount = response.length;
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setInt('cartCount_${_session!.user.id}', _cartCount);
//       notifyListeners();
//     } catch (e) {
//       // Fallback to shared preferences if Supabase fails
//       await _loadCartCount();
//       debugPrint('Error refreshing cart count: $e');
//     }
//   }

//   Future<void> _loadCartCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (_session != null) {
//       _cartCount = prefs.getInt('cartCount_${_session!.user.id}') ?? 0;
//     } else {
//       _cartCount = 0;
//     }
//     notifyListeners();
//   }

//   Future<String?> signOut() async {
//     try {
//       await _spb.auth.signOut();
//       updateSession(null);
//       return null;
//     } catch (e) {
//       notifyListeners();
//       return 'Error signing out: $e';
//     }
//   }

//   // Added updateSession method
//   void updateSession(Session? newSession) {
//     _session = newSession;
//     if (_session == null) {
//       _cartCount = 0;
//       _buyerLocation = null;
//       _sellerLocation = null;
//       _locationReady = false;
//       final prefs = SharedPreferences.getInstance();
//       prefs.then((p) {
//         if (_session != null) {
//           p.remove('cartCount_${_session!.user.id}');
//         }
//       });
//     } else {
//       refreshCartCount();
//     }
//     notifyListeners();
//   }
// }



// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// /// Manages the global state of the Markeet app, including user session,
// /// buyer/seller locations, cart count, and user profile data.
// class AppState extends ChangeNotifier {
//   /// Supabase client instance for interacting with the backend.
//   final _spb = Supabase.instance.client;

//   /// Current user session, null if the user is not logged in.
//   Session? _session;

//   /// User's profile data fetched from the 'profiles' table.
//   Map<String, dynamic>? _profile;

//   /// Buyer's location as a map with 'lat' and 'lon'.
//   Map<String, double>? _buyerLocation;

//   /// Seller's location as a map with 'lat' and 'lon'.
//   Map<String, double>? _sellerLocation;

//   /// Indicates whether the buyer's location is ready for use.
//   bool _locationReady = false;

//   /// Number of items in the user's cart.
//   int _cartCount = 0;

//   /// Getters for accessing private fields.
//   Session? get session => _session;
//   Map<String, dynamic>? get profile => _profile;
//   Map<String, double>? get buyerLocation => _buyerLocation;
//   Map<String, double>? get sellerLocation => _sellerLocation;
//   bool get locationReady => _locationReady;
//   int get cartCount => _cartCount;

//   AppState() {
//     // Listen to auth state changes and update the session accordingly.
//     _spb.auth.onAuthStateChange.listen((data) {
//       updateSession(data.session);
//     });

//     // Initialize cart count from shared preferences.
//     _loadCartCount();
//   }

//   /// Ensures the buyer's location is available, requesting it if not already set.
//   Future<void> ensureBuyerLocation() async {
//     if (_locationReady) return;
//     try {
//       // Request location permission.
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         debugPrint('Location permission denied.');
//         _locationReady = false;
//         notifyListeners();
//         return;
//       }

//       // Get the current position.
//       final position = await Geolocator.getCurrentPosition();
//       _buyerLocation = {'lat': position.latitude, 'lon': position.longitude};
//       _locationReady = true;
//       debugPrint('Buyer location set: $_buyerLocation');
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error getting buyer location: $e');
//       _locationReady = false;
//       notifyListeners();
//     }
//   }

//   /// Manually sets the buyer's location.
//   void setBuyerLocation(double lat, double lon) {
//     _buyerLocation = {'lat': lat, 'lon': lon};
//     _locationReady = true;
//     debugPrint('Buyer location manually set: $_buyerLocation');
//     notifyListeners();
//   }

//   /// Manually sets the seller's location.
//   void setSellerLocation(double lat, double lon) {
//     _sellerLocation = {'lat': lat, 'lon': lon};
//     debugPrint('Seller location set: $_sellerLocation');
//     notifyListeners();
//   }

//   /// Clears both buyer and seller locations.
//   void clearLocations() {
//     _buyerLocation = null;
//     _sellerLocation = null;
//     _locationReady = false;
//     debugPrint('Locations cleared.');
//     notifyListeners();
//   }

//   /// Refreshes the cart count by querying the 'cart' table in Supabase.
//   Future<void> refreshCartCount() async {
//     if (_session == null) {
//       _cartCount = 0;
//       notifyListeners();
//       debugPrint('Cart count reset to 0 (no session).');
//       return;
//     }

//     try {
//       final response = await _spb
//           .from('cart')
//           .select('id')
//           .eq('user_id', _session!.user.id);
//       if (response == null) {
//         debugPrint('Supabase returned null response for cart count.');
//         _cartCount = 0;
//       } else {
//         _cartCount = (response as List).length;
//       }

//       // Persist the cart count to shared preferences.
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setInt('cartCount_${_session!.user.id}', _cartCount);
//       debugPrint('Cart count refreshed: $_cartCount');
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error refreshing cart count: $e');
//       // Fallback to shared preferences if Supabase fails.
//       await _loadCartCount();
//     }
//   }

//   /// Loads the cart count from shared preferences as a fallback.
//   Future<void> _loadCartCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (_session != null) {
//       _cartCount = prefs.getInt('cartCount_${_session!.user.id}') ?? 0;
//       debugPrint('Cart count loaded from SharedPreferences: $_cartCount');
//     } else {
//       _cartCount = 0;
//       debugPrint('Cart count reset to 0 (no session).');
//     }
//     notifyListeners();
//   }

//   /// Signs out the user and clears the session.
//   Future<String?> signOut() async {
//     try {
//       await _spb.auth.signOut();
//       updateSession(null);
//       debugPrint('User signed out successfully.');
//       return null;
//     } catch (e) {
//       debugPrint('Error signing out: $e');
//       notifyListeners();
//       return 'Error signing out: $e';
//     }
//   }

//   /// Updates the session, fetching profile data if a session exists.
//   Future<void> updateSession(Session? newSession) async {
//     _session = newSession;

//     if (_session == null) {
//       // Clear state when the user logs out.
//       _profile = null;
//       _cartCount = 0;
//       _buyerLocation = null;
//       _sellerLocation = null;
//       _locationReady = false;

//       // Remove cart count from shared preferences.
//       final prefs = await SharedPreferences.getInstance();
//       if (_session != null) {
//         await prefs.remove('cartCount_${_session!.user.id}');
//       }
//       debugPrint('Session cleared, all state reset.');
//     } else {
//       // Fetch profile data when a session is set.
//       try {
//         _profile = await _spb
//             .from('profiles')
//             .select('*')
//             .eq('id', _session!.user.id)
//             .single();
//         debugPrint('Profile fetched: $_profile');
//       } catch (e) {
//         _profile = null;
//         debugPrint('Error fetching profile: $e');
//       }

//       // Refresh cart count for the new session.
//       await refreshCartCount();
//     }

//     notifyListeners();
//   }
// }



import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages the global state of the Markeet app, including user session,
/// buyer/seller locations, cart count, and user profile data.
class AppState extends ChangeNotifier {
  /// Supabase client instance for interacting with the backend.
  final _spb = Supabase.instance.client;

  /// Current user session, null if the user is not logged in.
  Session? _session;

  /// User's profile data fetched from the 'profiles' table.
  Map<String, dynamic>? _profile;

  /// Buyer's location as a map with 'lat' and 'lon'.
  Map<String, double>? _buyerLocation;

  /// Seller's location as a map with 'lat' and 'lon'.
  Map<String, double>? _sellerLocation;

  /// Indicates whether the buyer's location is ready for use.
  bool _locationReady = false;

  /// Number of items in the user's cart.
  int _cartCount = 0;

  /// Getters for accessing private fields.
  Session? get session => _session;
  Map<String, dynamic>? get profile => _profile;
  Map<String, double>? get buyerLocation => _buyerLocation;
  Map<String, double>? get sellerLocation => _sellerLocation;
  bool get locationReady => _locationReady;
  int get cartCount => _cartCount;

  AppState() {
    // Initialize session
    _session = _spb.auth.currentSession;
    debugPrint('Initial session: ${_session != null}');
    // Listen to auth state changes
    _spb.auth.onAuthStateChange.listen((data) {
      debugPrint('Auth state changed: session=${data.session != null}, event=${data.event}');
      updateSession(data.session);
    });
    _loadCartCount();
  }

  /// Ensures the buyer's location is available, requesting it if not already set.
  Future<void> ensureBuyerLocation() async {
    if (_locationReady) return;
    try {
      // Request location permission.
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied.');
        _locationReady = false;
        notifyListeners();
        return;
      }

      // Get the current position.
      final position = await Geolocator.getCurrentPosition();
      _buyerLocation = {'lat': position.latitude, 'lon': position.longitude};
      _locationReady = true;
      debugPrint('Buyer location set: $_buyerLocation');
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting buyer location: $e');
      _locationReady = false;
      notifyListeners();
    }
  }

  /// Manually sets the buyer's location.
  void setBuyerLocation(double lat, double lon) {
    _buyerLocation = {'lat': lat, 'lon': lon};
    _locationReady = true;
    debugPrint('Buyer location manually set: $_buyerLocation');
    notifyListeners();
  }

  /// Manually sets the seller's location.
  void setSellerLocation(double lat, double lon) {
    _sellerLocation = {'lat': lat, 'lon': lon};
    debugPrint('Seller location set: $_sellerLocation');
    notifyListeners();
  }

  /// Clears both buyer and seller locations.
  void clearLocations() {
    _buyerLocation = null;
    _sellerLocation = null;
    _locationReady = false;
    debugPrint('Locations cleared.');
    notifyListeners();
  }

  /// Refreshes the cart count by querying the 'cart' table in Supabase.
  Future<void> refreshCartCount() async {
    if (_session == null) {
      if (_cartCount != 0) {
        _cartCount = 0;
        debugPrint('Cart count reset to 0 (no session).');
        notifyListeners();
      }
      return;
    }

    try {
      final response = await _spb
          .from('cart')
          .select('id')
          .eq('user_id', _session!.user.id);
      if (response == null) {
        debugPrint('Supabase returned null response for cart count.');
        _cartCount = 0;
      } else {
        _cartCount = (response as List).length;
      }

      // Persist the cart count to shared preferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cartCount_${_session!.user.id}', _cartCount);
      debugPrint('Cart count refreshed: $_cartCount');
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing cart count: $e');
      // Fallback to shared preferences if Supabase fails.
      await _loadCartCount();
    }
  }

  /// Loads the cart count from shared preferences as a fallback.
  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (_session != null) {
      _cartCount = prefs.getInt('cartCount_${_session!.user.id}') ?? 0;
      debugPrint('Cart count loaded from SharedPreferences: $_cartCount');
    } else {
      if (_cartCount != 0) {
        _cartCount = 0;
        debugPrint('Cart count reset to 0 (no session).');
        notifyListeners();
      }
    }
  }

  /// Signs out the user and clears the session.
  Future<String?> signOut() async {
    try {
      await _spb.auth.signOut();
      updateSession(null);
      debugPrint('User signed out successfully.');
      return null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      notifyListeners();
      return 'Error signing out: $e';
    }
  }

  /// Updates the session, fetching profile data if a session exists.
  Future<void> updateSession(Session? newSession) async {
    final oldSession = _session;
    _session = newSession ?? _spb.auth.currentSession;

    if (_session == null) {
      if (_profile != null || _cartCount != 0 || _buyerLocation != null || _sellerLocation != null) {
        _profile = null;
        _cartCount = 0;
        _buyerLocation = null;
        _sellerLocation = null;
        _locationReady = false;
        final prefs = await SharedPreferences.getInstance();
        if (oldSession != null) {
          await prefs.remove('cartCount_${oldSession.user.id}');
        }
        debugPrint('Session cleared, all state reset.');
        notifyListeners();
      }
    } else {
      try {
        _profile = await _spb
            .from('profiles')
            .select('*')
            .eq('id', _session!.user.id)
            .single();
        debugPrint('Profile fetched: $_profile');
      } catch (e) {
        _profile = null;
        debugPrint('Error fetching profile: $e');
      }
      await refreshCartCount();
      if (oldSession?.user.id != _session!.user.id) {
        notifyListeners();
      }
    }
  }
}