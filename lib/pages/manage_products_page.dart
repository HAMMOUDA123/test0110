import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/sauce_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';

const backgroundColor = Color(0xFF181A20); // Dark background
const cardColor = Color(0xFF23232B); // Card color
const accentColor = Color(0xFFFF5A5F); // Accent (red)
const textColor = Colors.white; // White text
const secondaryColor = Color(0xFF4CAF50); // Green for highlights

// Add event bus for product updates
class ProductUpdateEvent {
  static final _instance = ProductUpdateEvent._internal();
  factory ProductUpdateEvent() => _instance;
  ProductUpdateEvent._internal();

  final _listeners = <Function()>[];

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

class SauceSelectorModal extends StatefulWidget {
  final List<Map<String, dynamic>> sauces;
  final List<int> initiallySelected;

  const SauceSelectorModal({
    required this.sauces,
    required this.initiallySelected,
    Key? key,
  }) : super(key: key);

  @override
  State<SauceSelectorModal> createState() => _SauceSelectorModalState();
}

class _SauceSelectorModalState extends State<SauceSelectorModal> {
  late List<int> selectedIds;

  @override
  void initState() {
    super.initState();
    selectedIds = List<int>.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Sauces',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...widget.sauces.map((sauce) => CheckboxListTile(
                  title: Text(sauce['name']),
                  value: selectedIds.contains(sauce['id']),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        selectedIds.add(sauce['id']);
                      } else {
                        selectedIds.remove(sauce['id']);
                      }
                    });
                  },
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedIds),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({Key? key}) : super(key: key);

  @override
  _ManageProductsPageState createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final SauceService _sauceService = SauceService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _isCategoryLoading = true;
  bool _isProductLoading = true;
  List<Map<String, dynamic>> _sauces = [];
  List<int> _selectedSauceIds = [];
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  FivemanageImageService _imageService = FivemanageImageService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
    _fetchSauces();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isCategoryLoading = true);
    try {
      final data = await _categoryService.fetchCategories();
      setState(() {
        _categories = data;
        _isCategoryLoading = false;
      });
    } catch (e) {
      setState(() => _isCategoryLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading categories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isProductLoading = true);
    try {
      final data = await _productService.fetchProducts();
      setState(() {
        _products = data;
        _isProductLoading = false;
      });
      // Notify listeners after fetching products
      ProductUpdateEvent().notifyListeners();
    } catch (e) {
      setState(() => _isProductLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchSauces() async {
    final sauces = await _sauceService.fetchSauces();
    setState(() {
      _sauces = sauces;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() => _isLoading = true);
    await _fetchProducts();
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get filteredProducts {
    var filtered = _products;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product['name']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product['description']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((product) => product['category'] == _selectedCategory)
          .toList();
    }
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return a['name'].compareTo(b['name']);
        case 'price':
          return a['price'].compareTo(b['price']);
        default:
          return 0;
      }
    });
    return filtered;
  }

  Widget _buildProductImage(String? imageUrl, {bool isAvailable = true}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Center(
                    child: Icon(Icons.image_outlined,
                        size: 48, color: Colors.grey),
                  )
                : Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              isAvailable ? 'Available' : 'Not Available',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product['image_url'] != null &&
                    product['image_url'].isNotEmpty) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        product['image_url'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${(product['price'] ?? '0').toString()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product['category'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if ((product['sauce_type'] ?? '') != '') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_pizza, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Sauce: ${(product['sauce_type'] ?? '')}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['description'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedCategory =
        _categories.isNotEmpty ? (_categories[0]['name'] ?? '') : '';
    final formKey = GlobalKey<FormState>();
    List<int> selectedSauceIds = [];
    File? selectedImageFile;
    String? uploadedImageUrl;
    bool isUploadingImage = false;

    Future<void> pickImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          selectedImageFile = File(pickedFile.path);
          isUploadingImage = true;
        });
        try {
          final url = await _imageService.uploadImage(selectedImageFile!, {});
          setState(() {
            uploadedImageUrl = url;
            isUploadingImage = false;
          });
        } catch (e) {
          setState(() {
            isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Image upload failed!'),
                backgroundColor: Colors.red),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Add Product',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: isUploadingImage
                          ? const Center(child: CircularProgressIndicator())
                          : (uploadedImageUrl != null
                              ? Image.network(uploadedImageUrl!,
                                  fit: BoxFit.cover)
                              : (selectedImageFile != null
                                  ? Image.file(selectedImageFile!,
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.add_a_photo,
                                      size: 40, color: Colors.grey))),
                    ),
                  ),
                  if (uploadedImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Image uploaded!',
                          style: TextStyle(color: Colors.green)),
                    ),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixText: '\$',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _isCategoryLoading
                        ? <DropdownMenuItem<String>>[]
                        : _categories
                            .map((category) => DropdownMenuItem<String>(
                                  value: category['name'],
                                  child: Text(category['name']),
                                ))
                            .toList(),
                    onChanged: _isCategoryLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              selectedCategory = value;
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet<List<int>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SauceSelectorModal(
                          sauces: _sauces,
                          initiallySelected: selectedSauceIds,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          selectedSauceIds = result;
                        });
                      }
                    },
                    child: Text(
                      selectedSauceIds.isEmpty
                          ? 'Select Sauces'
                          : 'Selected: ${selectedSauceIds.length} sauce(s)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sauces
                        .where((s) => selectedSauceIds.contains(s['id']))
                        .map((s) => Chip(label: Text(s['name'])))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              final productId =
                                  await _productService.addProduct(
                                name: nameController.text,
                                price: double.parse(priceController.text),
                                category: selectedCategory,
                                description: descriptionController.text,
                                imageUrl: uploadedImageUrl,
                              );
                              await _productService.setPizzaSauces(
                                  productId, selectedSauceIds);
                              Navigator.pop(context);
                              await _fetchProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Product added successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding product: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final TextEditingController nameController =
        TextEditingController(text: product['name'] ?? '');
    final TextEditingController priceController =
        TextEditingController(text: (product['price'] ?? '').toString());
    final TextEditingController descriptionController =
        TextEditingController(text: product['description'] ?? '');
    String selectedCategory = product['category'] ??
        (_categories.isNotEmpty ? (_categories[0]['name'] ?? '') : '');
    final formKey = GlobalKey<FormState>();
    List<int> selectedSauceIds = [];
    File? selectedImageFile;
    String? uploadedImageUrl = product['image_url'];
    bool isUploadingImage = false;

    _productService.fetchPizzaSauceIds(product['id']).then((ids) {
      setState(() {
        selectedSauceIds = List<int>.from(ids);
      });
    });

    Future<void> pickImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          selectedImageFile = File(pickedFile.path);
          isUploadingImage = true;
        });
        try {
          final url = await _imageService.uploadImage(selectedImageFile!, {});
          setState(() {
            uploadedImageUrl = url;
            isUploadingImage = false;
          });
        } catch (e) {
          setState(() {
            isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Image upload failed!'),
                backgroundColor: Colors.red),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Edit Product',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: isUploadingImage
                          ? const Center(child: CircularProgressIndicator())
                          : (uploadedImageUrl != null
                              ? Image.network(uploadedImageUrl!,
                                  fit: BoxFit.cover)
                              : (selectedImageFile != null
                                  ? Image.file(selectedImageFile!,
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.add_a_photo,
                                      size: 40, color: Colors.grey))),
                    ),
                  ),
                  if (uploadedImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Image uploaded!',
                          style: TextStyle(color: Colors.green)),
                    ),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixText: '\$',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _isCategoryLoading
                        ? <DropdownMenuItem<String>>[]
                        : _categories
                            .map((category) => DropdownMenuItem<String>(
                                  value: category['name'],
                                  child: Text(category['name']),
                                ))
                            .toList(),
                    onChanged: _isCategoryLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              selectedCategory = value;
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet<List<int>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SauceSelectorModal(
                          sauces: _sauces,
                          initiallySelected: selectedSauceIds,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          selectedSauceIds = result;
                        });
                      }
                    },
                    child: Text(
                      selectedSauceIds.isEmpty
                          ? 'Select Sauces'
                          : 'Selected: ${selectedSauceIds.length} sauce(s)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _sauces
                        .where((s) => selectedSauceIds.contains(s['id']))
                        .map((s) => Chip(label: Text(s['name'])))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        try {
                          await _productService.updateProduct(
                            id: product['id'] ?? 0,
                            name: nameController.text,
                            price: double.parse(priceController.text),
                            category: selectedCategory,
                            description: descriptionController.text,
                            imageUrl: uploadedImageUrl,
                          );
                          await _productService.setPizzaSauces(
                              product['id'], selectedSauceIds);
                          Navigator.pop(context);
                          await _fetchProducts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Product updated successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating product: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    print('Deleting product with id: $id');
    try {
      await _productService.deleteProduct(id);
      await _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxExtent = screenWidth < 500 ? screenWidth : 320;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title:
            const Text('Manage Products', style: TextStyle(color: textColor)),
        elevation: 2,
        backgroundColor: cardColor,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: cardColor,
                          style: const TextStyle(color: textColor),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          items: _isCategoryLoading
                              ? <DropdownMenuItem<String>>[]
                              : [
                                  const DropdownMenuItem<String>(
                                    value: 'All',
                                    child: Text('All', style: TextStyle(color: textColor)),
                                  ),
                                  ..._categories.map((category) => DropdownMenuItem<String>(
                                        value: category['name'],
                                        child: Text(category['name'], style: const TextStyle(color: textColor)),
                                      )),
                                ],
                          onChanged: _isCategoryLoading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          dropdownColor: cardColor,
                          style: const TextStyle(color: textColor),
                          decoration: const InputDecoration(
                            labelText: 'Sort by',
                            labelStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'name',
                                child: Text('Name', style: TextStyle(color: textColor))),
                            DropdownMenuItem(
                                value: 'price',
                                child: Text('Price', style: TextStyle(color: textColor))),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshProducts,
              child: _isProductLoading
                  ? const Center(child: CircularProgressIndicator(color: accentColor))
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text('No products found', style: TextStyle(fontSize: 16, color: Colors.white54)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxExtent.toDouble(),
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22),
                                    onTap: () => _showProductDetails(product),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              color: backgroundColor,
                                              child: (product['image_url'] == null || product['image_url'].isEmpty)
                                                  ? const SizedBox(
                                                      height: 110,
                                                      child: Center(
                                                        child: Icon(Icons.image_outlined, size: 48, color: Colors.white24),
                                                      ),
                                                    )
                                                  : Image.network(
                                                      product['image_url'],
                                                      height: 110,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                                                        height: 110,
                                                        child: Center(
                                                          child: Icon(Icons.broken_image, size: 48, color: Colors.white24),
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                    color: textColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                '\$${(product['price'] ?? '0').toString()}',
                                                style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 7),
                                          Wrap(
                                            spacing: 6,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              if (product['is_available'] ?? true)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: secondaryColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Available',
                                                    style: TextStyle(
                                                      color: secondaryColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: accentColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Not Available',
                                                    style: TextStyle(
                                                      color: accentColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 6),
                                              Chip(
                                                label: Text(
                                                  product['category'] ?? '',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                                                ),
                                                backgroundColor: Colors.blueGrey[700],
                                                labelStyle: const TextStyle(color: textColor),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ],
                                          ),
                                          if ((product['description'] ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 7),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.info_outline, size: 16, color: Colors.white54),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    product['description'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white70,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (product['sauces'] != null && (product['sauces'] as List).isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 2,
                                              children: (product['sauces'] as List).map<Widget>((sauceId) {
                                                final sauce = _sauces.firstWhere(
                                                  (s) => s['id'] == sauceId,
                                                  orElse: () => {},
                                                );
                                                if (sauce.isEmpty)
                                                  return const SizedBox();
                                                return Chip(
                                                  label: Text(sauce['name'], style: const TextStyle(fontSize: 11, color: accentColor)),
                                                  backgroundColor: Colors.black45,
                                                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final buttonWidth = (constraints.maxWidth - 6) / 2;
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Flexible(
                                                    child: SizedBox(
                                                      width: buttonWidth > 40 ? buttonWidth : 32,
                                                      height: buttonWidth > 40 ? buttonWidth : 32,
                                                      child: IconButton(
                                                        padding: EdgeInsets.zero,
                                                        iconSize: buttonWidth > 40 ? 22 : 16,
                                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                                        tooltip: 'Edit',
                                                        onPressed: () => _showEditProductDialog(product),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: SizedBox(
                                                      width: buttonWidth > 40 ? buttonWidth : 32,
                                                      height: buttonWidth > 40 ? buttonWidth : 32,
                                                      child: IconButton(
                                                        padding: EdgeInsets.zero,
                                                        iconSize: buttonWidth > 40 ? 22 : 16,
                                                        icon: const Icon(Icons.delete, color: accentColor),
                                                        tooltip: 'Delete',
                                                        onPressed: () => _showDeleteConfirmationDialog(product['id'] ?? 0),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add, color: textColor),
        label: const Text('Add Product', style: TextStyle(color: textColor)),
        elevation: 2,
        backgroundColor: accentColor,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
