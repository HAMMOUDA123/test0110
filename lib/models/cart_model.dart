class CartModel {
  static final CartModel _instance = CartModel._internal();
  factory CartModel() => _instance;
  CartModel._internal();

  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product, int quantity) {
    final index = _cartItems.indexWhere((item) => item['id'] == product['id']);
    if (index != -1) {
      _cartItems[index]['quantity'] += quantity;
    } else {
      _cartItems.add({
        ...product,
        'quantity': quantity,
      });
    }
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item['id'] == productId);
  }

  void updateQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item['id'] == productId);
    if (index != -1) {
      _cartItems[index]['quantity'] = quantity;
    }
  }

  void clearCart() {
    _cartItems.clear();
  }
}
