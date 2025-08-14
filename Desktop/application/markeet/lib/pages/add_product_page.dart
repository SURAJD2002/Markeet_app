// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import '../state/app_state.dart';
// import '../utils/supabase_utils.dart';

// class AddProductPage extends StatefulWidget {
//   const AddProductPage({super.key});
//   @override
//   State<AddProductPage> createState() => _AddProductPageState();
// }

// class _AddProductPageState extends State<AddProductPage> {
//   final _spb = Supabase.instance.client;
//   final _formKey = GlobalKey<FormState>();
//   bool _loading = false;
//   String? _error;
//   String _message = '';
//   bool _enableVariants = false;

//   // Form fields
//   String _title = '';
//   String _description = '';
//   double _price = 0.0;
//   double _commission = 0.0;
//   double _discount = 0.0;
//   int _stock = 0;
//   int? _categoryId;
//   List<XFile> _images = [];
//   List<Map<String, dynamic>> _specifications = [];
//   List<Map<String, dynamic>> _variants = [];

//   // UI state
//   List<Map<String, dynamic>> _categories = [];
//   double? _finalPrice;
//   List<String> _imagePreviews = [];
//   Map<int, List<String>> _variantPreviews = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchCategories();
//   }

//   Future<void> _fetchCategories() async {
//     try {
//       final response = await _spb
//           .from('categories')
//           .select('id, name, variant_attributes, specifications_fields')
//           .order('id', ascending: true);
//       setState(() {
//         _categories = response;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to load categories: $e';
//       });
//     }
//   }

//   Future<String?> _uploadImage(XFile file) async {
//     try {
//       final bytes = await file.readAsBytes();
//       final fileExt = file.path.split('.').last;
//       final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}.$fileExt';
//       await _spb.storage.from('product-images').uploadBinary(fileName, bytes);
//       final publicUrl = _spb.storage.from('product-images').getPublicUrl(fileName);
//       return publicUrl;
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to upload image: $e';
//       });
//       return null;
//     }
//   }

//   void _calculateFinalPrice() {
//     if (_price > 0) {
//       setState(() {
//         _finalPrice = _price - _discount;
//       });
//     } else {
//       setState(() {
//         _finalPrice = null;
//       });
//     }
//   }

//   Future<void> _pickImages() async {
//     final picker = ImagePicker();
//     final pickedFiles = await picker.pickMultiImage();
//     if (pickedFiles.isNotEmpty) {
//       setState(() {
//         _images = pickedFiles;
//         _imagePreviews = pickedFiles.map((file) => file.path).toList();
//       });
//     }
//   }

