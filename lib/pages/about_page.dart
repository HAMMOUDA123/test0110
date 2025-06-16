import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('À propos', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF7F9FB),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.local_pizza, size: 80, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Opizza',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _AboutSection(
            title: 'About Us',
            content:
                'Opizza is your favorite pizza delivery app. We deliver hot and fresh pizzas right to your doorstep.',
          ),
          const SizedBox(height: 24),
          _AboutSection(
            title: 'Contact Us',
            content:
                'Email: support@opizza.com\nPhone: +1 234 567 890\nAddress: 123 Pizza Street, NY',
          ),
          const SizedBox(height: 24),
          _AboutSection(
            title: 'Follow Us',
            content:
                'Stay connected with us on social media for the latest updates and special offers!',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(icon: Icons.facebook, onTap: () {}),
              _SocialButton(icon: Icons.message, onTap: () {}),
              _SocialButton(icon: Icons.chat, onTap: () {}),
              _SocialButton(icon: Icons.photo_camera, onTap: () {}),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Terms & Conditions'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final String content;

  const _AboutSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onTap,
        color: Colors.blue,
        iconSize: 32,
      ),
    );
  }
}
