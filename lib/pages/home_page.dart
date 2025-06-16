import 'package:flutter/material.dart';
import 'cart_page.dart';
import '../widgets/custom_drawer.dart';
import 'favorite_page.dart';
import 'profile_page.dart';
import 'admin_profile_page.dart';
import 'notifications_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/favorite_service.dart';
import '../models/cart_model.dart';
import 'login_page.dart';
import 'manage_products_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;
  final _categoryService = CategoryService();
  final _productService = ProductService();
  final _favoriteService = FavoriteService();
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;
  bool _isLoggedIn = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  String? _selectedCategoryId;
  List<int> _favoriteProductIds = [];
  bool _isLoadingFavorites = true;
  String _searchQuery = '';
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadProducts();
    _loadFavorites();
    _loadUnreadNotificationsCount();
    ProductUpdateEvent().addListener(_onProductsUpdated);
  }

  @override
  void dispose() {
    ProductUpdateEvent().removeListener(_onProductsUpdated);
    super.dispose();
  }

  void _onProductsUpdated() {
    _loadProducts();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoggedIn = false;
          _isAdmin = false;
          _userData = null;
          _unreadNotificationsCount = 0; // Reset count when not logged in
        });
        return;
      }

      final data = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();

      setState(() {
        _userData = data;
        _isAdmin = data['role'] == 'admin';
        _isLoggedIn = true;
      });

      // Load notifications count after user data is loaded
      await _loadUnreadNotificationsCount();
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoggedIn = false;
        _isAdmin = false;
        _userData = null;
        _unreadNotificationsCount = 0; // Reset count on error
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.fetchProducts();
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoadingFavorites = false;
        _favoriteProductIds = [];
      });
      return;
    }
    final favorites = await _favoriteService.fetchFavoriteProductIds(userId);
    setState(() {
      _favoriteProductIds = favorites;
      _isLoadingFavorites = false;
    });
  }

  Future<void> _loadUnreadNotificationsCount() async {
    if (!_isLoggedIn) return;
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('read', false);
      setState(() {
        _unreadNotificationsCount = response.length;
      });
    } catch (e) {
      print('Error loading unread notifications count: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> filtered = _products;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              (product['name']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery.toLowerCase()) ||
              (product['description']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategoryId == null) {
      return filtered;
    }
    // Use category name for filtering
    final selectedCategory = _categories.firstWhere(
      (cat) => cat['id'].toString() == _selectedCategoryId,
      orElse: () => <String, dynamic>{},
    );
    if (selectedCategory.isEmpty) return filtered;
    return filtered
        .where((product) => product['category'] == selectedCategory['name'])
        .toList();
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (!_isLoggedIn) {
      if (index != 0) {
        // Navigate to login page instead of showing dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      return;
    }

    if (_isAdmin) {
      // Admin navigation
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminProfilePage()),
        );
      } else if (index == 2) {
        // Products page for admin
        // TODO: Navigate to products page
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminProfilePage()),
        );
      }
    } else {
      // Normal user navigation
      if (index == 1) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavoritePage(
              favoriteProducts: _products
                  .where((p) => _favoriteProductIds.contains(p['id']))
                  .toList(),
            ),
          ),
        );
        await _loadFavorites();
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartPage()),
        );
      } else if (index == 3) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
        await _loadUnreadNotificationsCount();
      } else if (index == 4) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        // Reload user data when returning from profile page
        await _loadUserData();
      }
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Mock data for demo
          final double rating = product['rating'] ?? 4.0;
          final int calories = product['calories'] ?? 300;
          final String time = product['time'] ?? '30-45 min';
          final int proteins = product['proteins'] ?? 46;
          final int fats = product['fats'] ?? 26;
          final int carbs = product['carbs'] ?? 26;
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF23232B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and favorite button
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        product['image_url'] ??
                            'https://images.pexels.com/photos/825661/pexels-photo-825661.jpeg',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!_isAdmin) // Only show favorite button for non-admin users
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
                            final userId = _supabase.auth.currentUser?.id;
                            if (userId == null) return;
                            if (_favoriteProductIds.contains(product['id'])) {
                              await _favoriteService.removeFavorite(
                                  userId, product['id']);
                              setState(() {
                                _favoriteProductIds.remove(product['id']);
                              });
                            } else {
                              await _favoriteService.addFavorite(
                                  userId, product['id']);
                              setState(() {
                                _favoriteProductIds.add(product['id']);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _favoriteProductIds.contains(product['id'])
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 22,
                              color: _favoriteProductIds.contains(product['id'])
                                  ? Colors.red
                                  : const Color(0xFFFF5A5F),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                // Name, price, rating, calories, time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, color: Color(0xFFFFA726), size: 20),
                    const SizedBox(width: 4),
                    Text(time, style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    Text(
                      '\$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Details
                const Text('Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  product['description'] ?? 'No description.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 18),
                // Quantity selector and Add to Cart
                if (!_isAdmin) // Only show add to cart button for non-admin users
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5A5F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              CartModel().addToCart({
                                ...product,
                                'image': product['image_url'] ?? '',
                              }, 1); // Default quantity 1
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${product['name']} added to cart!')),
                              );
                            },
                            child: const Text('Add to Cart',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark color scheme
    final backgroundColor = const Color(0xFF181A20); // Dark background
    final cardColor = const Color(0xFF23232B); // Card color
    final accentColor = const Color(0xFFFF5A5F); // Accent (red)
    final textColor = Colors.white; // White text
    final secondaryColor = const Color(0xFF4CAF50); // Green for price

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: null, // Remove AppBar for custom top bar
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            // Address Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on, color: accentColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivery Address',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          _userData != null &&
                                  _userData!['address'] != null &&
                                  _userData!['address']
                                      .toString()
                                      .trim()
                                      .isNotEmpty
                              ? _userData!['address']
                              : '456 Your Location',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  _isAdmin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : _isLoggedIn
                          ? CircleAvatar(
                              backgroundColor: cardColor,
                              backgroundImage:
                                  NetworkImage('https://i.pravatar.cc/300'),
                              radius: 20,
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'GUEST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search "Dish"',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: accentColor),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Promo Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GET 15% OFF',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text('on first 2 orders & Free Delivery',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 0),
                            ),
                            child: Text('Order Now',
                                style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://img.icons8.com/ios/452/french-fries.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Top Categories
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: SizedBox(
                height: 45,
                child: _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _CategoryChip(
                            label: 'All',
                            icon: Icons.restaurant,
                            selected: _selectedCategoryId == null,
                            color: accentColor,
                            onSelected: () => _onCategorySelected(null),
                          ),
                          ..._categories.map((category) {
                            return _CategoryChip(
                              label: category['name'],
                              icon: _getCategoryIcon(category['name']),
                              selected: _selectedCategoryId ==
                                  category['id'].toString(),
                              color: accentColor,
                              onSelected: () => _onCategorySelected(
                                  category['id'].toString()),
                            );
                          }).toList(),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Popular Now Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Popular Now',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Food cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoadingProducts || _isLoadingFavorites
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.no_food,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No products found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return GestureDetector(
                              onTap: () =>
                                  _showProductDetails(context, product),
                              child: _FoodCard(
                                imageUrl: product['image_url'] ??
                                    'https://images.pexels.com/photos/825661/pexels-photo-825661.jpeg',
                                title: product['name'] ?? '',
                                price: (product['price'] ?? 0.0).toDouble(),
                                category: product['category'] ?? '',
                                primaryColor: accentColor,
                                secondaryColor: secondaryColor,
                                textColor: textColor,
                                isFavorite:
                                    _favoriteProductIds.contains(product['id']),
                                onFavoritePressed: () async {
                                  final userId = _supabase.auth.currentUser?.id;
                                  if (userId == null) return;
                                  if (_favoriteProductIds
                                      .contains(product['id'])) {
                                    await _favoriteService.removeFavorite(
                                        userId, product['id']);
                                    setState(() {
                                      _favoriteProductIds.remove(product['id']);
                                    });
                                  } else {
                                    await _favoriteService.addFavorite(
                                        userId, product['id']);
                                    setState(() {
                                      _favoriteProductIds.add(product['id']);
                                    });
                                  }
                                },
                                isAdmin: _isAdmin,
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: accentColor,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: _isAdmin
              ? const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
                ]
              : [
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Home'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.favorite_border), label: 'Favorite'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.shopping_cart), label: 'Cart'),
                  BottomNavigationBarItem(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_none),
                          if (_unreadNotificationsCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${_unreadNotificationsCount > 99 ? '99+' : _unreadNotificationsCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: 'Notification'),
                  if (_isLoggedIn)
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
        ),
      ),
      drawer: CustomDrawer(
        unreadNotificationsCount: _unreadNotificationsCount,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'pizza':
        return Icons.local_pizza;
      case 'drinks':
      case 'beverages':
        return Icons.local_drink;
      case 'burgers':
        return Icons.lunch_dining;
      case 'sides':
        return Icons.fastfood;
      case 'desserts':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? color;
  final VoidCallback? onSelected;
  const _CategoryChip({
    required this.label,
    required this.icon,
    this.selected = false,
    this.color,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: selected,
        selectedColor: color ?? Colors.red,
        backgroundColor: Colors.white,
        onSelected: (_) => onSelected?.call(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double price;
  final String category;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final bool isAdmin;

  const _FoodCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        color: const Color(0xFF23232B),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (!isAdmin)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoritePressed,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: isFavorite ? Colors.red : primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!isAdmin)
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: primaryColor),
                          onPressed: () {
                            // Add to cart functionality
                          },
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
