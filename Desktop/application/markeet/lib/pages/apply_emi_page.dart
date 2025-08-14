import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/app_state.dart';
import 'dart:math' as math;

class ApplyEMIPage extends StatefulWidget {
  final String productId;
  final String productName;
  final double productPrice;
  final String sellerId;

  const ApplyEMIPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.sellerId,
  });

  @override
  State<ApplyEMIPage> createState() => _ApplyEMIPageState();
}

class _ApplyEMIPageState extends State<ApplyEMIPage> {
  final _spb = Supabase.instance.client;
  Session? _session;
  Map<String, double>? _buyerLoc;
  Map<String, dynamic>? _sellerDetails;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _fullNameC = TextEditingController();
  final _mobileNumberC = TextEditingController();
  final _aadhaarLastFourC = TextEditingController();
  String _monthlyIncomeRange = '₹20,000-30,000';
  String _preferredEMIDuration = '6 months';
  final _addressC = TextEditingController();
  final _cityC = TextEditingController();
  final _postalCodeC = TextEditingController();
  String _shippingAddress = '';

  // UI state
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _submissionSuccess = false;
  Map<String, dynamic> _emiDetails = {};
  int? _newOrderId;

  // Validation errors
  final Map<String, String> _formErrors = {
    'fullName': '',
    'mobileNumber': '',
    'aadhaarLastFour': '',
    'monthlyIncomeRange': '',
    'preferredEMIDuration': '',
    'address': '',
    'city': '',
    'postalCode': '',
  };

