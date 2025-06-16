import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        notifications = [];
        isLoading = false;
      });
      return;
    }
    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    setState(() {
      notifications = response;
      isLoading = false;
    });
  }

  Future<void> deleteNotification(String id) async {
    await supabase.from('notifications').delete().eq('id', id);
    setState(() {
      notifications.removeWhere((n) => n['id'] == id);
    });
  }

  // Fetch product info for a notification using item_id
  Future<Map<String, dynamic>?> fetchProductForNotification(Map n) async {
    final productId = n['item_id'];
    if (productId == null) return null;
    final products = await supabase
        .from('products')
        .select('name, image_url')
        .eq('id', productId)
        .limit(1);
    if (products.isEmpty) return null;
    return products[0];
  }

  @override
  Widget build(BuildContext context) {
    // Colors from home_page.dart
    final backgroundColor = const Color(0xFF181A20);
    final cardColor = const Color(0xFF23232B);
    final accentColor = const Color(0xFFFF5A5F);
    final textColor = Colors.white;
    final secondaryTextColor = Colors.white70;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: fetchProductForNotification(n),
                      builder: (context, snapshot) {
                        final product = snapshot.data;
                        final productName = product?['name'] ?? 'your order';
                        final productImage = product?['image_url'];
                        final status =
                            n['message']?.split('status is now ').last ?? '';
                        return _NotificationCard(
                          productName: productName,
                          productImageUrl: productImage,
                          status: status,
                          time: n['created_at'] != null
                              ? DateTime.tryParse(n['created_at']) != null
                                  ? timeAgo(DateTime.parse(n['created_at']))
                                  : ''
                              : '',
                          isRead: n['read'] ?? false,
                          cardColor: cardColor,
                          accentColor: accentColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onDelete: () => deleteNotification(n['id']),
                        );
                      },
                    );
                  },
                ),
    );
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _NotificationCard extends StatelessWidget {
  final String productName;
  final String? productImageUrl;
  final String status;
  final String time;
  final bool isRead;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.productName,
    this.productImageUrl,
    required this.status,
    required this.time,
    this.isRead = false,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isRead ? cardColor : accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isRead
            ? null
            : Border.all(color: accentColor.withOpacity(0.5), width: 1.2),
      ),
      child: ListTile(
        leading: productImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  productImageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 48),
                ),
              )
            : const Icon(Icons.local_pizza, size: 48, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        title: Text(
          'Your $productName is now $status',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: textColor,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(
              color: secondaryTextColor.withOpacity(0.7), fontSize: 12),
        ),
        isThreeLine: false,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
          tooltip: 'Delete notification',
        ),
      ),
    );
  }
}
