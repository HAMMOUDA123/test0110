import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

const backgroundColor = Color(0xFF181A20); // Dark background
const cardColor = Color(0xFF23232B); // Card color
const accentColor = Color(0xFFFF5A5F); // Accent (red)
const textColor = Colors.white; // White text
const secondaryColor = Color(0xFF4CAF50); // Green for highlights

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchAllUsers();
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select(); // هذا يجيب كل اليوزرات من الجدول

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فما مشكلة في جلب اليوزرات: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole}).eq('id', userId);

      setState(() {
        _usersFuture = fetchAllUsers();
      });
      _showSnackBar('تم تحديث دور المستخدم بنجاح');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث دور المستخدم: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRoleEditDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context);
                updateUserRole(user['id'], 'Admin');
              },
            ),
            ListTile(
              title: const Text('User'),
              onTap: () {
                Navigator.pop(context);
                updateUserRole(user['id'], 'User');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users', style: TextStyle(color: textColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardColor,
        foregroundColor: textColor,
      ),
      body: Container(
        color: backgroundColor,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: secondaryColor));
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: accentColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'خطأ: ${snapshot.error}',
                      style: const TextStyle(color: accentColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _usersFuture = fetchAllUsers();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: textColor,
                      ),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'ما فماش يوزرات.',
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
              );
            }

            final users = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + index * 80),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    color: cardColor,
                    shadowColor: Colors.black.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  secondaryColor.withOpacity(0.8),
                                  accentColor.withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.transparent,
                              child: Text(
                                (user['first_name']?.isNotEmpty == true
                                    ? user['first_name'][0].toUpperCase()
                                    : '?'),
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['first_name']?.toString().isEmpty == true
                                      ? 'No name'
                                      : (user['first_name'] ?? 'No name'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user['email'] ?? 'No email',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                if (user['role'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: (user['role'] == 'Admin'
                                              ? accentColor
                                              : secondaryColor)
                                          .withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      user['role'],
                                      style: TextStyle(
                                        color: user['role'] == 'Admin'
                                            ? accentColor
                                            : secondaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 28),
                                splashRadius: 26,
                                onPressed: () => _showRoleEditDialog(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: accentColor, size: 28),
                                splashRadius: 26,
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: cardColor,
                                      title: const Text('Delete Confirmation',
                                          style: TextStyle(color: textColor)),
                                      content: const Text(
                                          'Are you sure you want to delete this user?',
                                          style: TextStyle(color: textColor)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: accentColor)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      final response = await Supabase
                                          .instance.client
                                          .from('users')
                                          .delete()
                                          .eq('id', user['id'])
                                          .select();
                                      if (response == null ||
                                          (response is List &&
                                              response.isEmpty)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'لم يتم حذف المستخدم (ربما لا يوجد أو لا تملك صلاحية)'),
                                            backgroundColor: accentColor,
                                          ),
                                        );
                                      } else {
                                        setState(() {
                                          _usersFuture = fetchAllUsers();
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('تم حذف المستخدم بنجاح'),
                                            backgroundColor: secondaryColor,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('خطأ في حذف المستخدم: $e'),
                                          backgroundColor: accentColor,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({required this.child, super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<List<Color>> gradients = [
    [
      Color(0xFF6EE7B7),
      Color(0xFF3B82F6),
      Color(0xFFF472B6)
    ], // teal, blue, pink
    [
      Color(0xFFFDE68A),
      Color(0xFFFCA5A5),
      Color(0xFF818CF8)
    ], // yellow, red, indigo
    [
      Color(0xFFA7F3D0),
      Color(0xFF60A5FA),
      Color(0xFFF9A8D4)
    ], // mint, blue, pink
    [
      Color(0xFFFECACA),
      Color(0xFF93C5FD),
      Color(0xFF6EE7B7)
    ], // red, blue, teal
  ];

  int currentIndex = 0;
  int nextIndex = 1;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              currentIndex = nextIndex;
              nextIndex = (nextIndex + 1) % gradients.length;
              _controller.reset();
              _controller.forward();
            }
          });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = List.generate(
        3,
        (i) => Color.lerp(
              gradients[currentIndex][i],
              gradients[nextIndex][i],
              _controller.value,
            )!);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: widget.child,
    );
  }
}