  /* ─── Helpers ─────────────────────────────────────────────────── */
  double _distKm(Map<String, double> a, Map<String, double> b) {
    const R = 6371.0;
    final dLat = (b['lat']! - a['lat']!) * math.pi / 180;
    final dLon = (b['lon']! - a['lon']!) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a['lat']! * math.pi / 180) *
            math.cos(b['lat']! * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double _calculateMonthlyInstallment() {
    final durationMonths = int.tryParse(_preferredEMIDuration.split(' ')[0]) ?? 0;
    const interestRate = 0.12;
    final monthlyRate = interestRate / 12;
    final totalWithInterest = widget.productPrice * (1 + interestRate * (durationMonths / 12));
    return durationMonths > 0 ? totalWithInterest / durationMonths : 0;
  }

  void _validateField(String name, String value) {
    String errorMsg = '';
    switch (name) {
      case 'fullName':
        if (value.trim().isEmpty) {
          errorMsg = 'Full Name is required.';
        }
        break;
      case 'mobileNumber':
        if (value.isEmpty) {
          errorMsg = 'Mobile Number is required.';
        } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
          errorMsg = 'Mobile Number must be a 10-digit number.';
        }
        break;
      case 'aadhaarLastFour':
        if (value.isEmpty) {
          errorMsg = 'Last 4 digits of Aadhaar are required.';
        } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
          errorMsg = 'Last 4 digits of Aadhaar must be a 4-digit number.';
        }
        break;
      case 'monthlyIncomeRange':
        if (value.isEmpty) {
          errorMsg = 'Please select a Monthly Income Range.';
        }
        break;
      case 'preferredEMIDuration':
        if (value.isEmpty) {
          errorMsg = 'Please select a Preferred EMI Duration.';
        }
        break;
      case 'address':
        if (value.trim().isEmpty) {
          errorMsg = 'Address is required.';
        } else if (value.trim().length < 10) {
          errorMsg = 'Address must be at least 10 characters long.';
        }
        break;
      case 'city':
        if (value.trim().isEmpty) {
          errorMsg = 'City is required.';
        }
        break;
      case 'postalCode':
        if (value.trim().isEmpty) {
          errorMsg = 'Postal Code is required.';
        } else if (!RegExp(r'^\d{5,6}$').hasMatch(value)) {
          errorMsg = 'Postal Code must be a 5 or 6-digit number.';
        }
        break;
    }
    setState(() {
      _formErrors[name] = errorMsg;
    });
  }

  bool _validateForm() {
    _formErrors.clear();
    [
      'fullName',
      'mobileNumber',
      'aadhaarLastFour',
      'monthlyIncomeRange',
      'preferredEMIDuration',
      'address',
      'city',
      'postalCode'
    ].forEach((key) {
      final value = key == 'fullName'
          ? _fullNameC.text
          : key == 'mobileNumber'
              ? _mobileNumberC.text
              : key == 'aadhaarLastFour'
                  ? _aadhaarLastFourC.text
                  : key == 'monthlyIncomeRange'
                      ? _monthlyIncomeRange
                      : key == 'preferredEMIDuration'
                          ? _preferredEMIDuration
                          : key == 'address'
                              ? _addressC.text
                              : key == 'city'
                                  ? _cityC.text
                                  : _postalCodeC.text;
      _validateField(key, value);
    });

    // Check income vs. installment
    final incomeRange = RegExp(r'₹(\d+,\d+)-(\d+,\d+)').firstMatch(_monthlyIncomeRange);
    if (incomeRange != null) {
      final minIncome = int.tryParse(incomeRange.group(1)!.replaceAll(',', '')) ?? 0;
      final monthlyInstallment = _calculateMonthlyInstallment();
      if (monthlyInstallment > minIncome * 0.5) {
        setState(() {
          _formErrors['monthlyIncomeRange'] =
              'Monthly installment exceeds 50% of your minimum income. Please select a longer EMI duration.';
        });
      }
    }

    return _formErrors.values.every((error) => error.isEmpty);
  }

  /* ─── Data Load ──────────────────────────────────────────────── */
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _session = context.read<AppState>().session;
      if (_session == null) {
        context.go('/auth');
        return;
      }

      _buyerLoc = context.read<AppState>().buyerLocation ?? {'lat': 12.9753, 'lon': 77.591};

      // Fetch seller details
      final sellerData = await _retry(() => _spb
          .from('sellers')
          .select('store_name, latitude, longitude')
          .eq('id', widget.sellerId)
          .single());

      if (sellerData == null) {
        setState(() => _error = 'Seller not found. Please ensure the seller exists.');
        return;
      }

      setState(() {
        _sellerDetails = {
          'name': sellerData['store_name'] ?? 'Unknown Seller',
          'latitude': sellerData['latitude'],
          'longitude': sellerData['longitude'],
        };
      });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<T> _retry<T>(Future<T> Function() fn,
      {int times = 3, Duration delay = const Duration(seconds: 1)}) async {
    for (var i = 0; i < times; i++) {
      try {
        return await fn();
      } catch (_) {
        if (i == times - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    throw Exception('retry failed');
  }

  /* ─── Form Submission ────────────────────────────────────────── */
  Future<void> _submit() async {
    if (!_validateForm()) {
      final errorMessages = _formErrors.values.where((msg) => msg.isNotEmpty).join(' ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the following errors: $errorMessages'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      _shippingAddress =
          '${_addressC.text}, City: ${_cityC.text}, Postal Code: ${_postalCodeC.text}';

      // Calculate distance and estimated delivery
      final sellerLoc = {
        'lat': (_sellerDetails!['latitude'] as num?)?.toDouble() ?? 0.0,
        'lon': (_sellerDetails!['longitude'] as num?)?.toDouble() ?? 0.0,
      };
      final distance = _distKm(_buyerLoc!, sellerLoc);
      final deliveryOffset = distance <= 40 ? 24 : 48;
      final estimatedDelivery = DateTime.now().add(Duration(hours: deliveryOffset));

      // Insert EMI application
      final emiData = await _retry(() => _spb.from('emi_applications').insert({
            'user_id': _session!.user.id,
            'product_id': widget.productId,
            'product_name': widget.productName,
            'product_price': widget.productPrice,
            'full_name': _fullNameC.text,
            'mobile_number': _mobileNumberC.text,
            'aadhaar_last_four': _aadhaarLastFourC.text,
            'monthly_income_range': _monthlyIncomeRange,
            'preferred_emi_duration': _preferredEMIDuration,
            'shipping_address': _shippingAddress,
            'seller_id': widget.sellerId,
            'seller_name': _sellerDetails!['name'],
            'status': 'pending',
          }).select().single());

      // Insert order
      final orderData = await _retry(() => _spb.from('orders').insert({
            'user_id': _session!.user.id,
            'seller_id': widget.sellerId,
            'total': widget.productPrice,
            'order_status': 'pending',
            'payment_method': 'emi',
            'shipping_location': 'POINT(${_buyerLoc!['lon']} ${_buyerLoc!['lat']})',
            'shipping_address': _shippingAddress,
            'emi_application_uuid': emiData['id'],
            'estimated_delivery': estimatedDelivery.toIso8601String(),
          }).select().single());

      // Insert notification
      final notificationPayload = {
        'recipient': 'agent',
        'message':
            'Buyer ${_fullNameC.text} (${_mobileNumberC.text}) applied for EMI. Product: ${widget.productName}, Price: ₹${widget.productPrice}.',
        'created_at': DateTime.now().toIso8601String(),
      };
      final notificationError =
          await _retry(() => _spb.from('notifications').insert(notificationPayload));
      if (notificationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'EMI application submitted, but failed to notify the agent. Please contact support if needed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      setState(() {
        _submissionSuccess = true;
        _newOrderId = orderData['id'];
        _emiDetails = {
          'monthlyInstallment': _calculateMonthlyInstallment(),
          'estimatedDelivery': estimatedDelivery.toString().substring(0, 16),
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EMI application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _error = 'Error submitting EMI application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting EMI application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  /* ─── Lifecycle ──────────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameC.dispose();
    _mobileNumberC.dispose();
    _aadhaarLastFourC.dispose();
    _addressC.dispose();
    _cityC.dispose();
    _postalCodeC.dispose();
    super.dispose();
  }

  /* ─── UI Helpers ─────────────────────────────────────────────── */
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply for EMI (No Credit Card Needed)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 16),
            // Full Name
            TextFormField(
              controller: _fullNameC,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _validateField('fullName', value),
            ),
            if (_formErrors['fullName']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['fullName']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Mobile Number
            TextFormField(
              controller: _mobileNumberC,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: 'Enter 10-digit mobile number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => _validateField('mobileNumber', value),
              maxLength: 10,
            ),
            if (_formErrors['mobileNumber']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['mobileNumber']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Aadhaar Last Four
            TextFormField(
              controller: _aadhaarLastFourC,
              decoration: const InputDecoration(
                labelText: 'Last 4 Digits of Aadhaar',
                hintText: 'Enter last 4 digits of Aadhaar',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _validateField('aadhaarLastFour', value),
              maxLength: 4,
            ),
            if (_formErrors['aadhaarLastFour']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['aadhaarLastFour']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Address
            TextFormField(
              controller: _addressC,
              decoration: const InputDecoration(
                labelText: 'Shipping Address',
                hintText: 'Enter your address (e.g., house number, street, area)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _validateField('address', value),
            ),
            if (_formErrors['address']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['address']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // City
            TextFormField(
              controller: _cityC,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Enter your city',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _validateField('city', value),
            ),
            if (_formErrors['city']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['city']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Postal Code
            TextFormField(
              controller: _postalCodeC,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                hintText: 'Enter 5 or 6-digit postal code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _validateField('postalCode', value),
              maxLength: 6,
            ),
            if (_formErrors['postalCode']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['postalCode']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Monthly Income Range
            DropdownButtonFormField<String>(
              value: _monthlyIncomeRange,
              decoration: const InputDecoration(
                labelText: 'Monthly Income Range',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: '₹20,000-30,000', child: Text('₹20,000 - ₹30,000')),
                DropdownMenuItem(
                    value: '₹30,000-50,000', child: Text('₹30,000 - ₹50,000')),
                DropdownMenuItem(
                    value: '₹50,000-80,000', child: Text('₹50,000 - ₹80,000')),
                DropdownMenuItem(value: '₹80,000+', child: Text('₹80,000+')),
              ],
              onChanged: (value) {
                setState(() {
                  _monthlyIncomeRange = value!;
                  _validateField('monthlyIncomeRange', value);
                });
              },
            ),
            if (_formErrors['monthlyIncomeRange']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['monthlyIncomeRange']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Preferred EMI Duration
            DropdownButtonFormField<String>(
              value: _preferredEMIDuration,
              decoration: const InputDecoration(
                labelText: 'Preferred EMI Duration',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '3 months', child: Text('3 months')),
                DropdownMenuItem(value: '6 months', child: Text('6 months')),
                DropdownMenuItem(value: '9 months', child: Text('9 months')),
                DropdownMenuItem(value: '12 months', child: Text('12 months')),
              ],
              onChanged: (value) {
                setState(() {
                  _preferredEMIDuration = value!;
                  _validateField('preferredEMIDuration', value);
                });
              },
            ),
            if (_formErrors['preferredEMIDuration']!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formErrors['preferredEMIDuration']!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            // Product ID
            TextFormField(
              initialValue: widget.productId,
              decoration: const InputDecoration(
                labelText: 'Product ID',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            // Product Name
            TextFormField(
              initialValue: widget.productName,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            // Product Price
            TextFormField(
              initialValue: '₹${widget.productPrice.toStringAsFixed(2)}',
              decoration: const InputDecoration(
                labelText: 'Product Price',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            // Form Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    _submitting ? 'Submitting...' : 'Apply for EMI Now',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                OutlinedButton(
                  onPressed: _submitting ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Congratulations, ${_fullNameC.text}!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your EMI application for ${widget.productName} has been submitted successfully!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Monthly Installment: ₹${_emiDetails['monthlyInstallment'].toStringAsFixed(2)}'),
                    Text('EMI Duration: $_preferredEMIDuration'),
                    Text('Total Amount: ₹${widget.productPrice.toStringAsFixed(2)}'),
                    Text('Estimated Delivery: ${_emiDetails['estimatedDelivery']}'),
                    const Text('Status: Pending Approval'),
                    const SizedBox(height: 8),
                    const Text(
                        'We’ll notify you once the seller reviews your application.'),
                    const SizedBox(height: 8),
                    const Text(
                      'Our trusted agent will call you within 24 hours to complete the process and ensure a smooth experience. Thank you for choosing us!',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/order-details/$_newOrderId'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text(
                'View Order Details',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ─── Build ──────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Apply for EMI'),
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for EMI'),
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
      ),
      body: Stack(
        children: [
          _buildForm(),
          if (_submissionSuccess) _buildSuccessDialog(),
        ],
      ),
    );
  }
}