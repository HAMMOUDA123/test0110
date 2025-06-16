import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_address_page.dart';

class DatabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> updateUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? imageUrl,
    required String userId,
  }) async {
    try {
      await supabase.from('users').update({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'address': address,
        if (imageUrl != null) 'avatar_url': imageUrl,
      }).eq('id', userId);

      print('User updated successfully!');
    } catch (e) {
      print('Exception: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final data =
          await supabase.from('users').select().eq('id', user.id).single();
      return data;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final String path = 'avatars/$userId.png';
      await supabase.storage.from('avatars').upload(path, imageFile);
      return supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      print('Exception uploading image: $e');
      throw e;
    }
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final db = DatabaseService();
  String? _userId;

  late AnimationController _avatarController;
  late AnimationController _buttonController;
  double _avatarScale = 1.0;
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.05,
      value: 1.0,
    )..addListener(() {
        setState(() {
          _avatarScale = _avatarController.value;
        });
      });
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    )..addListener(() {
        setState(() {
          _buttonScale = _buttonController.value;
        });
      });
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _buttonController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    try {
      // Pre-fill the form with existing user data, handle empty/null values
      _firstNameController.text =
          widget.userData['first_name']?.toString() ?? '';
      _lastNameController.text = widget.userData['last_name']?.toString() ?? '';
      _emailController.text = widget.userData['email']?.toString() ?? '';
      _phoneController.text = widget.userData['phone_number']?.toString() ?? '';
      _addressController.text = widget.userData['address']?.toString() ?? '';
      _userId = widget.userData['id']?.toString();

      if (_userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Unable to load user profile'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unable to update profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validate inputs
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      if (!_emailController.text.contains('@')) {
        throw Exception('Please enter a valid email address');
      }

      // Update profile
      await db.updateUser(
        userId: _userId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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

  Future<void> _pickImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onAvatarTap() async {
    await _avatarController.animateTo(1.05);
    await _avatarController.animateTo(1.0);
    _pickImage();
  }

  @override
  Widget build(BuildContext context) {
    // Home page color scheme
    final backgroundColor = const Color(0xFF181A20); // Dark background
    final cardColor = const Color(0xFF23232B); // Card color
    final accentColor = const Color(0xFFFF5A5F); // Accent (red)
    final textColor = Colors.white; // White text
    final secondaryColor = const Color(0xFF4CAF50); // Green for highlights
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _onAvatarTap,
                child: AnimatedScale(
                  scale: _avatarScale,
                  duration: const Duration(milliseconds: 150),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: cardColor,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.userData['avatar_url'] != null
                                    ? NetworkImage(widget.userData['avatar_url'])
                                    : const NetworkImage(
                                        'https://randomuser.me/api/portraits/men/32.jpg'))
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _firstNameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.person, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.person, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.email, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.phone, color: accentColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Address Section
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAddressPage(
                                userData: widget.userData,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _addressController.text = result;
                              // Update the userData map to reflect the new address
                              widget.userData['address'] = result;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: accentColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Address',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _addressController.text.isNotEmpty
                                          ? _addressController.text
                                          : (widget.userData['address']
                                                  ?.toString() ??
                                              'Add your address'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTapDown: (_) => _buttonController.animateTo(0.97),
                  onTapUp: (_) => _buttonController.animateTo(1.0),
                  onTapCancel: () => _buttonController.animateTo(1.0),
                  onTap: _isLoading ? null : _saveProfile,
                  child: AnimatedScale(
                    scale: _buttonScale,
                    duration: const Duration(milliseconds: 100),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
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
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
