import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAddressPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditAddressPage({super.key, required this.userData});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _streetController = TextEditingController();
  final _street2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _loadAddressData() {
    try {
      _userId = widget.userData['id']?.toString();

      // Parse the existing address if it exists
      final address = widget.userData['address']?.toString() ?? '';
      if (address.isNotEmpty) {
        final parts = address.split(', ');
        if (parts.length >= 3) {
          _streetController.text = parts[0];
          _cityController.text = parts[1];
          _zipCodeController.text = parts[2];
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unable to update address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validate inputs
      if (_streetController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _zipCodeController.text.trim().isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      // Format address
      final street2 = _street2Controller.text.trim().isNotEmpty
          ? ', ${_street2Controller.text.trim()}'
          : '';
      final formattedAddress =
          '${_streetController.text.trim()}$street2, ${_cityController.text.trim()}, ${_zipCodeController.text.trim()}';

      // Update address in database
      final supabase = Supabase.instance.client;
      await supabase
          .from('users')
          .update({'address': formattedAddress}).eq('id', _userId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Update the userData map before popping
        widget.userData['address'] = formattedAddress;
        Navigator.pop(context, formattedAddress);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF181A20);
    final cardColor = const Color(0xFF23232B);
    final accentColor = const Color(0xFFFF5A5F);
    final textColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Address', style: TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Address Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _streetController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Street Address *',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.home, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _street2Controller,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Apartment, suite, etc. (optional)',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.home_work, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _cityController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'City *',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon:
                              Icon(Icons.location_city, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _zipCodeController,
                        style: TextStyle(color: textColor),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ZIP Code *',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon:
                              Icon(Icons.local_post_office, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: accentColor.withOpacity(0.2),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
