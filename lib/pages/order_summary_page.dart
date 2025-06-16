import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/pages/orders_page.dart';
import 'package:flutter_application_1/pages/my_orders_page.dart';
import '../models/cart_model.dart';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({Key? key}) : super(key: key);

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Payment selection state
  int _selectedPayment = 0; // 0: Credit/Debit, 1: Cash
  int _selectedAddress = 0; // 0: Saved Address, 1: Temporary Address

  // Card form controllers
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  bool _billingSameAsShipping = true;

  // Cash on Delivery controllers
  final TextEditingController _codAddressController = TextEditingController();
  final TextEditingController _codPhoneController = TextEditingController();

  // Temporary address controllers
  final TextEditingController _tempStreetController = TextEditingController();
  final TextEditingController _tempStreet2Controller = TextEditingController();
  final TextEditingController _tempCityController = TextEditingController();
  final TextEditingController _tempZipCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _codAddressController.dispose();
    _codPhoneController.dispose();
    _tempStreetController.dispose();
    _tempStreet2Controller.dispose();
    _tempCityController.dispose();
    _tempZipCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _userData = null;
          _loading = false;
        });
        return;
      }
      final data = await supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();
      setState(() {
        _userData = data;
        _loading = false;
        // Prefill COD controllers
        _codAddressController.text = data['address']?.toString() ?? '';
        _codPhoneController.text = data['phone_number']?.toString() ?? '';
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _userData = null;
        _loading = false;
      });
      _fadeController.forward();
    }
  }

  String _getFormattedAddress() {
    if (_selectedAddress == 0) {
      return _userData?['address']?.toString() ?? '';
    } else {
      final street2 = _tempStreet2Controller.text.trim().isNotEmpty
          ? ', ${_tempStreet2Controller.text.trim()}'
          : '';
      return '${_tempStreetController.text.trim()}$street2, ${_tempCityController.text.trim()}, ${_tempZipCodeController.text.trim()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF23232B);
    final cardColor = const Color(0xFF292933);
    final accentColor = const Color(0xFFFF5A5F);
    final textColor = Colors.white;
    // Calculate total price from cart
    final cartItems = CartModel().cartItems;
    const double deliveryFee = 2.0;
    final double totalPrice = cartItems.fold(
            0.0, (sum, item) => sum + (item['price'] * item['quantity'])) +
        deliveryFee;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Order Summary',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite, color: accentColor),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Selection Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 16),
                          // Address Selection Radio Buttons
                          RadioListTile<int>(
                            value: 0,
                            groupValue: _selectedAddress,
                            activeColor: accentColor,
                            title: const Text('Use Saved Address',
                                style: TextStyle(color: Colors.white)),
                            onChanged: (value) =>
                                setState(() => _selectedAddress = value!),
                          ),
                          RadioListTile<int>(
                            value: 1,
                            groupValue: _selectedAddress,
                            activeColor: accentColor,
                            title: const Text('Use Different Address',
                                style: TextStyle(color: Colors.white)),
                            onChanged: (value) =>
                                setState(() => _selectedAddress = value!),
                          ),
                          const SizedBox(height: 16),
                          // Show appropriate address section
                          if (_selectedAddress == 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userData?['first_name'] != null &&
                                          _userData?['last_name'] != null
                                      ? '${_userData?['first_name']} ${_userData?['last_name']}'
                                      : 'Your Name',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: accentColor, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _userData?['address']?.toString() ??
                                            'No address',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextField(
                                  controller: _tempStreetController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: 'Street Address *',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    prefixIcon:
                                        Icon(Icons.home, color: accentColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _tempStreet2Controller,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Apartment, suite, etc. (optional)',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    prefixIcon: Icon(Icons.home_work,
                                        color: accentColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _tempCityController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: 'City *',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    prefixIcon: Icon(Icons.location_city,
                                        color: accentColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _tempZipCodeController,
                                  style: TextStyle(color: textColor),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'ZIP Code *',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    prefixIcon: Icon(Icons.local_post_office,
                                        color: accentColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Payment Method Title
                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 8),
                      child: Text('Payment Method',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                    // Payment Options
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        leading: Icon(Icons.credit_card,
                            color: accentColor, size: 28),
                        title: const Text('Credit & Debit Card',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        tileColor: cardColor,
                        onTap: () => setState(() => _selectedPayment = 0),
                        trailing: Radio<int>(
                          value: 0,
                          groupValue: _selectedPayment,
                          activeColor: accentColor,
                          onChanged: (val) =>
                              setState(() => _selectedPayment = 0),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ListTile(
                        leading: Icon(Icons.attach_money,
                            color: accentColor, size: 28),
                        title: const Text('Cash on Delivery',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        tileColor: cardColor,
                        onTap: () => setState(() => _selectedPayment = 1),
                        trailing: Radio<int>(
                          value: 1,
                          groupValue: _selectedPayment,
                          activeColor: accentColor,
                          onChanged: (val) =>
                              setState(() => _selectedPayment = 1),
                        ),
                      ),
                    ),
                    // Card form (show only if Credit/Debit selected)
                    if (_selectedPayment == 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Credit card',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 16)),
                                const Spacer(),
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/0/04/Mastercard-logo.png',
                                  width: 32,
                                  height: 20,
                                ),
                                const SizedBox(width: 8),
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/4/41/Visa_Logo.png',
                                  width: 32,
                                  height: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Credit card payment is currently not available. Please select Cash on Delivery.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Total Price and Place Order Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Price',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              totalPrice.toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22),
                            ),
                          ],
                        ),
                        Tooltip(
                          message: _selectedPayment == 0
                              ? 'Credit card payment is not available yet'
                              : 'Place your order',
                          child: SizedBox(
                            width: 160,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedPayment == 0
                                    ? Colors.grey
                                    : accentColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: _selectedPayment == 0 ? 0 : 8,
                                shadowColor: _selectedPayment == 0
                                    ? Colors.transparent
                                    : accentColor.withOpacity(0.18),
                              ),
                              onPressed: _selectedPayment == 0
                                  ? null
                                  : () async {
                                      final supabase = Supabase.instance.client;
                                      final user = supabase.auth.currentUser;
                                      if (user == null) return;

                                      // Validate temporary address if selected
                                      if (_selectedAddress == 1) {
                                        if (_tempStreetController.text
                                                .trim()
                                                .isEmpty ||
                                            _tempCityController.text
                                                .trim()
                                                .isEmpty ||
                                            _tempZipCodeController.text
                                                .trim()
                                                .isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Please fill in all required address fields'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                      }

                                      final String address =
                                          _selectedAddress == 0
                                              ? (_userData?['address']
                                                      ?.toString() ??
                                                  '')
                                              : _getFormattedAddress();
                                      final String phone = _selectedPayment == 1
                                          ? _codPhoneController.text
                                          : (_userData?['phone_number']
                                                  ?.toString() ??
                                              '');
                                      final String paymentMethod =
                                          _selectedPayment == 1
                                              ? 'cash_on_delivery'
                                              : 'card';

                                      final orderData = {
                                        'user_id': user.id,
                                        'total_price': totalPrice,
                                        'status': 'pending',
                                        'delivery_address': address,
                                        'phone_number': phone,
                                        'payment_method': paymentMethod,
                                      };
                                      try {
                                        final response = await supabase
                                            .from('orders')
                                            .insert(orderData)
                                            .select()
                                            .single();
                                        if (response != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('Order placed!')),
                                          );
                                          // Increment user's order_count
                                          try {
                                            final userId = user.id;
                                            final userData = await supabase
                                                .from('users')
                                                .select('order_count')
                                                .eq('id', userId)
                                                .single();
                                            final currentCount =
                                                (userData['order_count'] ?? 0)
                                                    as int;
                                            await supabase
                                                .from('users')
                                                .update({
                                              'order_count': currentCount + 1
                                            }).eq('id', userId);
                                          } catch (e) {
                                            // Optionally handle error
                                          }
                                          CartModel().clearCart();
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MyOrdersPage(),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Failed to place order.')),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    },
                              child: const Text('Place Order',
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
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
