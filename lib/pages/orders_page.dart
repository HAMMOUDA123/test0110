import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const backgroundColor = Color(0xFF181A20); // Dark background
const cardColor = Color(0xFF23232B); // Card color
const accentColor = Color(0xFFFF5A5F); // Accent (red)
const textColor = Colors.white; // White text
const secondaryColor = Color(0xFF4CAF50); // Green for highlights

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String searchQuery = '';
  String statusFilter = 'All';
  late AnimationController _bgController;
  late Animation<double> _bgFade;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);
    _bgController.forward();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    final response =
        await Supabase.instance.client.from('orders').select().order('id');
    setState(() {
      orders = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _acceptOrder(int index) async {
    final order = filteredOrders[index];
    await Supabase.instance.client
        .from('orders')
        .update({'status': 'Delivered'}).eq('id', order['id']);
    _fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order accepted!')),
    );
  }

  void _deleteOrder(int index) async {
    final order = filteredOrders[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client
          .from('orders')
          .delete()
          .eq('id', order['id']);
      _fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted!')),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    (order['delivery_address'] ?? '')
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Text(order['delivery_address'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text('Order: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Order #' + (order['id']?.toString() ?? ''),
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text('Date: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text((order['created_at'] ?? '').toString().substring(0, 16),
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text('Total: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${(order['total_price'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(order['status']?.toString() ?? '',
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusChangeDialog(int index) async {
    final order = filteredOrders[index];
    final statuses = ['pending', 'delivered', 'shipped', 'cancelled'];
    String? selectedStatus = (order['status']?.toString() ?? '').toLowerCase();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Order Status'),
        content: DropdownButton<String>(
          value: selectedStatus,
          items: statuses.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status[0].toUpperCase() + status.substring(1)),
            );
          }).toList(),
          onChanged: (value) {
            selectedStatus = value;
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null &&
        result.toLowerCase() !=
            (order['status']?.toString().toLowerCase() ?? '')) {
      try {
        await Supabase.instance.client
            .from('orders')
            .update({'status': result.toLowerCase()}).eq('id', order['id']);
        await _fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Order status changed to ' +
                  result[0].toUpperCase() +
                  result.substring(1) +
                  '!')),
        );
      } catch (e) {
        print('Error updating order status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change order status: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchesSearch = searchQuery.isEmpty ||
          (order['delivery_address'] ?? '')
                  ?.toLowerCase()
                  .contains(searchQuery.toLowerCase()) ==
              true ||
          (order['delivery_address'] ?? '')
                  ?.toLowerCase()
                  .contains(searchQuery.toLowerCase()) ==
              true;
      final matchesStatus = statusFilter == 'All' ||
          (order['status']?.toString().toLowerCase() ==
              statusFilter.toLowerCase());
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: secondaryColor)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: textColor),
            tooltip: 'Filter',
            onPressed: () {},
          ),
        ],
        backgroundColor: cardColor,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: FadeTransition(
        opacity: _bgFade,
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cardColor,
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildFilterChip('All', Colors.blueGrey),
                    _buildFilterChip('Pending', Colors.orange),
                    _buildFilterChip('Delivered', secondaryColor),
                    _buildFilterChip('Shipped', Colors.blue),
                    _buildFilterChip('Cancelled', accentColor),
                  ],
                ),
              ),
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'No orders found',
                              style: TextStyle(
                                  fontSize: 20, color: Colors.white54),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'All caught up! New orders will appear here.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final origIndex = orders.indexOf(order);
                          Color statusColor;
                          IconData statusIcon;
                          switch (order['status']?.toString() ?? '') {
                            case 'Delivered':
                              statusColor = secondaryColor;
                              statusIcon = Icons.check_circle;
                              break;
                            case 'Pending':
                              statusColor = Colors.orange;
                              statusIcon = Icons.hourglass_top;
                              break;
                            case 'Shipped':
                              statusColor = Colors.blue;
                              statusIcon = Icons.local_shipping;
                              break;
                            case 'Cancelled':
                              statusColor = accentColor;
                              statusIcon = Icons.cancel;
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusIcon = Icons.help_outline;
                          }
                          String initials = (order['delivery_address'] ?? '')
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase();
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 400 + index * 80),
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Card(
                                  elevation: 2.5,
                                  margin: EdgeInsets.zero,
                                  color: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  shadowColor: statusColor.withOpacity(0.13),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              statusColor.withOpacity(0.13),
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                'Order #' +
                                                    (order['id']?.toString() ??
                                                        ''),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor)),
                                            Text(
                                              '\$${(order['total_price'] ?? 0).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: secondaryColor),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (order['name'] != null &&
                                                order['name']
                                                    .toString()
                                                    .isNotEmpty)
                                              Row(
                                                children: [
                                                  const Icon(Icons.person,
                                                      color: Colors.white54,
                                                      size: 16),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      order['name'],
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: textColor),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (order['phone_number'] != null &&
                                                order['phone_number']
                                                    .toString()
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.phone,
                                                        color: Colors.white54,
                                                        size: 16),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        order['phone_number'],
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            color: textColor),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if ((order['name'] != null &&
                                                    order['name']
                                                        .toString()
                                                        .isNotEmpty) ||
                                                (order['phone_number'] !=
                                                        null &&
                                                    order['phone_number']
                                                        .toString()
                                                        .isNotEmpty))
                                              const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    color: Colors.white54,
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    order['delivery_address'] ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: textColor),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(statusIcon,
                                                    color: statusColor,
                                                    size: 18),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    order['status']
                                                            ?.toString() ??
                                                        '',
                                                    style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.white54),
                                                const SizedBox(width: 4),
                                                Text(
                                                    (order['created_at'] ?? '')
                                                        .toString()
                                                        .substring(0, 16),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white70)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        onTap: () => _showOrderDetails(order),
                                      ),
                                      const Divider(
                                          height: 1,
                                          thickness: 1,
                                          indent: 16,
                                          endIndent: 16,
                                          color: Colors.white12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if ((order['status']?.toString() ??
                                                    '') !=
                                                'Cancelled')
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.edit,
                                                      size: 18),
                                                  label: const Text(
                                                      'Change Status'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor: textColor,
                                                    minimumSize:
                                                        const Size(90, 36),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _showStatusChangeDialog(
                                                          origIndex),
                                                ),
                                              ),
                                            if ((order['status']?.toString() ??
                                                    '') !=
                                                'Cancelled')
                                              const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.delete,
                                                    size: 18),
                                                label: const Text('Delete'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: accentColor,
                                                  foregroundColor: textColor,
                                                  minimumSize:
                                                      const Size(90, 36),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    _deleteOrder(origIndex),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if ((order['status']?.toString() ?? '') ==
                                    'Pending')
                                  Positioned(
                                    top: 10,
                                    right: 18,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.18),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 1),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    final bool selected = statusFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: color.withOpacity(0.18),
        backgroundColor: cardColor,
        labelStyle: TextStyle(
          color: selected ? color : Colors.white54,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => statusFilter = label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side:
            BorderSide(color: selected ? color : Colors.transparent, width: 1),
      ),
    );
  }
}

class _AnimatedAcceptButton extends StatefulWidget {
  final VoidCallback onAccept;
  const _AnimatedAcceptButton({required this.onAccept});

  @override
  State<_AnimatedAcceptButton> createState() => _AnimatedAcceptButtonState();
}

class _AnimatedAcceptButtonState extends State<_AnimatedAcceptButton> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: accepted
          ? ElevatedButton.icon(
              key: const ValueKey('done'),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(90, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: null,
            )
          : ElevatedButton.icon(
              key: const ValueKey('accept'),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                minimumSize: const Size(90, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                setState(() => accepted = true);
                await Future.delayed(const Duration(milliseconds: 600));
                widget.onAccept();
              },
            ),
    );
  }
}
