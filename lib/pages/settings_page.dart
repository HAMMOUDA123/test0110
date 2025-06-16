import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/change_password_page.dart';
import 'package:flutter_application_1/auth/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool darkMode = false;

  String? userName;
  String? userEmail;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();
    final userData = await authService.getCurrentUserData();
    setState(() {
      userName = userData != null
          ? ((userData['first_name'] ?? '') +
                  ' ' +
                  (userData['last_name'] ?? ''))
              .trim()
          : null;
      userEmail = userData != null ? userData['email'] : null;
      _loadingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Home page color scheme
    const backgroundColor = Color(0xFF181A20); // Dark background
    const cardColor = Color(0xFF23232B); // Card color
    const accentColor = Color(0xFFFF5A5F); // Accent (red)
    const textColor = Colors.white;
    const secondaryColor = Color(0xFF4CAF50); // Green for highlights
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: textColor)),
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Profile Avatar Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            color: cardColor,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: accentColor.withOpacity(0.1),
                  child:
                      const Icon(Icons.person, size: 48, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                _loadingUser
                    ? const CircularProgressIndicator()
                    : Text(
                        (userName == null || userName!.isEmpty)
                            ? 'No Name'
                            : userName!,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                _loadingUser
                    ? const SizedBox.shrink()
                    : Text(userEmail ?? 'No Email',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Account',
            children: [
              _AnimatedTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Notifications',
            children: [
              _AnimatedSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Get notified about order updates',
                value: pushNotifications,
                onChanged: (val) => setState(() => pushNotifications = val),
                activeColor: accentColor,
              ),
              _AnimatedSwitchTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Receive offers and updates',
                value: emailNotifications,
                onChanged: (val) => setState(() => emailNotifications = val),
                activeColor: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'More',
            children: [
              _AnimatedTile(
                icon: Icons.language,
                title: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('English', style: TextStyle(color: Colors.grey)),
                    Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {},
              ),
              _AnimatedSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                value: darkMode,
                onChanged: (val) => setState(() => darkMode = val),
                activeColor: Colors.black87,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Card(
            color: const Color(0xFF23232B),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _AnimatedTile(
      {required this.icon,
      required this.title,
      this.trailing,
      required this.onTap});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: ListTile(
          leading: Icon(widget.icon, color: Color(0xFFFF5A5F)),
          title: Text(widget.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.white)),
          trailing: widget.trailing,
        ),
      ),
    );
  }
}

class _AnimatedSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _AnimatedSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          icon,
          key: ValueKey(value),
          color: value ? activeColor : Colors.white54,
        ),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w500, color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.white54))
          : null,
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Switch(
          key: ValueKey(value),
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ),
      onTap: () => onChanged(!value),
    );
  }
}
