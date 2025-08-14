// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../state/app_state.dart';

// class AuthPage extends StatefulWidget {
//   const AuthPage({super.key});
//   @override
//   State<AuthPage> createState() => _AuthPageState();
// }

// class _AuthPageState extends State<AuthPage> {
//   final _spb = Supabase.instance.client;

//   // form state
//   bool _signUp = false;
//   bool _isSeller = false;
//   bool _loading = false;
//   String _msg = '';

//   // controllers
//   final _nameC = TextEditingController();
//   final _emailC = TextEditingController();
//   final _passC = TextEditingController();
//   final _phoneC = TextEditingController();
//   final _otpC = TextEditingController();

//   // otp helpers
//   bool _otpSent = false;
//   int _cooldown = 0;
//   Timer? _cooldownTimer;

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _emailC.dispose();
//     _passC.dispose();
//     _phoneC.dispose();
//     _otpC.dispose();
//     _cooldownTimer?.cancel();
//     super.dispose();
//   }

//   // ─── Google ───────────────────────────────────────────────────────────────
//   Future<void> _google() async {
//     setState(() => _loading = true);
//     try {
//       await _spb.auth.signInWithOAuth(
//   OAuthProvider.google,
//   redirectTo: null,            // optional; keep it if you rely on deep-link
// );

//       // redirect handled by onAuthStateChange in AppState
//     } catch (e) {
//       setState(() => _msg = 'Google sign-in failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── OTP flow ──────────────────────────────────────────────────────────────
//   Future<void> _sendOtp() async {
//     final phone = _phoneC.text.trim();
//     if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(phone)) {
//       setState(() => _msg = 'Enter a valid phone (e.g. +919876543210)');
//       return;
//     }
//     setState(() {
//       _loading = true;
//       _msg = '';
//     });
//     try {
//       await _spb.auth.signInWithOtp(phone: phone);
//       setState(() {
//         _otpSent = true;
//         _cooldown = 30;
//       });
//       _cooldownTimer?.cancel();
//       _cooldownTimer =
//           Timer.periodic(const Duration(seconds: 1), (t) => setState(() {
//                 if (_cooldown == 0) t.cancel();
//                 else _cooldown--;
//               }));
//     } catch (e) {
//       setState(() => _msg = 'OTP send failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _verifyOtp() async {
//     if (_otpC.text.isEmpty) {
//       setState(() => _msg = 'Enter the OTP');
//       return;
//     }
//     setState(() {
//       _loading = true;
//       _msg = '';
//     });
//     try {
//       await _spb.auth.verifyOTP(
//         type: OtpType.sms,
//         phone: _phoneC.text.trim(),
//         token: _otpC.text.trim(),
//       );
//       if (_signUp) await _emailAuth(); // continue signup flow
//     } catch (e) {
//       setState(() => _msg = 'Invalid OTP');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── Email / Password ─────────────────────────────────────────────────────
//   Future<void> _emailAuth() async {
//     FocusScope.of(context).unfocus();
//     final email = _emailC.text.trim();
//     final pass = _passC.text;
//     if (_signUp && email.isEmpty && _phoneC.text.isEmpty) {
//       setState(() => _msg = 'Provide email or phone');
//       return;
//     }
//     if (_signUp && _phoneC.text.isNotEmpty && !_otpSent) {
//       setState(() => _msg = 'Verify phone first');
//       return;
//     }

//     setState(() {
//       _loading = true;
//       _msg = '';
//     });

