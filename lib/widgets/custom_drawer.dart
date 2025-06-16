import 'package:flutter/material.dart';
import '../pages/profile_page.dart';
import '../pages/notifications_page.dart';
import '../pages/settings_page.dart';
import '../pages/about_page.dart';
import '../auth/auth_service.dart';
import '../pages/login_page.dart';
import '../pages/admin_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/manage_products_page.dart';
import '../pages/manage_categories_page.dart';
import '../pages/orders_page.dart';
import '../pages/manage_users_page.dart';
import '../pages/favorite_page.dart';
import '../services/favorite_service.dart';
import '../services/product_service.dart';
import '../pages/my_coupon_page.dart';

class CustomDrawer extends StatefulWidget {
  final Function()? onClose;
  final int unreadNotificationsCount;
  const CustomDrawer({
    Key? key,
    this.onClose,
    this.unreadNotificationsCount = 0,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  bool _isAdmin = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<Map<String, dynamic>> _favoriteProducts = [];
  final FavoriteService _favoriteService = FavoriteService();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _favoriteProducts = []);
      return;
    }
    final ids = await _favoriteService.fetchFavoriteProductIds(userId);
    final products = await _productService.fetchProductsByIds(ids);
    setState(() => _favoriteProducts = products);
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoggedIn = false;
          _isAdmin = false;
          _userData = null;
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();

      setState(() {
        _userData = data;
        _isAdmin = data['role'] == 'admin';
        _isLoggedIn = true;
      });
      await _loadFavorites();
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoggedIn = false;
        _isAdmin = false;
        _userData = null;
      });
    }
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();
      if (context.mounted) {
        setState(() {
          _isLoggedIn = false;
          _isAdmin = false;
          _userData = null;
        });
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
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
    // Dark theme colors
    const backgroundColor = Color(0xFF181A20);
    const cardColor = Color(0xFF23232B);
    const accentColor = Color(0xFFFF5A5F);
    const textColor = Colors.white;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
        ),
        child: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.1, 0),
              end: Offset.zero,
            ).animate(_animation),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  decoration: const BoxDecoration(
                    color: cardColor,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_pizza,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Opizza',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoggedIn) ...[
                  _DrawerSection(
                    title: 'Account',
                    items: [
                      _DrawerItem(
                        icon: _isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person_outline,
                        label: _isAdmin ? 'Admin Dashboard' : 'Profile',
                        onTap: () => _navigateToPage(
                          context,
                          _isAdmin
                              ? const AdminProfilePage()
                              : const ProfilePage(),
                        ),
                      ),
                      if (!_isAdmin) ...[
                        _DrawerItem(
                          icon: Icons.notifications,
                          label: 'Notifications',
                          badge: widget.unreadNotificationsCount > 0
                              ? '${widget.unreadNotificationsCount > 99 ? '99+' : widget.unreadNotificationsCount}'
                              : null,
                          onTap: () => _navigateToPage(
                              context, const NotificationsPage()),
                        ),
                        _DrawerItem(
                          icon: Icons.favorite,
                          label: 'Favorites',
                          onTap: () async {
                            await _loadFavorites();
                            _navigateToPage(
                              context,
                              FavoritePage(favoriteProducts: _favoriteProducts),
                            );
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.card_giftcard,
                          label: 'My Coupon',
                          onTap: () {
                            _navigateToPage(
                              context,
                              MyCouponPage(
                                orderCount: _userData?['order_count'] ?? 0,
                                onClaimed: (newCount) {
                                  // Optionally update user data or refresh
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      if (_isAdmin) ...[
                        _DrawerItem(
                          icon: Icons.inventory_2,
                          label: 'Manage Products',
                          onTap: () {
                            _navigateToPage(
                                context, const ManageProductsPage());
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.category,
                          label: 'Categories',
                          onTap: () {
                            _navigateToPage(
                                context, const ManageCategoriesPage());
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.shopping_bag,
                          label: 'Orders',
                          onTap: () {
                            _navigateToPage(context, const OrdersPage());
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.people,
                          label: 'Users',
                          onTap: () {
                            _navigateToPage(context, const ManageUsersPage());
                          },
                        ),
                      ],
                      _DrawerItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () =>
                            _navigateToPage(context, const SettingsPage()),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                if (_isLoggedIn)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_userData?['first_name'] ?? ''} ${_userData?['last_name'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    _userData?['email'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleLogout(context),
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor.withOpacity(0.15),
                              foregroundColor: accentColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Sign in to access all features',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToPage(context, const LoginPage());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<_DrawerItem> items;
  const _DrawerSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
          const SizedBox(height: 16),
          Divider(
            color: Colors.white24,
            height: 1,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFF5A5F);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: selected
          ? BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              Navigator.pop(context);
              onTap!();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withOpacity(0.15)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? accentColor : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? accentColor : Colors.white,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
