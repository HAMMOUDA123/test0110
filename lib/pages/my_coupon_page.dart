import 'dart:math';
import 'package:flutter/material.dart';

class MyCouponPage extends StatefulWidget {
  final int orderCount;
  final Function(int) onClaimed;
  const MyCouponPage(
      {Key? key, required this.orderCount, required this.onClaimed})
      : super(key: key);

  @override
  State<MyCouponPage> createState() => _MyCouponPageState();
}

class _MyCouponPageState extends State<MyCouponPage> {
  late int _orderCount;
  String? _couponCode;
  bool _claimed = false;

  final Color backgroundColor = const Color(0xFF181820);
  final Color cardColor = const Color(0xFF23232B);
  final Color accentColor = const Color(0xFFFF5A5F);
  final Color progressBg = const Color(0xFF353542);
  final Color progressFg = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _orderCount = widget.orderCount;
  }

  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(8, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  void _claimCoupon() {
    setState(() {
      _couponCode = _generateCouponCode();
      _claimed = true;
      _orderCount = 0;
    });
    widget.onClaimed(_orderCount);
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_orderCount / 5).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Coupon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                'Order Objective',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'You have $_orderCount/5 orders',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 18,
                  backgroundColor: progressBg,
                  valueColor: AlwaysStoppedAnimation<Color>(progressFg),
                ),
              ),
              const SizedBox(height: 32),
              if (_couponCode != null)
                Column(
                  children: [
                    const Text('🎉 Your 10% Discount Coupon:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor, width: 1.5),
                      ),
                      child: SelectableText(
                        _couponCode!,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Use this code on your next order!',
                        style: TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed:
                        (_orderCount >= 5 && !_claimed) ? _claimCoupon : null,
                    child: const Text('Claim'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