//     try {
//       if (_signUp) {
//         final resp = await _spb.auth.signUp(email: email, password: pass);
//         final id = resp.user?.id;
//         if (id != null) {
//           await _spb.from('profiles').upsert({
//             'id': id,
//             'full_name': _nameC.text.isEmpty
//                 ? email.split('@')[0]
//                 : _nameC.text.trim(),
//             'is_seller': _isSeller,
//             'phone_number': _phoneC.text.isEmpty ? null : _phoneC.text.trim(),
//           });
//           if (_isSeller) {
//             await _spb.from('sellers').upsert({
//               'id': id,
//               'store_name':
//                   '${_nameC.text.isEmpty ? email.split("@")[0] : _nameC.text} Store'
//             });
//           }
//         }
//         setState(() => _msg =
//             'Sign-up successful. Verify the email sent to you to continue.');
//       } else {
//         await _spb.auth.signInWithPassword(email: email, password: pass);
//         // redirect handled by AppState listener
//       }
//     } catch (e) {
//       setState(() => _msg = 'Auth failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── UI ────────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     // already logged-in?  goRouter redirect will have handled but safe-guard:
//     if (context.watch<AppState>().session != null) {
//       context.go('/account');
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text(_signUp ? 'Sign Up' : 'Login')),
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 420),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               children: [
//                 // Google
//                 ElevatedButton(
//                   onPressed: _loading ? null : _google,
//                   child: Text(_loading ? 'Please wait…' : 'Continue with Google'),
//                 ),
//                 const SizedBox(height: 16),
//                 Divider(color: theme.dividerColor),
//                 const SizedBox(height: 16),

//                 // form
//                 if (_signUp)
//                   TextField(
//                     controller: _nameC,
//                     decoration:
//                         const InputDecoration(labelText: 'Full name *'),
//                   ),
//                 if (_signUp)
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: _isSeller,
//                         onChanged: _loading
//                             ? null
//                             : (v) => setState(() => _isSeller = v ?? false),
//                       ),
//                       const Text('Register as Seller'),
//                     ],
//                   ),
//                 TextField(
//                   controller: _emailC,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   enabled: !_loading && _phoneC.text.isEmpty,
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _passC,
//                   decoration: const InputDecoration(labelText: 'Password'),
//                   obscureText: true,
//                   enabled: !_loading,
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _loading ? null : _emailAuth,
//                   child: Text(_loading
//                       ? 'Processing…'
//                       : _signUp
//                           ? 'Sign Up'
//                           : 'Login'),
//                 ),
//                 const SizedBox(height: 24),
//                 Divider(color: theme.dividerColor),
//                 const SizedBox(height: 16),

//                 // phone / OTP
//                 TextField(
//                   controller: _phoneC,
//                   keyboardType: TextInputType.phone,
//                   decoration: const InputDecoration(
//                       labelText: 'Phone (+91…)',
//                       hintText: '+919876543210'),
//                   enabled: !_loading && !_otpSent,
//                 ),
//                 const SizedBox(height: 8),
//                 if (!_otpSent)
//                   OutlinedButton(
//                     onPressed: _loading ? null : _sendOtp,
//                     child: Text(_loading ? 'Sending…' : 'Send OTP'),
//                   )
//                 else ...[
//                   TextField(
//                     controller: _otpC,
//                     decoration:
//                         const InputDecoration(labelText: 'Enter OTP'),
//                     enabled: !_loading,
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: _loading ? null : _verifyOtp,
//                           child:
//                               Text(_loading ? 'Verifying…' : 'Verify OTP'),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       TextButton(
//                         onPressed: _loading || _cooldown > 0 ? null : _sendOtp,
//                         child: Text(_cooldown > 0
//                             ? 'Resend in $_cooldown s'
//                             : 'Resend OTP'),
//                       ),
//                     ],
//                   )
//                 ],

//                 const SizedBox(height: 16),
//                 if (_msg.isNotEmpty)
//                   Text(
//                     _msg,
//                     style: TextStyle(color: theme.colorScheme.error),
//                     textAlign: TextAlign.center,
//                   ),
//                 const SizedBox(height: 24),

//                 TextButton(
//                   onPressed: _loading
//                       ? null
//                       : () => setState(() {
//                             _signUp = !_signUp;
//                             _msg = '';
//                             _otpSent = false;
//                             _cooldown = 0;
//                           }),
//                   child: Text(_signUp
//                       ? 'Have an account? Login'
//                       : 'Need an account? Sign up'),
//                 ),
//                 const SizedBox(height: 16),
//                 Wrap(
//                   alignment: WrapAlignment.center,
//                   spacing: 16,
//                   children: [
//                     TextButton(
//                       onPressed: () => context.go('/policy'),
//                       child: const Text('Policies'),
//                     ),
//                     TextButton(
//                       onPressed: () => context.go('/privacy'),
//                       child: const Text('Privacy'),
//                     ),
//                   ],
//                 ),
//                 TextButton(
//                   onPressed: () => context.go('/'),
//                   child: const Text('← Back to Home'),
//                 ),
//               ],
//             ),
//           ),
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

// import '../state/app_state.dart';

// // Define the same premium color palette for consistency
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// class AuthPage extends StatefulWidget {
//   const AuthPage({super.key});
//   @override
//   State<AuthPage> createState() => _AuthPageState();
// }

// class _AuthPageState extends State<AuthPage> {
//   final _spb = Supabase.instance.client;

//   // Form state
//   bool _signUp = false;
//   bool _isSeller = false;
//   bool _loading = false;
//   String _msg = '';

//   // Controllers
//   final _nameC = TextEditingController();
//   final _emailC = TextEditingController();
//   final _passC = TextEditingController();
//   final _phoneC = TextEditingController();
//   final _otpC = TextEditingController();

//   // OTP helpers
//   bool _otpSent = false;
//   int _cooldown = 0;
//   Timer? _cooldownTimer;

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _emailC.dispose();
//     _passC.dispose();
//     _phoneC.dispose();
//     _otpC.dispose();
//     _cooldownTimer?.cancel();
//     super.dispose();
//   }

//   // ─── Google ───────────────────────────────────────────────────────────────
//   Future<void> _google() async {
//     setState(() => _loading = true);
//     try {
//       await _spb.auth.signInWithOAuth(
//         OAuthProvider.google,
//         redirectTo: null, // Optional; keep it if you rely on deep-link
//       );
//       // Redirect handled by onAuthStateChange in AppState
//     } catch (e) {
//       setState(() => _msg = 'Google sign-in failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── OTP Flow ──────────────────────────────────────────────────────────────
//   Future<void> _sendOtp() async {
//     final phone = _phoneC.text.trim();
//     if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(phone)) {
//       setState(() => _msg = 'Enter a valid phone (e.g. +919876543210)');
//       return;
//     }
//     setState(() {
//       _loading = true;
//       _msg = '';
//     });
//     try {
//       await _spb.auth.signInWithOtp(phone: phone);
//       setState(() {
//         _otpSent = true;
//         _cooldown = 30;
//       });
//       _cooldownTimer?.cancel();
//       _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() {
//             if (_cooldown == 0) t.cancel();
//             else _cooldown--;
//           }));
//     } catch (e) {
//       setState(() => _msg = 'OTP send failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _verifyOtp() async {
//     if (_otpC.text.isEmpty) {
//       setState(() => _msg = 'Enter the OTP');
//       return;
//     }
//     setState(() {
//       _loading = true;
//       _msg = '';
//     });
//     try {
//       await _spb.auth.verifyOTP(
//         type: OtpType.sms,
//         phone: _phoneC.text.trim(),
//         token: _otpC.text.trim(),
//       );
//       if (_signUp) await _emailAuth(); // Continue signup flow
//     } catch (e) {
//       setState(() => _msg = 'Invalid OTP');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── Email / Password ─────────────────────────────────────────────────────
//   Future<void> _emailAuth() async {
//     FocusScope.of(context).unfocus();
//     final email = _emailC.text.trim();
//     final pass = _passC.text;
//     if (_signUp && email.isEmpty && _phoneC.text.isEmpty) {
//       setState(() => _msg = 'Provide email or phone');
//       return;
//     }
//     if (_signUp && _phoneC.text.isNotEmpty && !_otpSent) {
//       setState(() => _msg = 'Verify phone first');
//       return;
//     }

//     setState(() {
//       _loading = true;
//       _msg = '';
//     });

//     try {
//       if (_signUp) {
//         final resp = await _spb.auth.signUp(email: email, password: pass);
//         final id = resp.user?.id;
//         if (id != null) {
//           await _spb.from('profiles').upsert({
//             'id': id,
//             'full_name': _nameC.text.isEmpty
//                 ? email.split('@')[0]
//                 : _nameC.text.trim(),
//             'is_seller': _isSeller,
//             'phone_number': _phoneC.text.isEmpty ? null : _phoneC.text.trim(),
//           });
//           if (_isSeller) {
//             await _spb.from('sellers').upsert({
//               'id': id,
//               'store_name':
//                   '${_nameC.text.isEmpty ? email.split("@")[0] : _nameC.text} Store'
//             });
//           }
//         }
//         setState(() => _msg =
//             'Sign-up successful. Verify the email sent to you to continue.');
//       } else {
//         await _spb.auth.signInWithPassword(email: email, password: pass);
//         // Redirect handled by AppState listener
//       }
//     } catch (e) {
//       setState(() => _msg = 'Auth failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // ─── UI ────────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     // Already logged-in? GoRouter redirect will have handled but safe-guard:
//     if (context.watch<AppState>().session != null) {
//       context.go('/account');
//     }

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: AppBar(
//         title: Text(
//           _signUp ? 'Sign Up' : 'Login',
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
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 420),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Card(
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header Text
//                     Text(
//                       _signUp ? 'Create an Account' : 'Welcome Back',
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         color: premiumTextColor,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 24,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _signUp
//                           ? 'Join us today to start shopping!'
//                           : 'Login to continue shopping.',
//                       style: TextStyle(
//                         color: premiumSecondaryTextColor,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Google Sign-In
//                     ElevatedButton.icon(
//                       onPressed: _loading ? null : _google,
//                       icon: const Icon(Icons.g_mobiledata, color: Colors.white),
//                       label: Text(
//                         _loading ? 'Please wait…' : 'Continue with Google',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: premiumPrimaryColor,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 4,
//                         shadowColor: Colors.black.withOpacity(0.2),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Divider(color: theme.dividerColor),
//                     const SizedBox(height: 16),

//                     // Form
//                     if (_signUp) ...[
//                       TextField(
//                         controller: _nameC,
//                         decoration: InputDecoration(
//                           labelText: 'Full Name *',
//                           labelStyle: TextStyle(color: premiumSecondaryTextColor),
//                           prefixIcon: const Icon(Icons.person_outline,
//                               color: premiumSecondaryTextColor),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(color: Colors.grey),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(
//                                 color: premiumPrimaryColor, width: 2),
//                           ),
//                           enabled: !_loading,
//                         ),
//                         style: const TextStyle(color: premiumTextColor),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Checkbox(
//                             value: _isSeller,
//                             onChanged: _loading
//                                 ? null
//                                 : (v) => setState(() => _isSeller = v ?? false),
//                             activeColor: premiumPrimaryColor,
//                           ),
//                           const Text(
//                             'Register as Seller',
//                             style: TextStyle(
//                               color: premiumTextColor,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                     TextField(
//                       controller: _emailC,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: TextStyle(color: premiumSecondaryTextColor),
//                         prefixIcon: const Icon(Icons.email_outlined,
//                             color: premiumSecondaryTextColor),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Colors.grey),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                               color: premiumPrimaryColor, width: 2),
//                         ),
//                         enabled: !_loading && _phoneC.text.isEmpty,
//                       ),
//                       style: const TextStyle(color: premiumTextColor),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _passC,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         labelStyle: TextStyle(color: premiumSecondaryTextColor),
//                         prefixIcon: const Icon(Icons.lock_outline,
//                             color: premiumSecondaryTextColor),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Colors.grey),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                               color: premiumPrimaryColor, width: 2),
//                         ),
//                         enabled: !_loading,
//                       ),
//                       obscureText: true,
//                       style: const TextStyle(color: premiumTextColor),
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _loading ? null : _emailAuth,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: premiumPrimaryColor,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 24, vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 4,
//                           shadowColor: Colors.black.withOpacity(0.2),
//                         ),
//                         child: Text(
//                           _loading
//                               ? 'Processing…'
//                               : _signUp
//                                   ? 'Sign Up'
//                                   : 'Login',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Divider(color: theme.dividerColor),
//                     const SizedBox(height: 16),

//                     // Phone / OTP
//                     TextField(
//                       controller: _phoneC,
//                       keyboardType: TextInputType.phone,
//                       decoration: InputDecoration(
//                         labelText: 'Phone (+91…)',
//                         hintText: '+919876543210',
//                         labelStyle: TextStyle(color: premiumSecondaryTextColor),
//                         prefixIcon: const Icon(Icons.phone_outlined,
//                             color: premiumSecondaryTextColor),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Colors.grey),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                               color: premiumPrimaryColor, width: 2),
//                         ),
//                         enabled: !_loading && !_otpSent,
//                       ),
//                       style: const TextStyle(color: premiumTextColor),
//                     ),
//                     const SizedBox(height: 16),
//                     if (!_otpSent)
//                       SizedBox(
//                         width: double.infinity,
//                         child: OutlinedButton(
//                           onPressed: _loading ? null : _sendOtp,
//                           style: OutlinedButton.styleFrom(
//                             side: const BorderSide(
//                                 color: premiumPrimaryColor, width: 1.5),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 24, vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: Text(
//                             _loading ? 'Sending…' : 'Send OTP',
//                             style: const TextStyle(
//                               color: premiumPrimaryColor,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                       )
//                     else ...[
//                       TextField(
//                         controller: _otpC,
//                         decoration: InputDecoration(
//                           labelText: 'Enter OTP',
//                           labelStyle: TextStyle(color: premiumSecondaryTextColor),
//                           prefixIcon: const Icon(Icons.sms_outlined,
//                               color: premiumSecondaryTextColor),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(color: Colors.grey),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(
//                                 color: premiumPrimaryColor, width: 2),
//                           ),
//                           enabled: !_loading,
//                         ),
//                         style: const TextStyle(color: premiumTextColor),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: _loading ? null : _verifyOtp,
//                               style: OutlinedButton.styleFrom(
//                                 side: const BorderSide(
//                                     color: premiumPrimaryColor, width: 1.5),
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 24, vertical: 14),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: Text(
//                                 _loading ? 'Verifying…' : 'Verify OTP',
//                                 style: const TextStyle(
//                                   color: premiumPrimaryColor,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           TextButton(
//                             onPressed: _loading || _cooldown > 0 ? null : _sendOtp,
//                             child: Text(
//                               _cooldown > 0
//                                   ? 'Resend in $_cooldown s'
//                                   : 'Resend OTP',
//                               style: TextStyle(
//                                 color: _cooldown > 0
//                                     ? premiumSecondaryTextColor
//                                     : premiumPrimaryColor,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],

//                     const SizedBox(height: 24),
//                     if (_msg.isNotEmpty)
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: theme.colorScheme.error.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: theme.colorScheme.error),
//                         ),
//                         child: Text(
//                           _msg,
//                           style: TextStyle(
//                             color: theme.colorScheme.error,
//                             fontSize: 14,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     const SizedBox(height: 24),

//                     Center(
//                       child: TextButton(
//                         onPressed: _loading
//                             ? null
//                             : () => setState(() {
//                                   _signUp = !_signUp;
//                                   _msg = '';
//                                   _otpSent = false;
//                                   _cooldown = 0;
//                                 }),
//                         child: Text(
//                           _signUp
//                               ? 'Have an account? Login'
//                               : 'Need an account? Sign up',
//                           style: const TextStyle(
//                             color: premiumPrimaryColor,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 16,
//                       children: [
//                         TextButton(
//                           onPressed: () => context.go('/policy'),
//                           child: const Text(
//                             'Policies',
//                             style: TextStyle(
//                               color: premiumSecondaryTextColor,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () => context.go('/privacy'),
//                           child: const Text(
//                             'Privacy',
//                             style: TextStyle(
//                               color: premiumSecondaryTextColor,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Center(
//                       child: TextButton(
//                         onPressed: () => context.go('/'),
//                         child: const Text(
//                           '← Back to Home',
//                           style: TextStyle(
//                             color: premiumPrimaryColor,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../state/app_state.dart';

// // Premium color palette matching React
// const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
// const premiumAccentColor = Color(0xFFFFD740); // Gold
// const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
// const premiumTextColor = Color(0xFF212121); // Dark Grey
// const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// // Validation constants
// final indianPhone = RegExp(r'^\+91\d{10}$');
// const minNameLength = 2;
// const minPasswordLength = 6;

// class AuthPage extends StatefulWidget {
//   const AuthPage({super.key});

//   @override
//   State<AuthPage> createState() => _AuthPageState();
// }

// class _AuthPageState extends State<AuthPage> {
//   final _spb = Supabase.instance.client;

//   // State
//   String _mode = 'login'; // login | signup | forgot | edit
//   final _nameC = TextEditingController();
//   final _phoneC = TextEditingController(text: '+91');
//   final _passC = TextEditingController();
//   final _confirmPassC = TextEditingController();
//   final _otpC = TextEditingController();
//   bool _otpSent = false;
//   bool _otpVerified = false;
//   bool _loading = false;
//   int _cooldown = 0;
//   bool _showPwd = false;
//   bool _showConfirm = false;
//   Timer? _cooldownTimer;

//   @override
//   void initState() {
//     super.initState();
//     // Watch Supabase session
//     _fetchSession();
//     _spb.auth.onAuthStateChange.listen((data) {
//       if (data.event == AuthChangeEvent.signedIn && _mode != 'edit') {
//         context.pushReplacement('/');
//       } else if (data.event == AuthChangeEvent.signedOut) {
//         context.pushReplacement('/auth');
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _nameC.dispose();
//     _phoneC.dispose();
//     _passC.dispose();
//     _confirmPassC.dispose();
//     _otpC.dispose();
//     _cooldownTimer?.cancel();
//     super.dispose();
//   }

//   // Helpers
//   void _resetUI() {
//     _otpC.clear();
//     _otpSent = false;
//     _otpVerified = false;
//     _cooldown = 0;
//     _cooldownTimer?.cancel();
//   }

//   void _switchMode(String m) {
//     setState(() {
//       _mode = m;
//       _passC.clear();
//       _confirmPassC.clear();
//       _nameC.clear();
//       _phoneC.text = '+91';
//       _resetUI();
//     });
//   }

//   bool _validPhone(String p) => indianPhone.hasMatch(p);

//   bool _validName(String n) =>
//       n.trim().isNotEmpty &&
//       n.trim().toLowerCase() != 'user' &&
//       n.trim().length >= minNameLength;

//   void _showError(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_LONG,
//       gravity: ToastGravity.TOP,
//       backgroundColor: const Color(0xFFEF4444),
//       textColor: Colors.white,
//       fontSize: 16,
//       timeInSecForIosWeb: 3,
//     );
//   }

//   void _showSuccess(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_LONG,
//       gravity: ToastGravity.TOP,
//       backgroundColor: const Color(0xFF2ECC71),
//       textColor: Colors.white,
//       fontSize: 16,
//       timeInSecForIosWeb: 3,
//     );
//   }

//   // Session fetch
//   Future<void> _fetchSession() async {
//     try {
//       final session = _spb.auth.currentSession;
//       if (session != null) {
//         if (_mode == 'edit') {
//           final profile = await _spb
//               .from('profiles')
//               .select('full_name, phone_number')
//               .eq('id', session.user.id)
//               .single();
//           setState(() {
//             _nameC.text = profile['full_name'] ?? '';
//             _phoneC.text = profile['phone_number'] ?? '+91';
//           });
//         } else {
//           context.pushReplacement('/');
//         }
//       }
//     } catch (e) {
//       debugPrint('Session fetch error: $e');
//       _showError('Failed to fetch session. Please try again.');
//     }
//   }

//   // Cooldown timer
//   void _startCooldown() {
//     _cooldownTimer?.cancel();
//     _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       setState(() {
//         if (_cooldown == 0) {
//           t.cancel();
//         } else {
//           _cooldown--;
//         }
//       });
//     });
//   }

//   // DB Util
//   Future<bool> _phoneExists(String ph) async {
//     try {
//       final response = await _spb
//           .from('profiles')
//           .select('id')
//           .eq('phone_number', ph)
//           .maybeSingle();
//       return response != null;
//     } catch (e) {
//       debugPrint('Phone check error: $e');
//       throw Exception('Database error while checking phone');
//     }
//   }

//   // OTP Handlers
//   Future<void> _sendOtp() async {
//     if (!_validPhone(_phoneC.text)) {
//       _showError('Enter a valid +91 phone number (e.g., +919876543210)');
//       return;
//     }
//     if (_cooldown > 0) {
//       _showError('Please wait ${_cooldown}s to resend OTP');
//       return;
//     }
//     if (_mode == 'signup') {
//       if (!_validName(_nameC.text)) {
//         _showError('Full name must be at least 2 characters and not "User"');
//         return;
//       }
//       if (_passC.text.length < minPasswordLength) {
//         _showError('Password must be at least $minPasswordLength characters');
//         return;
//       }
//       if (_passC.text != _confirmPassC.text) {
//         _showError('Passwords do not match');
//         return;
//       }
//     }
//     setState(() => _loading = true);
//     try {
//       await _spb.auth.signInWithOtp(
//         phone: _phoneC.text,
//         data: _mode == 'signup' ? {'full_name': _nameC.text.trim()} : null,
//       );
//       setState(() {
//         _otpSent = true;
//         _cooldown = 30;
//       });
//       _startCooldown();
//       _showSuccess('OTP sent to your phone');
//     } catch (e) {
//       debugPrint('OTP send error: $e');
//       if (e.toString().contains('already registered')) {
//         _showError(
//             'This phone number is already registered. Please log in or use a different number.');
//       } else {
//         _showError('Failed to send OTP');
//       }
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _verifyOtp() async {
//     if (_otpC.text.isEmpty) {
//       _showError('Please enter the OTP');
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       final response = await _spb.auth.verifyOTP(
//         phone: _phoneC.text,
//         token: _otpC.text,
//         type: OtpType.sms,
//       );
//       setState(() {
//         _otpVerified = true;
//         _otpSent = false;
//         _otpC.clear();
//       });
//       _showSuccess('Phone number verified');
//       if (_mode == 'signup') {
//         await _finishSignup(response.user);
//       } else if (_mode == 'forgot') {
//         // Wait for password reset
//       } else {
//         context.pushReplacement('/');
//       }
//     } catch (e) {
//       debugPrint('OTP verify error: $e');
//       _showError('Invalid OTP');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Signup Flow
//   Future<void> _finishSignup(User? user) async {
//     if (user == null) {
//       _showError('User not found');
//       return;
//     }
//     try {
//       await _spb.from('profiles').upsert({
//         'id': user.id,
//         'full_name': _nameC.text.trim(),
//         'phone_number': _phoneC.text,
//         'is_seller': false,
//         'created_at': DateTime.now().toIso8601String(),
//         'updated_at': DateTime.now().toIso8601String(),
//       });
//       await _spb.auth.updateUser(
//         UserAttributes(password: _passC.text),
//       );
//       final profile = await _spb
//           .from('profiles')
//           .select('full_name, phone_number')
//           .eq('id', user.id)
//           .single();
//       if (profile['full_name'] == null || profile['phone_number'] == null) {
//         _showError('Please complete your profile details');
//         _switchMode('edit');
//       } else {
//         _showSuccess('Signed up successfully');
//         context.pushReplacement('/');
//       }
//     } catch (e) {
//       debugPrint('Signup finish error: $e');
//       _showError('Signup failed');
//     }
//   }

//   // Login & Reset
//   Future<void> _handleLogin() async {
//     if (!_validPhone(_phoneC.text)) {
//       _showError('Enter a valid +91 phone number');
//       return;
//     }
//     if (_passC.text.isEmpty) {
//       _showError('Password is required');
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       await _spb.auth.signInWithPassword(
//         phone: _phoneC.text,
//         password: _passC.text,
//       );
//       _showSuccess('Login successful');
//       context.pushReplacement('/');
//     } catch (e) {
//       debugPrint('Login error: $e');
//       _showError('Invalid credentials');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _forgotStart() async {
//     if (!_validPhone(_phoneC.text)) {
//       _showError('Enter a valid +91 phone number');
//       return;
//     }
//     if (!await _phoneExists(_phoneC.text)) {
//       _showError('No account found for this phone number');
//       return;
//     }
//     await _sendOtp();
//   }

//   Future<void> _resetPw() async {
//     if (!_otpVerified) {
//       _showError('Please verify OTP first');
//       return;
//     }
//     if (_passC.text != _confirmPassC.text) {
//       _showError('Passwords do not match');
//       return;
//     }
//     if (_passC.text.length < minPasswordLength) {
//       _showError('Password must be at least $minPasswordLength characters');
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       await _spb.auth.updateUser(
//         UserAttributes(password: _passC.text),
//       );
//       final user = await _spb.auth.getUser();
//       final profile = await _spb
//           .from('profiles')
//           .select('phone_number')
//           .eq('id', user.user!.id)
//           .single();
//       if (profile['phone_number'] == null) {
//         await _spb.from('profiles').upsert({
//           'id': user.user!.id,
//           'phone_number': _phoneC.text,
//           'is_seller': false,
//           'updated_at': DateTime.now().toIso8601String(),
//         });
//       }
//       _showSuccess('Password reset successful. Please log in.');
//       _switchMode('login');
//     } catch (e) {
//       debugPrint('Password reset error: $e');
//       _showError('Password reset failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Profile Update
//   Future<void> _handleProfileUpdate() async {
//     if (!_validName(_nameC.text)) {
//       _showError('Full name must be at least 2 characters and not "User"');
//       return;
//     }
//     if (!_validPhone(_phoneC.text)) {
//       _showError('Enter a valid +91 phone number');
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       final user = await _spb.auth.getUser();
//       await _spb.from('profiles').upsert({
//         'id': user.user!.id,
//         'full_name': _nameC.text.trim(),
//         'phone_number': _phoneC.text,
//         'is_seller': false,
//         'updated_at': DateTime.now().toIso8601String(),
//       });
//       _showSuccess('Profile updated successfully');
//       context.pushReplacement('/');
//     } catch (e) {
//       debugPrint('Profile update error: $e');
//       _showError('Failed to update profile');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // Google Sign-In
//   Future<void> _google() async {
//     setState(() => _loading = true);
//     try {
//       await _spb.auth.signInWithOAuth(
//         OAuthProvider.google,
//         redirectTo: 'com.example.markeet://login-callback/',
//       );
//     } catch (e) {
//       debugPrint('Google sign-in error: $e');
//       _showError('Google sign-in failed');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   // UI
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     if (context.watch<AppState>().session != null && _mode != 'edit') {
//       context.pushReplacement('/account');
//     }

//     return Scaffold(
//       backgroundColor: premiumBackgroundColor,
//       appBar: AppBar(
//         title: Text(
//           _mode == 'signup'
//               ? 'Sign Up'
//               : _mode == 'forgot'
//                   ? 'Reset Password'
//                   : _mode == 'edit'
//                       ? 'Update Profile'
//                       : 'Login',
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
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 420),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Card(
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Form(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _mode == 'signup'
//                             ? 'Create an Account'
//                             : _mode == 'forgot'
//                                 ? 'Reset Your Password'
//                                 : _mode == 'edit'
//                                     ? 'Update Your Profile'
//                                     : 'Welcome Back',
//                         style: theme.textTheme.titleLarge?.copyWith(
//                           color: premiumTextColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 24,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _mode == 'signup'
//                             ? 'Join us today to start shopping!'
//                             : _mode == 'forgot'
//                                 ? 'Reset your password to continue.'
//                                 : _mode == 'edit'
//                                     ? 'Update your profile details.'
//                                     : 'Login to continue shopping.',
//                         style: const TextStyle(
//                           color: premiumSecondaryTextColor,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       ElevatedButton.icon(
//                         onPressed: _loading ? null : _google,
//                         icon: const Icon(Icons.g_mobiledata, color: Colors.white),
//                         label: Text(
//                           _loading ? 'Please wait…' : 'Continue with Google',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: premiumPrimaryColor,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 24, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 4,
//                           shadowColor: Colors.black.withOpacity(0.2),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Divider(color: theme.dividerColor),
//                       const SizedBox(height: 16),
//                       if (_mode == 'signup' || _mode == 'edit') ...[
//                         TextFormField(
//                           controller: _nameC,
//                           decoration: InputDecoration(
//                             labelText: 'Full Name *',
//                             labelStyle:
//                                 const TextStyle(color: premiumSecondaryTextColor),
//                             prefixIcon: const Icon(Icons.person_outline,
//                                 color: premiumSecondaryTextColor),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(
//                                   color: premiumPrimaryColor, width: 2),
//                             ),
//                             enabled: !_loading &&
//                                 (_mode == 'signup' && !_otpVerified),
//                           ),
//                           style: const TextStyle(color: premiumTextColor),
//                           validator: (value) => _validName(value ?? '')
//                               ? null
//                               : 'Full name must be at least 2 characters and not "User"',
//                         ),
//                         const SizedBox(height: 16),
//                       ],
//                       TextFormField(
//                         controller: _phoneC,
//                         keyboardType: TextInputType.phone,
//                         maxLength: 13,
//                         decoration: InputDecoration(
//                           labelText: 'Phone Number *',
//                           hintText: '+919876543210',
//                           labelStyle:
//                               const TextStyle(color: premiumSecondaryTextColor),
//                           prefixIcon: const Icon(Icons.phone_outlined,
//                               color: premiumSecondaryTextColor),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(color: Colors.grey),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(
//                                 color: premiumPrimaryColor, width: 2),
//                           ),
//                           enabled: !_loading &&
//                               (_mode != 'signup' || !_otpVerified) &&
//                               (_mode != 'forgot' || !_otpSent),
//                         ),
//                         style: const TextStyle(color: premiumTextColor),
//                         validator: (value) =>
//                             _validPhone(value ?? '') ? null : 'Enter a valid +91 phone number',
//                         onChanged: (value) {
//                           if (!value.startsWith('+91')) {
//                             _phoneC.text = '+91';
//                             _phoneC.selection = TextSelection.fromPosition(
//                                 TextPosition(offset: _phoneC.text.length));
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       if ((_mode == 'signup' || _mode == 'login') && !_otpSent) ...[
//                         TextFormField(
//                           controller: _passC,
//                           obscureText: !_showPwd,
//                           decoration: InputDecoration(
//                             labelText: 'Password *',
//                             labelStyle:
//                                 const TextStyle(color: premiumSecondaryTextColor),
//                             prefixIcon: const Icon(Icons.lock_outline,
//                                 color: premiumSecondaryTextColor),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                   _showPwd ? Icons.visibility_off : Icons.visibility,
//                                   color: premiumSecondaryTextColor),
//                               onPressed: () => setState(() => _showPwd = !_showPwd),
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(
//                                   color: premiumPrimaryColor, width: 2),
//                             ),
//                             enabled: !_loading,
//                           ),
//                           style: const TextStyle(color: premiumTextColor),
//                           validator: (value) => (value?.length ?? 0) >= minPasswordLength
//                               ? null
//                               : 'Password must be at least $minPasswordLength characters',
//                         ),
//                         const SizedBox(height: 16),
//                         if (_mode == 'signup')
//                           TextFormField(
//                             controller: _confirmPassC,
//                             obscureText: !_showConfirm,
//                             decoration: InputDecoration(
//                               labelText: 'Confirm Password *',
//                               labelStyle:
//                                   const TextStyle(color: premiumSecondaryTextColor),
//                               prefixIcon: const Icon(Icons.lock_outline,
//                                   color: premiumSecondaryTextColor),
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                     _showConfirm
//                                         ? Icons.visibility_off
//                                         : Icons.visibility,
//                                     color: premiumSecondaryTextColor),
//                                 onPressed: () =>
//                                     setState(() => _showConfirm = !_showConfirm),
//                               ),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(color: Colors.grey),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                                 borderSide: const BorderSide(
//                                     color: premiumPrimaryColor, width: 2),
//                               ),
//                               enabled: !_loading,
//                             ),
//                             style: const TextStyle(color: premiumTextColor),
//                             validator: (value) =>
//                                 value == _passC.text ? null : 'Passwords do not match',
//                           ),
//                         const SizedBox(height: 16),
//                       ],
//                       if (_otpSent && (!_otpVerified || _mode != 'forgot')) ...[
//                         TextFormField(
//                           controller: _otpC,
//                           keyboardType: TextInputType.number,
//                           maxLength: 6,
//                           decoration: InputDecoration(
//                             labelText: 'Enter OTP *',
//                             labelStyle:
//                                 const TextStyle(color: premiumSecondaryTextColor),
//                             prefixIcon: const Icon(Icons.sms_outlined,
//                                 color: premiumSecondaryTextColor),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(
//                                   color: premiumPrimaryColor, width: 2),
//                             ),
//                             enabled: !_loading,
//                           ),
//                           style: const TextStyle(color: premiumTextColor),
//                           validator: (value) =>
//                               value?.isNotEmpty ?? false ? null : 'Enter the OTP',
//                           onChanged: (value) {
//                             _otpC.text = value.replaceAll(RegExp(r'[^0-9]'), '');
//                             _otpC.selection = TextSelection.fromPosition(
//                                 TextPosition(offset: _otpC.text.length));
//                           },
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton(
//                                 onPressed: _loading ? null : _verifyOtp,
//                                 style: OutlinedButton.styleFrom(
//                                   side: const BorderSide(
//                                       color: premiumPrimaryColor, width: 1.5),
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 24, vertical: 14),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   _loading ? 'Verifying...' : 'Verify OTP',
//                                   style: const TextStyle(
//                                     color: premiumPrimaryColor,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             TextButton(
//                               onPressed: _loading || _cooldown > 0 ? null : _sendOtp,
//                               child: Text(
//                                 _cooldown > 0 ? 'Resend in $_cooldown s' : 'Resend OTP',
//                                 style: TextStyle(
//                                   color: _cooldown > 0
//                                       ? premiumSecondaryTextColor
//                                       : premiumPrimaryColor,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                       ],
//                       if (!_otpSent || (_mode == 'forgot' && _otpVerified) || _mode == 'edit')
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _loading
//                                 ? null
//                                 : () {
//                                     if (_mode == 'signup') {
//                                       if (_otpSent) {
//                                         _verifyOtp();
//                                       } else {
//                                         _handleSignup();
//                                       }
//                                     } else if (_mode == 'forgot') {
//                                       if (_otpVerified) {
//                                         _resetPw();
//                                       } else {
//                                         _forgotStart();
//                                       }
//                                     } else if (_mode == 'edit') {
//                                       _handleProfileUpdate();
//                                     } else {
//                                       _handleLogin();
//                                     }
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: premiumPrimaryColor,
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 24, vertical: 14),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 4,
//                               shadowColor: Colors.black.withOpacity(0.2),
//                             ),
//                             child: Text(
//                               _loading
//                                   ? 'Processing...'
//                                   : _mode == 'signup'
//                                       ? 'Sign Up'
//                                       : _mode == 'forgot'
//                                           ? 'Save Password'
//                                           : _mode == 'edit'
//                                               ? 'Update Profile'
//                                               : 'Login',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ),
//                         ),
//                       const SizedBox(height: 24),
//                       Wrap(
//                         alignment: WrapAlignment.center,
//                         spacing: 16,
//                         children: [
//                           if (_mode != 'signup' && _mode != 'edit')
//                             TextButton(
//                               onPressed: _loading ? null : () => _switchMode('signup'),
//                               child: const Text(
//                                 'Need an account? Sign Up',
//                                 style: TextStyle(
//                                   color: premiumPrimaryColor,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           if (_mode != 'login' && _mode != 'edit')
//                             TextButton(
//                               onPressed: _loading ? null : () => _switchMode('login'),
//                               child: const Text(
//                                 'Have an account? Login',
//                                 style: TextStyle(
//                                   color: premiumPrimaryColor,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           if (_mode != 'forgot' && _mode != 'edit')
//                             TextButton(
//                               onPressed: _loading ? null : () => _switchMode('forgot'),
//                               child: const Text(
//                                 'Forgot Password?',
//                                 style: TextStyle(
//                                   color: premiumPrimaryColor,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           if (_mode == 'edit')
//                             TextButton(
//                               onPressed: _loading ? null : () => context.pushReplacement('/account'),
//                               child: const Text(
//                                 'Back to Account',
//                                 style: TextStyle(
//                                   color: premiumPrimaryColor,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       Wrap(
//                         alignment: WrapAlignment.center,
//                         spacing: 16,
//                         children: [
//                           TextButton(
//                             onPressed: () => context.push('/policy'),
//                             child: const Text(
//                               'Policy',
//                               style: TextStyle(
//                                 color: premiumSecondaryTextColor,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () => context.push('/privacy'),
//                             child: const Text(
//                               'Privacy',
//                               style: TextStyle(
//                                 color: premiumSecondaryTextColor,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Center(
//                         child: TextButton(
//                           onPressed: () => context.pushReplacement('/'),
//                           child: const Text(
//                             'Back to Home',
//                             style: TextStyle(
//                               color: premiumPrimaryColor,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleSignup() async {
//     if (!_validName(_nameC.text)) {
//       _showError('Full name must be at least 2 characters and not "User"');
//       return;
//     }
//     if (!_validPhone(_phoneC.text)) {
//       _showError('Enter a valid +91 phone number');
//       return;
//     }
//     if (_passC.text.length < minPasswordLength) {
//       _showError('Password must be at least $minPasswordLength characters');
//       return;
//     }
//     if (_passC.text != _confirmPassC.text) {
//       _showError('Passwords do not match');
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       if (await _phoneExists(_phoneC.text)) {
//         _showError('You already have an account – please log in.');
//         _switchMode('login');
//         setState(() {
//           _otpSent = false;
//           _loading = false;
//         });
//         return;
//       }
//       _showSuccess('Sending OTP...');
//       await _sendOtp();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../state/app_state.dart';

// Premium color palette matching React
const premiumPrimaryColor = Color(0xFF1A237E); // Deep Indigo
const premiumAccentColor = Color(0xFFFFD740); // Gold
const premiumBackgroundColor = Color(0xFFF5F5F5); // Light Grey
const premiumTextColor = Color(0xFF212121); // Dark Grey
const premiumSecondaryTextColor = Color(0xFF757575); // Medium Grey

// Validation constants
final indianPhone = RegExp(r'^\+91\d{10}$');
const minNameLength = 2;
const minPasswordLength = 6;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _spb = Supabase.instance.client;

  // State
  String _mode = 'login'; // login | signup | forgot | edit
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController(text: '+91');
  final _passC = TextEditingController();
  final _confirmPassC = TextEditingController();
  final _otpC = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;
  int _cooldown = 0;
  bool _showPwd = false;
  bool _showConfirm = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Load .env file
    dotenv.load();
    // Watch Supabase session
    _fetchSession();
    _spb.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && _mode != 'edit') {
        context.pushReplacement('/');
      } else if (data.event == AuthChangeEvent.signedOut) {
        context.pushReplacement('/auth');
      }
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _confirmPassC.dispose();
    _otpC.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Helpers
  void _resetUI() {
    _otpC.clear();
    _otpSent = false;
    _otpVerified = false;
    _cooldown = 0;
    _cooldownTimer?.cancel();
  }

  void _switchMode(String m) {
    setState(() {
      _mode = m;
      _passC.clear();
      _confirmPassC.clear();
      _nameC.clear();
      _phoneC.text = '+91';
      _resetUI();
    });
  }

  bool _validPhone(String p) => indianPhone.hasMatch(p);

  bool _validName(String n) =>
      n.trim().isNotEmpty &&
      n.trim().toLowerCase() != 'user' &&
      n.trim().length >= minNameLength;

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFEF4444),
      textColor: Colors.white,
      fontSize: 16,
      timeInSecForIosWeb: 3,
    );
  }

  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF2ECC71),
      textColor: Colors.white,
      fontSize: 16,
      timeInSecForIosWeb: 3,
    );
  }

  // Session fetch
  Future<void> _fetchSession() async {
    try {
      final session = _spb.auth.currentSession;
      if (session != null) {
        if (_mode == 'edit') {
          final profile = await _spb
              .from('profiles')
              .select('full_name, phone_number')
              .eq('id', session.user.id)
              .single();
          setState(() {
            _nameC.text = profile['full_name'] ?? '';
            _phoneC.text = profile['phone_number'] ?? '+91';
          });
        } else {
          context.pushReplacement('/');
        }
      }
    } catch (e) {
      debugPrint('Session fetch error: $e');
      _showError('Failed to fetch session. Please try again.');
    }
  }

  // Cooldown timer
  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_cooldown == 0) {
          t.cancel();
        } else {
          _cooldown--;
        }
      });
    });
  }

  // DB Util
  Future<bool> _phoneExists(String ph) async {
    try {
      final response = await _spb
          .from('profiles')
          .select('id')
          .eq('phone_number', ph)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Phone check error: $e');
      throw Exception('Database error while checking phone');
    }
  }

  // OTP Handlers
  Future<void> _sendOtp() async {
    if (!_validPhone(_phoneC.text)) {
      _showError('Enter a valid +91 phone number (e.g., +919876543210)');
      return;
    }
    if (_cooldown > 0) {
      _showError('Please wait ${_cooldown}s to resend OTP');
      return;
    }
    if (_mode == 'signup') {
      if (!_validName(_nameC.text)) {
        _showError('Full name must be at least 2 characters and not "User"');
        return;
      }
      if (_passC.text.length < minPasswordLength) {
        _showError('Password must be at least $minPasswordLength characters');
        return;
      }
      if (_passC.text != _confirmPassC.text) {
        _showError('Passwords do not match');
        return;
      }
    }
    setState(() => _loading = true);
    try {
      await _spb.auth.signInWithOtp(
        phone: _phoneC.text,
        data: _mode == 'signup' ? {'full_name': _nameC.text.trim()} : null,
      );
      setState(() {
        _otpSent = true;
        _cooldown = 30;
      });
      _startCooldown();
      _showSuccess('OTP sent to your phone');
    } catch (e) {
      debugPrint('OTP send error: $e');
      if (e.toString().contains('already registered')) {
        _showError(
            'This phone number is already registered. Please log in or use a different number.');
      } else {
        _showError('Failed to send OTP');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpC.text.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await _spb.auth.verifyOTP(
        phone: _phoneC.text,
        token: _otpC.text,
        type: OtpType.sms,
      );
      setState(() {
        _otpVerified = true;
        _otpSent = false;
        _otpC.clear();
      });
      _showSuccess('Phone number verified');
      if (_mode == 'signup') {
        await _finishSignup(response.user);
      } else if (_mode == 'forgot') {
        // Wait for password reset
      } else {
        context.pushReplacement('/');
      }
    } catch (e) {
      debugPrint('OTP verify error: $e');
      _showError('Invalid OTP');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Signup Flow
  Future<void> _finishSignup(User? user) async {
    if (user == null) {
      _showError('User not found');
      return;
    }
    try {
      await _spb.from('profiles').upsert({
        'id': user.id,
        'full_name': _nameC.text.trim(),
        'phone_number': _phoneC.text,
        'is_seller': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await _spb.auth.updateUser(
        UserAttributes(password: _passC.text),
      );
      final profile = await _spb
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', user.id)
          .single();
      if (profile['full_name'] == null || profile['phone_number'] == null) {
        _showError('Please complete your profile details');
        _switchMode('edit');
      } else {
        _showSuccess('Signed up successfully');
        context.pushReplacement('/');
      }
    } catch (e) {
      debugPrint('Signup finish error: $e');
      _showError('Signup failed');
    }
  }

  // Login Handler using REST API
  Future<void> _handleLogin() async {
    if (!_validPhone(_phoneC.text)) {
      _showError('Enter a valid +91 phone number');
      return;
    }
    if (_passC.text.isEmpty) {
      _showError('Password is required');
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['SUPABASE_URL']}/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': dotenv.env['SUPABASE_ANON_KEY']!,
        },
        body: jsonEncode({
          'phone': _phoneC.text,
          'password': _passC.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final refreshToken = data['refresh_token'] as String;

        // Set Supabase session manually using refresh token
        await _spb.auth.setSession(refreshToken);

        // Update profile with phone number
        final user = await _spb.auth.getUser();
        await _spb.from('profiles').upsert({
          'id': user.user!.id,
          'phone_number': _phoneC.text,
          'updated_at': DateTime.now().toIso8601String(),
        });

        _showSuccess('Login successful');
        context.pushReplacement('/');
      } else {
        final error = jsonDecode(response.body)['error_description'] ?? 'Invalid credentials';
        _showError(error);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _showError('Login failed: Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Forgot Password & Reset
  Future<void> _forgotStart() async {
    if (!_validPhone(_phoneC.text)) {
      _showError('Enter a valid +91 phone number');
      return;
    }
    if (!await _phoneExists(_phoneC.text)) {
      _showError('No account found for this phone number');
      return;
    }
    await _sendOtp();
  }

  Future<void> _resetPw() async {
    if (!_otpVerified) {
      _showError('Please verify OTP first');
      return;
    }
    if (_passC.text != _confirmPassC.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passC.text.length < minPasswordLength) {
      _showError('Password must be at least $minPasswordLength characters');
      return;
    }
    setState(() => _loading = true);
    try {
      await _spb.auth.updateUser(
        UserAttributes(password: _passC.text),
      );
      final user = await _spb.auth.getUser();
      final profile = await _spb
          .from('profiles')
          .select('phone_number')
          .eq('id', user.user!.id)
          .single();
      if (profile['phone_number'] == null) {
        await _spb.from('profiles').upsert({
          'id': user.user!.id,
          'phone_number': _phoneC.text,
          'is_seller': false,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      _showSuccess('Password reset successful. Please log in.');
      _switchMode('login');
    } catch (e) {
      debugPrint('Password reset error: $e');
      _showError('Password reset failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Profile Update
  Future<void> _handleProfileUpdate() async {
    if (!_validName(_nameC.text)) {
      _showError('Full name must be at least 2 characters and not "User"');
      return;
    }
    if (!_validPhone(_phoneC.text)) {
      _showError('Enter a valid +91 phone number');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _spb.auth.getUser();
      await _spb.from('profiles').upsert({
        'id': user.user!.id,
        'full_name': _nameC.text.trim(),
        'phone_number': _phoneC.text,
        'is_seller': false,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _showSuccess('Profile updated successfully');
      context.pushReplacement('/');
    } catch (e) {
      debugPrint('Profile update error: $e');
      _showError('Failed to update profile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Google Sign-In
  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await _spb.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.markeet://login-callback/',
      );
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _showError('Google sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (context.watch<AppState>().session != null && _mode != 'edit') {
      context.pushReplacement('/account');
    }

    return Scaffold(
      backgroundColor: premiumBackgroundColor,
      appBar: AppBar(
        title: Text(
          _mode == 'signup'
              ? 'Sign Up'
              : _mode == 'forgot'
                  ? 'Reset Password'
                  : _mode == 'edit'
                      ? 'Update Profile'
                      : 'Login',
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mode == 'signup'
                            ? 'Create an Account'
                            : _mode == 'forgot'
                                ? 'Reset Your Password'
                                : _mode == 'edit'
                                    ? 'Update Your Profile'
                                    : 'Welcome Back',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: premiumTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == 'signup'
                            ? 'Join us today to start shopping!'
                            : _mode == 'forgot'
                                ? 'Reset your password to continue.'
                                : _mode == 'edit'
                                    ? 'Update your profile details.'
                                    : 'Login to continue shopping.',
                        style: const TextStyle(
                          color: premiumSecondaryTextColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _google,
                        icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                        label: Text(
                          _loading ? 'Please wait…' : 'Continue with Google',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: premiumPrimaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 16),
                      if (_mode == 'signup' || _mode == 'edit') ...[
                        TextFormField(
                          controller: _nameC,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            labelStyle:
                                const TextStyle(color: premiumSecondaryTextColor),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: premiumSecondaryTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: premiumPrimaryColor, width: 2),
                            ),
                            enabled: !_loading &&
                                (_mode == 'signup' && !_otpVerified),
                          ),
                          style: const TextStyle(color: premiumTextColor),
                          validator: (value) => _validName(value ?? '')
                              ? null
                              : 'Full name must be at least 2 characters and not "User"',
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _phoneC,
                        keyboardType: TextInputType.phone,
                        maxLength: 13,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '+919876543210',
                          labelStyle:
                              const TextStyle(color: premiumSecondaryTextColor),
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: premiumSecondaryTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: premiumPrimaryColor, width: 2),
                          ),
                          enabled: !_loading &&
                              (_mode != 'signup' || !_otpVerified) &&
                              (_mode != 'forgot' || !_otpSent),
                        ),
                        style: const TextStyle(color: premiumTextColor),
                        validator: (value) =>
                            _validPhone(value ?? '') ? null : 'Enter a valid +91 phone number',
                        onChanged: (value) {
                          if (!value.startsWith('+91')) {
                            _phoneC.text = '+91';
                            _phoneC.selection = TextSelection.fromPosition(
                                TextPosition(offset: _phoneC.text.length));
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if ((_mode == 'signup' || _mode == 'login') && !_otpSent) ...[
                        TextFormField(
                          controller: _passC,
                          obscureText: !_showPwd,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            labelStyle:
                                const TextStyle(color: premiumSecondaryTextColor),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: premiumSecondaryTextColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _showPwd ? Icons.visibility_off : Icons.visibility,
                                  color: premiumSecondaryTextColor),
                              onPressed: () => setState(() => _showPwd = !_showPwd),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: premiumPrimaryColor, width: 2),
                            ),
                            enabled: !_loading,
                          ),
                          style: const TextStyle(color: premiumTextColor),
                          validator: (value) => (value?.length ?? 0) >= minPasswordLength
                              ? null
                              : 'Password must be at least $minPasswordLength characters',
                        ),
                        const SizedBox(height: 16),
                        if (_mode == 'signup')
                          TextFormField(
                            controller: _confirmPassC,
                            obscureText: !_showConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password *',
                              labelStyle:
                                  const TextStyle(color: premiumSecondaryTextColor),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: premiumSecondaryTextColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showConfirm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: premiumSecondaryTextColor),
                                onPressed: () =>
                                    setState(() => _showConfirm = !_showConfirm),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: premiumPrimaryColor, width: 2),
                              ),
                              enabled: !_loading,
                            ),
                            style: const TextStyle(color: premiumTextColor),
                            validator: (value) =>
                                value == _passC.text ? null : 'Passwords do not match',
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (_otpSent && (!_otpVerified || _mode != 'forgot')) ...[
                        TextFormField(
                          controller: _otpC,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Enter OTP *',
                            labelStyle:
                                const TextStyle(color: premiumSecondaryTextColor),
                            prefixIcon: const Icon(Icons.sms_outlined,
                                color: premiumSecondaryTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: premiumPrimaryColor, width: 2),
                            ),
                            enabled: !_loading,
                          ),
                          style: const TextStyle(color: premiumTextColor),
                          validator: (value) =>
                              value?.isNotEmpty ?? false ? null : 'Enter the OTP',
                          onChanged: (value) {
                            _otpC.text = value.replaceAll(RegExp(r'[^0-9]'), '');
                            _otpC.selection = TextSelection.fromPosition(
                                TextPosition(offset: _otpC.text.length));
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _loading ? null : _verifyOtp,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: premiumPrimaryColor, width: 1.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _loading ? 'Verifying...' : 'Verify OTP',
                                  style: const TextStyle(
                                    color: premiumPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: _loading || _cooldown > 0 ? null : _sendOtp,
                              child: Text(
                                _cooldown > 0 ? 'Resend in $_cooldown s' : 'Resend OTP',
                                style: TextStyle(
                                  color: _cooldown > 0
                                      ? premiumSecondaryTextColor
                                      : premiumPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_otpSent || (_mode == 'forgot' && _otpVerified) || _mode == 'edit')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    if (_mode == 'signup') {
                                      if (_otpSent) {
                                        _verifyOtp();
                                      } else {
                                        _handleSignup();
                                      }
                                    } else if (_mode == 'forgot') {
                                      if (_otpVerified) {
                                        _resetPw();
                                      } else {
                                        _forgotStart();
                                      }
                                    } else if (_mode == 'edit') {
                                      _handleProfileUpdate();
                                    } else {
                                      _handleLogin();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: premiumPrimaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.2),
                            ),
                            child: Text(
                              _loading
                                  ? 'Processing...'
                                  : _mode == 'signup'
                                      ? 'Sign Up'
                                      : _mode == 'forgot'
                                          ? 'Save Password'
                                          : _mode == 'edit'
                                              ? 'Update Profile'
                                              : 'Login',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        children: [
                          if (_mode != 'signup' && _mode != 'edit')
                            TextButton(
                              onPressed: _loading ? null : () => _switchMode('signup'),
                              child: const Text(
                                'Need an account? Sign Up',
                                style: TextStyle(
                                  color: premiumPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          if (_mode != 'login' && _mode != 'edit')
                            TextButton(
                              onPressed: _loading ? null : () => _switchMode('login'),
                              child: const Text(
                                'Have an account? Login',
                                style: TextStyle(
                                  color: premiumPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          if (_mode != 'forgot' && _mode != 'edit')
                            TextButton(
                              onPressed: _loading ? null : () => _switchMode('forgot'),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: premiumPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          if (_mode == 'edit')
                            TextButton(
                              onPressed: _loading ? null : () => context.pushReplacement('/account'),
                              child: const Text(
                                'Back to Account',
                                style: TextStyle(
                                  color: premiumPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        children: [
                          TextButton(
                            onPressed: () => context.push('/policy'),
                            child: const Text(
                              'Policy',
                              style: TextStyle(
                                color: premiumSecondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/privacy'),
                            child: const Text(
                              'Privacy',
                              style: TextStyle(
                                color: premiumSecondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pushReplacement('/'),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              color: premiumPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_validName(_nameC.text)) {
      _showError('Full name must be at least 2 characters and not "User"');
      return;
    }
    if (!_validPhone(_phoneC.text)) {
      _showError('Enter a valid +91 phone number');
      return;
    }
    if (_passC.text.length < minPasswordLength) {
      _showError('Password must be at least $minPasswordLength characters');
      return;
    }
    if (_passC.text != _confirmPassC.text) {
      _showError('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      if (await _phoneExists(_phoneC.text)) {
        _showError('You already have an account – please log in.');
        _switchMode('login');
        setState(() {
          _otpSent = false;
          _loading = false;
        });
        return;
      }
      _showSuccess('Sending OTP...');
      await _sendOtp();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}