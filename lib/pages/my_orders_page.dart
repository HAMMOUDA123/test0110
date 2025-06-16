import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const backgroundColor = Color(0xFF181A20);
const cardColor = Color(0xFF23232B);
const accentColor = Color(0xFFFF5A5F);
const textColor = Colors.white;
const secondaryColor = Color(0xFF4CAF50);

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        orders = [];
        isLoading = false;
      });
      return;
    }
    final response = await supabase
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .order('id');
    setState(() {
      orders = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: secondaryColor))
          : orders.isEmpty
              ? Center(
                  child: Text(
                    'No orders found.',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    Color statusColor;
                    IconData statusIcon;
                    switch (order['status']?.toString().toLowerCase() ?? '') {
                      case 'delivered':
                        statusColor = secondaryColor;
                        statusIcon = Icons.check_circle_rounded;
                        break;
                      case 'pending':
                        statusColor = Colors.orange;
                        statusIcon = Icons.hourglass_top_rounded;
                        break;
                      case 'shipped':
                        statusColor = Colors.blue;
                        statusIcon = Icons.local_shipping_rounded;
                        break;
                      case 'cancelled':
                        statusColor = accentColor;
                        statusIcon = Icons.cancel_rounded;
                        break;
                      default:
                        statusColor = Colors.grey;
                        statusIcon = Icons.help_outline_rounded;
                    }
                    String initials = (order['delivery_address'] ?? '')
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase();
                    return Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border(
                          left: BorderSide(color: statusColor, width: 5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: statusColor.withOpacity(0.13),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order['id'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        '\$${(order['total_price'] ?? 0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.white54, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          order['delivery_address'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 15, color: textColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(statusIcon,
                                          color: statusColor, size: 18),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (order['status']?.toString() ?? '')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(Icons.calendar_today,
                                          size: 15, color: Colors.white54),
                                      const SizedBox(width: 4),
                                      Text(
                                        (order['created_at'] ?? '')
                                            .toString()
                                            .substring(0, 16),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: accentColor, size: 26),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Order'),
                                        content: const Text(
                                            'Are you sure you want to delete this order?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: accentColor),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final supabase = Supabase.instance.client;
                                      await supabase
                                          .from('orders')
                                          .delete()
                                          .eq('id', order['id']);
                                      setState(() {
                                        orders.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Order deleted!')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