//   Future<void> _pickVariantImages(int index) async {
//     final picker = ImagePicker();
//     final pickedFiles = await picker.pickMultiImage();
//     if (pickedFiles.isNotEmpty) {
//       setState(() {
//         _variants[index]['images'] = pickedFiles;
//         _variantPreviews[index] = pickedFiles.map((file) => file.path).toList();
//       });
//     }
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() {
//       _loading = true;
//       _error = null;
//       _message = '';
//     });

//     try {
//       final session = context.read<AppState>().session;
//       if (session == null) {
//         setState(() {
//           _error = 'You must be logged in.';
//         });
//         return;
//       }
//       final sellerId = session.user.id;
//       final sellerLoc = context.read<AppState>().sellerLocation;
//       if (sellerLoc == null) {
//         setState(() {
//           _error = 'Please set your store location in the Seller Dashboard.';
//         });
//         context.push('/seller');
//         return;
//       }

//       // Upload images
//       final imageUrls = <String>[];
//       for (var file in _images) {
//         final url = await _uploadImage(file);
//         if (url != null) imageUrls.add(url);
//       }

//       // Prepare specifications
//       final specs = _specifications.fold<Map<String, String>>({}, (obj, spec) {
//         if (spec['key'].isNotEmpty && spec['value'].isNotEmpty) {
//           obj[spec['key']] = spec['value'];
//         }
//         return obj;
//       });

//       // Insert product
//       final productResponse = await _spb.from('products').insert({
//         'seller_id': sellerId,
//         'category_id': _categoryId,
//         'title': _title.trim(),
//         'description': _description,
//         'price': _price - _discount,
//         'original_price': _price,
//         'commission_amount': _commission,
//         'discount_amount': _discount,
//         'stock': _stock,
//         'images': imageUrls,
//         'latitude': sellerLoc['lat'],
//         'longitude': sellerLoc['lon'],
//         'is_approved': false,
//         'status': 'active',
//         'specifications': specs,
//       }).select('id').single();

//       final productId = productResponse['id'];

//       // Insert variants
//       if (_enableVariants && _variants.isNotEmpty) {
//         final selectedCategory = _categories.firstWhere((c) => c['id'] == _categoryId);
//         final variantAttributes = List<String>.from(selectedCategory['variant_attributes'] ?? []);

//         for (var variant in _variants) {
//           if (variant['price'] <= 0 || variant['stock'] < 0) {
//             throw Exception('Variant price and stock must be valid.');
//           }
//           final attributes = variantAttributes.isNotEmpty
//               ? {for (var attr in variantAttributes) attr: variant[attr] ?? ''}
//               : {'attribute1': variant['attribute1'] ?? ''};
//           if (!attributes.values.any((v) => v.isNotEmpty)) {
//             throw Exception('At least one variant attribute must be filled.');
//           }

//           final variantImageUrls = <String>[];
//           for (var file in variant['images'] ?? []) {
//             final url = await _uploadImage(file as XFile);
//             if (url != null) variantImageUrls.add(url);
//           }

//           await _spb.from('product_variants').insert({
//             'product_id': productId,
//             'attributes': attributes,
//             'price': variant['price'] - _discount,
//             'original_price': variant['price'],
//             'stock': variant['stock'],
//             'images': variantImageUrls,
//             'status': 'active',
//           });
//         }
//       }

//       setState(() {
//         _message = 'Product added successfully!';
//         _title = '';
//         _description = '';
//         _price = 0.0;
//         _commission = 0.0;
//         _discount = 0.0;
//         _stock = 0;
//         _categoryId = null;
//         _images = [];
//         _imagePreviews = [];
//         _specifications = [];
//         _variants = [];
//         _variantPreviews = {};
//         _enableVariants = false;
//       });
//       context.push('/seller');
//     } catch (e) {
//       setState(() {
//         _error = 'Error: $e';
//       });
//     } finally {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedCategory = _categories.firstWhere((c) => c['id'] == _categoryId, orElse: () => {});
//     final isMobileCategory = selectedCategory['name'] == 'Mobile Phones';
//     final variantAttributes = List<String>.from(selectedCategory['variant_attributes'] ?? []);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Add Product')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (_message.isNotEmpty) Text(_message, style: const TextStyle(color: Colors.green)),
//                     if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
//                     TextFormField(
//                       decoration: const InputDecoration(labelText: 'Product Name'),
//                       validator: (value) => value!.isEmpty ? 'Required' : null,
//                       onChanged: (value) => _title = value,
//                     ),
//                     TextFormField(
//                       decoration: const InputDecoration(labelText: 'Description'),
//                       maxLines: 4,
//                       validator: (value) => value!.isEmpty ? 'Required' : null,
//                       onChanged: (value) => _description = value,
//                     ),
//                     TextFormField(
//                       decoration: const InputDecoration(labelText: 'Price (₹)'),
//                       keyboardType: TextInputType.number,
//                       validator: (value) => double.tryParse(value!) == null || double.parse(value) < 0 ? 'Invalid price' : null,
//                       onChanged: (value) {
//                         _price = double.tryParse(value) ?? 0.0;
//                         _calculateFinalPrice();
//                       },
//                     ),
//                     TextFormField(
//                       decoration: const InputDecoration(labelText: 'Commission (₹)'),
//                       keyboardType: TextInputType.number,
//                       validator: (value) => double.tryParse(value!) == null || double.parse(value) < 0 ? 'Invalid commission' : null,
//                       onChanged: (value) => _commission = double.tryParse(value) ?? 0.0,
//                     ),
//                     TextFormField(
//                       decoration: const InputDecoration(labelText: 'Discount (₹)'),
//                       keyboardType: TextInputType.number,
//                       validator: (value) => double.tryParse(value!) == null || double.parse(value) < 0 ? 'Invalid discount' : null,
//                       onChanged: (value) {
//                         _discount = double.tryParse(value) ?? 0.0;
//                         _calculateFinalPrice();
//                       },
//                     ),
//                     if (_finalPrice != null)
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         child: Text('Final Price: ₹${_finalPrice!.toStringAsFixed(2)}'),
//                       ),
//                     TextFormField(
//                       decoration: const InputDecoration(labelText: 'Stock'),
//                       keyboardType: TextInputType.number,
//                       validator: (value) => int.tryParse(value!) == null || int.parse(value) < 0 ? 'Invalid stock' : null,
//                       onChanged: (value) => _stock = int.tryParse(value) ?? 0,
//                     ),
//                     DropdownButtonFormField<int>(
//                       decoration: const InputDecoration(labelText: 'Category'),
//                       value: _categoryId,
//                       items: _categories
//                           .map((c) => DropdownMenuItem<int>(
//                                 value: c['id'],
//                                 child: Text(c['name']),
//                               ))
//                           .toList(),
//                       validator: (value) => value == null ? 'Required' : null,
//                       onChanged: (value) {
//                         setState(() {
//                           _categoryId = value;
//                           _specifications = List<Map<String, dynamic>>.from(
//                               selectedCategory['specifications_fields'] ??
//                                   (isMobileCategory
//                                       ? [
//                                           {'key': 'RAM', 'value': ''},
//                                           {'key': 'Storage', 'value': ''},
//                                           {'key': 'Battery Capacity', 'value': ''},
//                                         ]
//                                       : []));
//                         });
//                       },
//                     ),
//                     ElevatedButton(
//                       onPressed: _pickImages,
//                       child: const Text('Pick Images'),
//                     ),
//                     if (_imagePreviews.isNotEmpty)
//                       Wrap(
//                         children: _imagePreviews
//                             .asMap()
//                             .entries
//                             .map((e) => Padding(
//                                   padding: const EdgeInsets.all(8),
//                                   child: Image.file(File(e.value), width: 100, height: 100),
//                                 ))
//                             .toList(),
//                       ),
//                     const SizedBox(height: 16),
//                     const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                     ..._specifications.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final spec = entry.value;
//                       return Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               initialValue: spec['key'],
//                               decoration: const InputDecoration(labelText: 'Key'),
//                               readOnly: spec['key'].isNotEmpty,
//                               onChanged: (value) => _specifications[index]['key'] = value,
//                             ),
//                           ),
//                           Expanded(
//                             child: TextFormField(
//                               initialValue: spec['value'],
//                               decoration: const InputDecoration(labelText: 'Value'),
//                               validator: (value) => value!.isEmpty ? 'Required' : null,
//                               onChanged: (value) => _specifications[index]['value'] = value,
//                             ),
//                           ),
//                           if (!isMobileCategory || spec['key'].isEmpty)
//                             IconButton(
//                               icon: const Icon(Icons.delete),
//                               onPressed: () => setState(() => _specifications.removeAt(index)),
//                             ),
//                         ],
//                       );
//                     }),
//                     TextButton(
//                       onPressed: () => setState(() => _specifications.add({'key': '', 'value': ''})),
//                       child: const Text('Add Specification'),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         const Text('Variants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         Switch(
//                           value: _enableVariants,
//                           onChanged: (value) => setState(() => _enableVariants = value),
//                         ),
//                       ],
//                     ),
//                     if (_enableVariants) ...[
//                       ..._variants.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final variant = entry.value;
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (variantAttributes.isNotEmpty)
//                               ...variantAttributes.map((attr) => TextFormField(
//                                     decoration: InputDecoration(labelText: attr),
//                                     validator: (value) => value!.isEmpty ? 'Required' : null,
//                                     onChanged: (value) => variant[attr] = value,
//                                   ))
//                             else
//                               TextFormField(
//                                 decoration: const InputDecoration(labelText: 'Attribute 1'),
//                                 validator: (value) => value!.isEmpty ? 'Required' : null,
//                                 onChanged: (value) => variant['attribute1'] = value,
//                               ),
//                             TextFormField(
//                               decoration: const InputDecoration(labelText: 'Variant Price (₹)'),
//                               keyboardType: TextInputType.number,
//                               validator: (value) =>
//                                   double.tryParse(value!) == null || double.parse(value) <= 0
//                                       ? 'Invalid price'
//                                       : null,
//                               onChanged: (value) => variant['price'] = double.tryParse(value) ?? 0.0,
//                             ),
//                             TextFormField(
//                               decoration: const InputDecoration(labelText: 'Variant Stock'),
//                               keyboardType: TextInputType.number,
//                               validator: (value) =>
//                                   int.tryParse(value!) == null || int.parse(value) < 0 ? 'Invalid stock' : null,
//                               onChanged: (value) => variant['stock'] = int.tryParse(value) ?? 0,
//                             ),
//                             ElevatedButton(
//                               onPressed: () => _pickVariantImages(index),
//                               child: const Text('Pick Variant Images'),
//                             ),
//                             if (_variantPreviews[index] != null)
//                               Wrap(
//                                 children: _variantPreviews[index]!
//                                     .map((path) => Padding(
//                                           padding: const EdgeInsets.all(8),
//                                           child: Image.file(File(path), width: 100, height: 100),
//                                         ))
//                                     .toList(),
//                               ),
//                             TextButton(
//                               onPressed: () => setState(() => _variants.removeAt(index)),
//                               child: const Text('Remove Variant'),
//                             ),
//                           ],
//                         );
//                       }),
//                       TextButton(
//                         onPressed: () => setState(() => _variants.add({
//                               'price': 0.0,
//                               'stock': 0,
//                               'images': [],
//                               ...{for (var attr in variantAttributes) attr: ''},
//                               'attribute1': '',
//                             })),
//                         child: const Text('Add Variant'),
//                       ),
//                     ],
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         ElevatedButton(
//                           onPressed: _loading ? null : _submit,
//                           child: Text(_loading ? 'Saving...' : 'Save'),
//                         ),
//                         const SizedBox(width: 16),
//                         TextButton(
//                           onPressed: _loading ? null : () => context.push('/seller'),
//                           child: const Text('Cancel'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../utils/supabase_utils.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _spb = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  String _message = '';
  bool _enableVariants = false;

  // Form fields
  String _title = '';
  String _description = '';
  double _price = 0.0;
  double _commission = 0.0;
  double _discount = 0.0;
  int _stock = 0;
  int? _categoryId;
  List<XFile> _images = [];
  List<Map<String, dynamic>> _specifications = [];
  List<Map<String, dynamic>> _variants = [];

  // UI state
  List<Map<String, dynamic>> _categories = [];
  double? _finalPrice;
  List<String> _imagePreviews = [];
  Map<int, List<String>> _variantPreviews = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _spb
          .from('categories')
          .select('id, name, variant_attributes, specifications_fields')
          .order('id', ascending: true);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load categories: $e';
      });
    }
  }

  Future<String> _uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}.$fileExt';
      await _spb.storage.from('product-images').uploadBinary(fileName, bytes);
      final publicUrl = _spb.storage.from('product-images').getPublicUrl(fileName);
      if (publicUrl.isEmpty) {
        throw Exception('Failed to get public URL for image: $fileName');
      }
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void _calculateFinalPrice() {
    if (_price > 0) {
      final calculatedPrice = _price - _discount;
      setState(() {
        _finalPrice = calculatedPrice >= 0 ? calculatedPrice : 0;
      });
    } else {
      setState(() {
        _finalPrice = null;
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles;
        _imagePreviews = pickedFiles.map((file) => file.path).toList();
      });
    }
  }

  Future<void> _pickVariantImages(int index) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _variants[index]['images'] = pickedFiles;
        _variantPreviews[index] = pickedFiles.map((file) => file.path).toList();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = '';
    });

    try {
      final session = context.read<AppState>().session;
      if (session == null) {
        throw Exception('You must be logged in.');
      }
      final sellerId = session.user.id;
      final sellerLoc = context.read<AppState>().sellerLocation;
      if (sellerLoc == null) {
        throw Exception('Please set your store location in the Seller Dashboard.');
      }

      // Upload product images
      final imageUrls = <String>[];
      for (var file in _images) {
        final url = await _uploadImage(file);
        imageUrls.add(url);
      }

      // Prepare specifications
      final specs = _specifications.fold<Map<String, String>>({}, (obj, spec) {
        if (spec['key'].isNotEmpty && spec['value'].isNotEmpty) {
          obj[spec['key']] = spec['value'];
        }
        return obj;
      });

      // Insert product
      final productResponse = await retry(() => _spb.from('products').insert({
            'seller_id': sellerId,
            'category_id': _categoryId,
            'title': _title.trim(),
            'description': _description,
            'price': _price - _discount,
            'original_price': _price,
            'commission_amount': _commission,
            'discount_amount': _discount,
            'stock': _stock,
            'images': imageUrls,
            'latitude': sellerLoc['lat'],
            'longitude': sellerLoc['lon'],
            'is_approved': false,
            'status': 'active',
            'specifications': specs,
          }).select('id').single());

      final productId = productResponse['id'];

      // Insert variants
      if (_enableVariants && _variants.isNotEmpty) {
        final selectedCategory = _categories.firstWhere((c) => c['id'] == _categoryId, orElse: () => {});
        final variantAttributes = List<String>.from(selectedCategory['variant_attributes'] ?? []);

        for (var variant in _variants) {
          if (variant['price'] <= 0 || variant['stock'] < 0) {
            throw Exception('Variant price must be greater than 0 and stock must be non-negative.');
          }
          final attributes = variantAttributes.isNotEmpty
              ? {for (var attr in variantAttributes) attr: variant[attr]?.toString() ?? ''}
              : {'attribute1': variant['attribute1']?.toString() ?? ''};
          if (!attributes.values.any((v) => v.isNotEmpty)) {
            throw Exception('At least one variant attribute must be filled.');
          }

          final variantImages = variant['images'] as List<XFile>? ?? [];
          final variantImageUrls = <String>[];
          for (var file in variantImages) {
            final url = await _uploadImage(file);
            variantImageUrls.add(url);
          }

          await retry(() => _spb.from('product_variants').insert({
                'product_id': productId,
                'attributes': attributes,
                'price': variant['price'] - _discount,
                'original_price': variant['price'],
                'stock': variant['stock'],
                'images': variantImageUrls,
                'status': 'active',
              }));
        }
      }

      setState(() {
        _message = 'Product added successfully! Awaiting approval.';
        _title = '';
        _description = '';
        _price = 0.0;
        _commission = 0.0;
        _discount = 0.0;
        _stock = 0;
        _categoryId = null;
        _images = [];
        _imagePreviews = [];
        _specifications = [];
        _variants = [];
        _variantPreviews = {};
        _enableVariants = false;
        _finalPrice = null;
        _formKey.currentState!.reset();
      });
      Future.delayed(const Duration(seconds: 2), () => context.push('/seller'));
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categoryId != null
        ? _categories.firstWhere((c) => c['id'] == _categoryId, orElse: () => {})
        : {};
    final isMobileCategory = selectedCategory['name'] == 'Mobile Phones';
    final variantAttributes = List<String>.from(selectedCategory['variant_attributes'] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_message, style: const TextStyle(color: Colors.green)),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                      onChanged: (value) => _title = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                      onChanged: (value) => _description = value,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = double.tryParse(value!);
                        if (parsed == null || parsed <= 0) return 'Must be greater than 0';
                        return null;
                      },
                      onChanged: (value) {
                        _price = double.tryParse(value) ?? 0.0;
                        _calculateFinalPrice();
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Commission (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = double.tryParse(value!);
                        if (parsed == null || parsed < 0) return 'Must be non-negative';
                        return null;
                      },
                      onChanged: (value) => _commission = double.tryParse(value) ?? 0.0,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Discount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = double.tryParse(value!);
                        if (parsed == null || parsed < 0) return 'Must be non-negative';
                        if (parsed != null && parsed > _price) return 'Cannot exceed price';
                        return null;
                      },
                      onChanged: (value) {
                        _discount = double.tryParse(value) ?? 0.0;
                        _calculateFinalPrice();
                      },
                    ),
                    if (_finalPrice != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Final Price: ₹${_finalPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value!);
                        if (parsed == null || parsed < 0) return 'Must be non-negative';
                        return null;
                      },
                      onChanged: (value) => _stock = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _categoryId,
                      items: _categories
                          .map((c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['name'] ?? 'Unnamed Category'),
                              ))
                          .toList(),
                      validator: (value) => value == null ? 'Required' : null,
                      onChanged: (value) {
                        setState(() {
                          _categoryId = value;
                          final newSelectedCategory = _categories.firstWhere(
                            (c) => c['id'] == _categoryId,
                            orElse: () => {},
                          );
                          _specifications = List<Map<String, dynamic>>.from(
                            newSelectedCategory['specifications_fields'] ??
                                (newSelectedCategory['name'] == 'Mobile Phones'
                                    ? [
                                        {'key': 'RAM', 'value': ''},
                                        {'key': 'Storage', 'value': ''},
                                        {'key': 'Battery Capacity', 'value': ''},
                                      ]
                                    : []),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_imagePreviews.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _imagePreviews
                              .asMap()
                              .entries
                              .map((e) => Stack(
                                    children: [
                                      Image.file(
                                        File(e.value),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => setState(() {
                                            _images.removeAt(e.key);
                                            _imagePreviews.removeAt(e.key);
                                          }),
                                        ),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._specifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final spec = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: spec['key'],
                                decoration: const InputDecoration(
                                  labelText: 'Key',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: spec['key'].isNotEmpty,
                                onChanged: (value) => setState(() => _specifications[index]['key'] = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: spec['value'],
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value!.trim().isEmpty && spec['key'].isNotEmpty ? 'Required' : null,
                                onChanged: (value) => setState(() => _specifications[index]['value'] = value),
                              ),
                            ),
                            if (!isMobileCategory || spec['key'].isEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _specifications.removeAt(index)),
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => setState(() => _specifications.add({'key': '', 'value': ''})),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Specification'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Variants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Switch(
                          value: _enableVariants,
                          onChanged: (value) => setState(() => _enableVariants = value),
                        ),
                      ],
                    ),
                    if (_enableVariants) ...[
                      ..._variants.asMap().entries.map((entry) {
                        final index = entry.key;
                        final variant = entry.value;
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (variantAttributes.isNotEmpty)
                                  ...variantAttributes.map((attr) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            labelText: attr,
                                            border: const OutlineInputBorder(),
                                          ),
                                          validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                                          onChanged: (value) => setState(() => variant[attr] = value),
                                        ),
                                      ))
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Attribute 1',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                                      onChanged: (value) => setState(() => variant['attribute1'] = value),
                                    ),
                                  ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Variant Price (₹)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final parsed = double.tryParse(value!);
                                    if (parsed == null || parsed <= 0) return 'Must be greater than 0';
                                    return null;
                                  },
                                  onChanged: (value) =>
                                      setState(() => variant['price'] = double.tryParse(value) ?? 0.0),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Variant Stock',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final parsed = int.tryParse(value!);
                                    if (parsed == null || parsed < 0) return 'Must be non-negative';
                                    return null;
                                  },
                                  onChanged: (value) => setState(() => variant['stock'] = int.tryParse(value) ?? 0),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _pickVariantImages(index),
                                  icon: const Icon(Icons.image),
                                  label: const Text('Pick Variant Images'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                if (_variantPreviews[index] != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _variantPreviews[index]!
                                          .asMap()
                                          .entries
                                          .map((e) => Stack(
                                                children: [
                                                  Image.file(
                                                    File(e.value),
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                      onPressed: () => setState(() {
                                                        final variantImages =
                                                            variant['images'] as List<XFile>;
                                                        variantImages.removeAt(e.key);
                                                        _variantPreviews[index]!.removeAt(e.key);
                                                      }),
                                                    ),
                                                  ),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _variants.removeAt(index);
                                    _variantPreviews.remove(index);
                                  }),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Remove Variant'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setState(() => _variants.add({
                              'price': 0.0,
                              'stock': 0,
                              'images': <XFile>[],
                              ...{for (var attr in variantAttributes) attr: ''},
                              'attribute1': '',
                            })),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_loading ? 'Saving...' : 'Save'),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _loading ? null : () => context.push('/seller'),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}