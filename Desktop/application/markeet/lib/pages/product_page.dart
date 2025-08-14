import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

// Constants
const String defaultImage = 'https://dummyimage.com/300';
const String currencyFormat = 'en_IN';
const String cacheKeyPrefix = 'relatedCache';
const double kRadiusKm = 50.0;
const Color premiumPrimaryColor = Color(0xFF3B82F6);
const Color premiumAccentColor = Color(0xFFFFD700);
const Color premiumBackgroundColor = Color(0xFFF5F5F5);
const Color premiumCardColor = Colors.white;
const Color premiumTextColor = Color(0xFF212121);
const Color premiumSecondaryTextColor = Color(0xFF757575);
const Color premiumErrorColor = Color(0xFFEF4444);
const Color premiumSuccessColor = Color(0xFF10B981);
const Color premiumWarningColor = Color(0xFFF59E0B);

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.id});
  final String id;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _spb = Supabase.instance.client;
  
  // Data
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _relatedProducts = [];
  int _selectedVariantIndex = 0;
  
  // UI State
  bool _loading = true;
  bool _isRelatedLoading = false;
  String? _error;
  bool _isRestricted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ─── Helper Methods ───────────────────────────────────────────────────────
  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: currencyFormat,
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

  double _calculateDistance(Map<String, double>? userLoc, Map<String, dynamic> sellerLoc) {
    if (userLoc == null ||
        userLoc['lat'] == null || 
        userLoc['lon'] == null ||
        sellerLoc['latitude'] == null ||
        sellerLoc['longitude'] == null ||
        sellerLoc['latitude'] == 0 ||
        sellerLoc['longitude'] == 0) {
      return -1;
    }
    
    const R = 6371; // Earth's radius in km
    final dLat = ((sellerLoc['latitude'] - userLoc['lat']!) * math.pi) / 180;
    final dLon = ((sellerLoc['longitude'] - userLoc['lon']!) * math.pi) / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(userLoc['lat']! * (math.pi / 180)) *
            math.cos(sellerLoc['latitude'] * (math.pi / 180)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
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

  Map<String, dynamic>? get _activeVariant {
    if (_variants.isEmpty || _selectedVariantIndex < 0 || _selectedVariantIndex >= _variants.length) {
      return null;
    }
    return _variants[_selectedVariantIndex];
  }

  List<String> get _displayedImages {
    final activeVariant = _activeVariant;
    final productImages = List<String>.from(_product?['images'] ?? []);
    final variantImages = List<String>.from(activeVariant?['images'] ?? []);
    final mergedImages = [...productImages, ...variantImages].toSet().toList();
    return mergedImages.isNotEmpty ? mergedImages : [defaultImage];
  }

  bool get _isOutOfStock {
    final activeVariant = _activeVariant;
    final stock = activeVariant?['stock'] ?? _product?['stock'] ?? 0;
    return stock <= 0;
  }

  bool get _isLowStock {
    final activeVariant = _activeVariant;
    final stock = activeVariant?['stock'] ?? _product?['stock'] ?? 0;
    return stock > 0 && stock < 5;
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final totalRating = _reviews.fold<double>(0, (sum, review) => sum + (review['rating'] ?? 0));
    return totalRating / _reviews.length;
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: premiumAccentColor,
          size: 16,
        );
      }),
    );
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    if (!(await _checkNetworkStatus())) {
      setState(() {
        _error = 'No internet connection.';
        _loading = false;
      });
      return;
    }

    final app = context.read<AppState>();
    if (app.buyerLocation == null) {
        Fluttertoast.showToast(
          msg: 'No buyer location available. Please allow location access.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
        setState(() {
          _error = 'No buyer location available.';
          _loading = false;
        });
        return;
      }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final productData = await retry(() => _spb
          .from('products')
          .select('''
            *,
            sellers(id, store_name, latitude, longitude),
            categories(id, name, is_restricted, max_delivery_radius_km)
          ''')
          .eq('id', int.parse(widget.id))
          .eq('is_approved', true)
          .eq('status', 'active')
          .maybeSingle());

      if (productData == null) {
        setState(() => _error = 'Product not found.');
        return;
      }

      // Validate delivery radius
      final distance = _calculateDistance(app.buyerLocation, {
        'latitude': productData['sellers']?['latitude'],
        'longitude': productData['sellers']?['longitude'],
      });
      
      final effectiveRadius = productData['delivery_radius_km'] ?? 
                             productData['categories']?['max_delivery_radius_km'] ?? 
                             kRadiusKm;
      
      if (distance == -1 || distance > effectiveRadius) {
        Fluttertoast.showToast(
          msg: 'Product is not available in your area.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
        setState(() => _error = 'Product is not available in your area.');
        context.go('/products');
        return;
      }

      // Check for restricted categories
      if (productData['categories']?['is_restricted'] == true) {
        Fluttertoast.showToast(
          msg: 'Please access this restricted category via the Categories page.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
        context.go('/categories');
        return;
      }

      final normalizedProduct = {
        ...productData,
        'price': double.tryParse(productData['price'].toString()) ?? 0,
        'original_price': double.tryParse(productData['original_price']?.toString() ?? '0') ?? null,
        'discount_amount': double.tryParse(productData['discount_amount']?.toString() ?? '0') ?? 0,
        'category_name': productData['categories']?['name'] ?? 'Unknown Category',
        'category_id': productData['categories']?['id'],
        'distance': distance,
        'distance_text': _formatDistance(distance),
      };

      final variantsData = await retry(() => _spb
          .from('product_variants')
          .select('id, product_id, price, original_price, discount_amount, stock, attributes, images')
          .eq('product_id', int.parse(widget.id))
          .eq('status', 'active'));

      final validVariants = (variantsData ?? []).map((variant) {
        return {
          ...variant,
          'price': double.tryParse(variant['price'].toString()) ?? 0,
          'original_price': double.tryParse(variant['original_price']?.toString() ?? '0') ?? null,
          'discount_amount': double.tryParse(variant['discount_amount']?.toString() ?? '0') ?? 0,
          'stock': variant['stock'] ?? 0,
          'images': (variant['images'] != null && variant['images'].isNotEmpty) ? variant['images'] : productData['images'],
        };
      }).where((variant) {
        final attributes = variant['attributes'] as Map<String, dynamic>? ?? {};
        return attributes.values.any((val) => val != null && val.toString().trim().isNotEmpty);
      }).toList();

      final reviewsData = await _fetchReviews(int.parse(widget.id));
      await _fetchRelatedProducts(normalizedProduct);

      if (mounted) {
        setState(() {
          _product = normalizedProduct;
          _variants = validVariants;
          _selectedVariantIndex = validVariants.isNotEmpty ? 0 : -1;
          _reviews = reviewsData;
          _isRestricted = productData['categories']?['is_restricted'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load product: $e');
        Fluttertoast.showToast(
          msg: 'Failed to load product. Please try again.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReviews(int productId) async {
    try {
      final reviewsData = await retry(() => _spb
          .from('reviews')
          .select('''
            id, rating, review_text, reply_text, created_at,
            profiles!reviews_reviewer_id_fkey(full_name)
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false));
      return reviewsData.map((review) {
        return {
          ...review,
          'reviewer_name': review['profiles']?['full_name'] ?? 'Anonymous',
        };
      }).toList();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load reviews.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
      return [];
    }
  }

  Future<void> _fetchRelatedProducts(Map<String, dynamic> product, {int retryCount = 0}) async {
    if (product['category_id'] == null) {
      setState(() {
        _relatedProducts = [];
        _isRelatedLoading = false;
      });
      return;
    }

    setState(() => _isRelatedLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$cacheKeyPrefix-${product['id']}-${product['category_id']}';
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      setState(() {
        _relatedProducts = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
        _isRelatedLoading = false;
      });
      return;
    }

    try {
      final relatedData = await retry(() => _spb.rpc(
            'get_related_products',
            params: {
              'p_product_id': int.parse(product['id'].toString()),
            'p_limit': 4,
            },
          ));

      final normalized = (relatedData ?? [])
          .map((item) => {
          ...item,
          'price': double.tryParse(item['price'].toString()) ?? 0,
          'category_name': item['category_name'] ?? 'Unknown Category',
              })
          .where((item) => item['id'] != product['id'])
          .toList();

      prefs.setString(cacheKey, jsonEncode(normalized));
      setState(() {
        _relatedProducts = normalized;
        _isRelatedLoading = false;
      });
    } catch (e) {
      if (retryCount < 2) {
        Future.delayed(Duration(seconds: 1), () => _fetchRelatedProducts(product, retryCount: retryCount + 1));
        return;
      }
      setState(() {
        _relatedProducts = [];
        _isRelatedLoading = false;
      });
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Unable to load related products.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    }
  }

  Future<void> _addToCart({bool goToCart = false}) async {
    if (_product == null) {
      Fluttertoast.showToast(
        msg: 'Product not available.',
        backgroundColor: premiumErrorColor,
        textColor: Colors.white,
        fontSize: 15,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      return;
    }

    if (_isOutOfStock) {
      Fluttertoast.showToast(
        msg: 'This item is out of stock.',
        backgroundColor: premiumErrorColor,
        textColor: Colors.white,
        fontSize: 15,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      return;
    }

    if (_isRestricted) {
      Fluttertoast.showToast(
        msg: 'Please access this restricted category via the Categories page.',
        backgroundColor: premiumErrorColor,
        textColor: Colors.white,
        fontSize: 15,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      context.go('/categories');
      return;
    }

    final app = context.read<AppState>();
    if (app.session == null) {
      Fluttertoast.showToast(
        msg: goToCart ? 'Please log in to proceed to checkout.' : 'Please log in to add items to your cart.',
        backgroundColor: premiumErrorColor,
        textColor: Colors.white,
        fontSize: 15,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      context.go('/auth');
      return;
    }

    if (!(await _checkNetworkStatus())) return;

    try {
      final activeVariant = _activeVariant;
      final variantId = activeVariant?['id'];
      final price = activeVariant?['price'] ?? _product!['price'];
      final stock = activeVariant?['stock'] ?? _product!['stock'] ?? 0;

      // Check if item already exists in cart
      final userId = app.session!.user.id;
      var query = _spb
          .from('cart')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_id', int.parse(widget.id));

      if (variantId != null) {
        query = query.eq('variant_id', variantId);
      }

      final existingCartItem = await query.maybeSingle();
      final newQuantity = (existingCartItem?['quantity'] ?? 0) + 1;

      if (newQuantity > stock) {
        Fluttertoast.showToast(
          msg: 'Exceeds available stock.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
        return;
      }

      if (existingCartItem != null) {
        // Update existing cart item
        await retry(() => _spb
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingCartItem['id']));
      } else {
        // Add new cart item
        await retry(() => _spb.from('cart').insert({
              'user_id': userId,
              'product_id': int.parse(widget.id),
              'variant_id': variantId,
              'quantity': 1,
              'price': price,
              'title': _product!['title'] ?? _product!['name'] ?? 'Product',
            }));
      }

      await app.refreshCartCount();

      Fluttertoast.showToast(
        msg: '${_product!['title'] ?? _product!['name']} added to cart!',
        backgroundColor: premiumSuccessColor,
        textColor: Colors.white,
        fontSize: 15,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );

      if (goToCart) {
        Fluttertoast.showToast(
          msg: 'Redirecting to cart...',
          backgroundColor: premiumPrimaryColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
        );
        Future.delayed(const Duration(seconds: 2), () => context.go('/cart'));
      }
    } catch (e) {
        Fluttertoast.showToast(
        msg: 'Failed to add to cart. Please try again.',
          backgroundColor: premiumErrorColor,
          textColor: Colors.white,
          fontSize: 15,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: premiumBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: premiumPrimaryColor)),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: premiumBackgroundColor,
        appBar: AppBar(
          title: const Text('Product'),
          backgroundColor: premiumPrimaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/products'),
          ),
        ),
        body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error ?? 'Product not found.',
                      style: GoogleFonts.roboto(
                        color: premiumTextColor,
                  fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final productName = _product!['title'] ?? _product!['name'] ?? 'Product';
    final variantAttributes = _variants
        .asMap()
        .entries
        .map((entry) => {
              'id': entry.value['id'],
              'index': entry.key,
              'attributes': (entry.value['attributes'] as Map<String, dynamic>?)
                      ?.entries
                      .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
                  .map((e) => '${e.key}: ${e.value}')
                      .join(', ') ??
                  '',
            })
        .where((v) => v['attributes'].isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: premiumBackgroundColor,
      appBar: AppBar(
        title: Text(
          productName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: premiumPrimaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: premiumCardColor,
              child: CarouselSlider(
                items: _displayedImages.map((image) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 260,
                    placeholder: (context, url) => Container(
                      height: 260,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Image.network(
                      defaultImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 260,
                    ),
                  ),
                )).toList(),
                options: CarouselOptions(
                  height: 260,
                  viewportFraction: 1,
                  enableInfiniteScroll: _displayedImages.length > 1,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                ),
              ),
            ),
                  const SizedBox(height: 16),
            
                  // Product Details
                            Text(
                              productName,
                              style: GoogleFonts.roboto(
                                color: premiumTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
            
            // Seller Info
            Text(
              'Seller: ${_product!['sellers']?['store_name'] ?? 'Unknown Seller'}',
                                style: GoogleFonts.roboto(
                                  color: premiumPrimaryColor,
                                  fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            // Distance Info
            if (_product!['distance'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: premiumSuccessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: premiumSuccessColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: premiumSuccessColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _product!['distance_text'] ?? 'Distance available',
                      style: GoogleFonts.roboto(
                        color: premiumSuccessColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                              ),
                            ),
                            const SizedBox(height: 8),
            ],
            
            // Price
                            Row(
                              children: [
                                Text(
                  _formatCurrency(_product!['price']),
                                  style: GoogleFonts.roboto(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                if (_isOutOfStock)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                        color: premiumErrorColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Out of Stock',
                                        style: GoogleFonts.roboto(
                                          color: premiumErrorColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_isLowStock)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      'Hurry! Only ${_activeVariant?['stock'] ?? _product?['stock']} left in stock.',
                                      style: GoogleFonts.roboto(
                                        color: premiumErrorColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
            
            // Original Price and Discount
            if (_product!['original_price'] != null || _product!['discount_amount'] > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (_product!['original_price'] != null)
                                        Text(
                                          _formatCurrency(_product!['original_price']),
                                          style: GoogleFonts.roboto(
                                            color: premiumSecondaryTextColor,
                                            fontSize: 16,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      if (_product!['discount_amount'] > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            'Save ${_formatCurrency(_product!['discount_amount'])}',
                                            style: GoogleFonts.roboto(
                                              color: Colors.green,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
            
                                  const SizedBox(height: 16),
            
            // Variants
            if (variantAttributes.isNotEmpty) ...[
                                  Text(
                                    'Select Variant',
                                    style: GoogleFonts.roboto(
                                      color: premiumTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: variantAttributes.map((v) {
                                      return ChoiceChip(
                                        label: Text(
                                          v['attributes'],
                                          style: GoogleFonts.roboto(
                        color: _selectedVariantIndex == v['index'] ? Colors.white : premiumTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                    selected: _selectedVariantIndex == v['index'],
                                        onSelected: (selected) {
                      if (selected) setState(() => _selectedVariantIndex = v['index']);
                                        },
                                        selectedColor: premiumPrimaryColor,
                                        backgroundColor: premiumCardColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                        color: _selectedVariantIndex == v['index'] ? premiumPrimaryColor : premiumSecondaryTextColor,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
            ],
            
            // Description
            if (_product!['description'] != null && (_product!['description'] as String).isNotEmpty) ...[
                                  Text(
                                    'Product Highlights',
                                    style: GoogleFonts.roboto(
                                      color: premiumTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: (_product!['description'] as String)
                                        .split(';')
                                        .where((point) => point.trim().isNotEmpty)
                                        .map((point) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                '• ${point.trim()}',
                                                style: GoogleFonts.roboto(
                                                  color: premiumTextColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 16),
            ],
            
            // Reviews
            if (_reviews.isNotEmpty) ...[
                                  Text(
                                    'Ratings & Reviews',
                                    style: GoogleFonts.roboto(
                                      color: premiumTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildStarRating(_averageRating),
                  const SizedBox(width: 8),
                  Text(
                    '${_averageRating.toStringAsFixed(1)}',
                    style: GoogleFonts.roboto(
                      color: premiumTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'})',
                                        style: GoogleFonts.roboto(
                                          color: premiumSecondaryTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
              ..._reviews.map((review) => Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          color: premiumCardColor,
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      review['reviewer_name'],
                                                      style: GoogleFonts.roboto(
                                                        color: premiumTextColor,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildStarRating(review['rating']?.toDouble() ?? 0),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  review['review_text'],
                                                  style: GoogleFonts.roboto(
                                                    color: premiumTextColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (review['reply_text'] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      'Seller Reply: ${review['reply_text']}',
                                                      style: GoogleFonts.roboto(
                                                        color: premiumSecondaryTextColor,
                                                        fontSize: 14,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 8),
                                                Text(
                            DateFormat.yMMMMd().format(DateTime.parse(review['created_at'])),
                                                  style: GoogleFonts.roboto(
                                                    color: premiumSecondaryTextColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                  )),
                            const SizedBox(height: 24),
            ],
            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                    onPressed: _isOutOfStock ? null : () => _addToCart(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: premiumPrimaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 4,
                                    ),
                                    child: Text(
                      _isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                    onPressed: _isOutOfStock ? null : () => _addToCart(goToCart: true),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: premiumPrimaryColor, width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Text(
                                      'Buy Now',
                                      style: GoogleFonts.roboto(
                                        color: premiumPrimaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
      ),
    );
  }
}