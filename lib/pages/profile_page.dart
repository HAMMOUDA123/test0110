import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/edit_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../auth/auth_service.dart';
import 'package:flutter_application_1/pages/orders_page.dart';
import 'dart:ui';
import 'package:flutter_application_1/pages/my_orders_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _isLoggedIn = false;
  int _ordersCount = 0;
  int _favoritesCount = 0;

  late final AnimationController _avatarController;
  late final Animation<double> _avatarScaleAnim;

  late final AnimationController _listController;
  late final List<Animation<double>> _tileFadeAnims;
  late final List<Animation<Offset>> _tileSlideAnims;

  late final AnimationController _buttonController;
  late final Animation<double> _buttonFadeAnim;
  late final Animation<Offset> _buttonSlideAnim;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _avatarScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut),
    );

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tileFadeAnims = List.generate(
      4,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(0.1 * i, 0.5 + 0.1 * i, curve: Curves.easeOut),
        ),
      ),
    );
    _tileSlideAnims = List.generate(
      4,
      (i) =>
          Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(0.1 * i, 0.5 + 0.1 * i, curve: Curves.easeOut),
        ),
      ),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );
    _buttonSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    _loadUserProfile();
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _avatarController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _listController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _listController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoggedIn = false;
          _userData = null;
          _ordersCount = 0;
          _favoritesCount = 0;
          _loading = false;
        });
        return;
      }

      final data = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();

      // Fetch order count for this user
      final ordersResp = await _supabase
          .from('orders')
          .select('id')
          .eq('user_id', currentUser.id);
      final ordersCount = (ordersResp as List).length;

      // Fetch favorites count for this user
      final favResp = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', currentUser.id);
      final favoritesCount = (favResp as List).length;

      setState(() {
        _userData = data;
        _isLoggedIn = true;
        _ordersCount = ordersCount;
        _favoritesCount = favoritesCount;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoggedIn = false;
        _userData = null;
        _ordersCount = 0;
        _favoritesCount = 0;
        _loading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();
      if (context.mounted) {
        setState(() {
          _isLoggedIn = false;
          _userData = null;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark color scheme (same as home_page.dart)
    final primaryColor = const Color(0xFFFF5A5F); // Accent red
    final secondaryColor = const Color(0xFF4CAF50); // Green for stats
    final backgroundColor = const Color(0xFF181A20); // Dark background
    final cardColor = const Color(0xFF23232B); // Card color
    final textColor = Colors.white;
    final accentColor = const Color(0xFFFF5A5F); // Accent red

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Authentication Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please sign in to view your profile and access all features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Profile Card
                  Center(
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          // Avatar with shadow and animation
                          ScaleTransition(
                            scale: _avatarScaleAnim,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 44,
                                backgroundColor: Color(0xFF23232B),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Color(0xFFFF5A5F),
                                  child: Icon(Icons.person,
                                      size: 40, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Personalized Greeting
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            '${_userData?['first_name'] ?? ''} ${_userData?['last_name'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userData?['email'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // User Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ProfileStat(
                                  icon: Icons.shopping_bag,
                                  label: 'Orders',
                                  value: _ordersCount.toString(),
                                  color: accentColor),
                              _ProfileStat(
                                  icon: Icons.favorite,
                                  label: 'Favorites',
                                  value: _favoritesCount.toString(),
                                  color: accentColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section Title with colored bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Card with ListTiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: cardColor,
                child: Column(
                  children: [
                    // My Orders tile
                    AnimatedBuilder(
                      animation: _listController,
                      builder: (context, child) => Opacity(
                        opacity: _tileFadeAnims[0].value,
                        child: SlideTransition(
                          position: _tileSlideAnims[0],
                          child: child,
                        ),
                      ),
                      child: _ProfileListTile(
                        icon: Icons.shopping_bag,
                        iconBg: accentColor.withOpacity(0.12),
                        iconColor: accentColor,
                        title: 'My Orders',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyOrdersPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    // Only show Edit Profile, Favorites, and Addresses (remove My Orders)
                    AnimatedBuilder(
                      animation: _listController,
                      builder: (context, child) => Opacity(
                        opacity: _tileFadeAnims[1].value,
                        child: SlideTransition(
                          position: _tileSlideAnims[1],
                          child: child,
                        ),
                      ),
                      child: _ProfileListTile(
                        icon: Icons.person_outline,
                        iconBg: accentColor.withOpacity(0.12),
                        iconColor: accentColor,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(userData: _userData!),
                            ),
                          ).then((result) {
                            if (result == true) _loadUserProfile();
                          });
                        },
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _listController,
                      builder: (context, child) => Opacity(
                        opacity: _tileFadeAnims[2].value,
                        child: SlideTransition(
                          position: _tileSlideAnims[2],
                          child: child,
                        ),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                    AnimatedBuilder(
                      animation: _listController,
                      builder: (context, child) => Opacity(
                        opacity: _tileFadeAnims[3].value,
                        child: SlideTransition(
                          position: _tileSlideAnims[3],
                          child: child,
                        ),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Move buttons up
            AnimatedBuilder(
              animation: _buttonController,
              builder: (context, child) => Opacity(
                opacity: _buttonFadeAnim.value,
                child: SlideTransition(
                  position: _buttonSlideAnim,
                  child: child,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                    label: Text(
                      'Back',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _buttonController,
              builder: (context, child) => Opacity(
                opacity: _buttonFadeAnim.value,
                child: SlideTransition(
                  position: _buttonSlideAnim,
                  child: child,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleLogout(context),
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Decorative bar at the bottom
            Container(
              width: double.infinity,
              height: 6,
              color: accentColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        title: const Text('Pepperoni Pizza'),
        subtitle: const Text('Ordered on 2024-05-01\nStatus: Delivered'),
        trailing: const Text(
          ' 24.99',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () {},
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.red),
        title: const Text('123 Pizza Street'),
        subtitle: const Text('New York, NY'),
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.credit_card, color: Colors.blue),
        title: const Text('Visa **** 1234'),
        subtitle: const Text('Expires 12/26'),
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
      ),
    );
  }
}

// Add the custom ListTile widget for profile actions
class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ProfileListTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _BottomWavePainter extends CustomPainter {
  final Color primaryColor;
  _BottomWavePainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.4, size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning! ☀️';
  if (hour < 18) return 'Good afternoon! 🌤️';
  return 'Good evening! 🌙';
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ProfileStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
      ],
    );
  }
}
