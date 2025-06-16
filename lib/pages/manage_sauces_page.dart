import 'package:flutter/material.dart';
import '../services/sauce_service.dart';

const backgroundColor = Color(0xFF181A20); // Dark background
const cardColor = Color(0xFF23232B); // Card color
const accentColor = Color(0xFFFF5A5F); // Accent (red)
const textColor = Colors.white; // White text
const secondaryColor = Color(0xFF4CAF50); // Green for highlights

class ManageSaucesPage extends StatefulWidget {
  const ManageSaucesPage({Key? key}) : super(key: key);

  @override
  State<ManageSaucesPage> createState() => _ManageSaucesPageState();
}

class _ManageSaucesPageState extends State<ManageSaucesPage> {
  final SauceService _sauceService = SauceService();
  List<Map<String, dynamic>> _sauces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSauces();
  }

  Future<void> _fetchSauces() async {
    setState(() => _isLoading = true);
    _sauces = await _sauceService.fetchSauces();
    setState(() => _isLoading = false);
  }

  void _showSauceDialog({Map<String, dynamic>? sauce}) {
    final TextEditingController controller = TextEditingController(
      text: sauce != null ? sauce['name'] : '',
    );
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sauce == null ? 'Add Sauce' : 'Edit Sauce',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Sauce Name',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      if (sauce == null) {
                        await _sauceService.addSauce(name);
                      } else {
                        await _sauceService.updateSauce(sauce['id'], name);
                      }
                      Navigator.pop(context);
                      _fetchSauces();
                    },
                    child: Text(sauce == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSauce(int id) async {
    await _sauceService.deleteSauce(id);
    _fetchSauces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sauces', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: secondaryColor))
          : _sauces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_food_beverage,
                          size: 64, color: Colors.white24),
                      const SizedBox(height: 18),
                      const Text(
                        'No sauces yet',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white54,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first sauce to get started!',
                        style: TextStyle(fontSize: 15, color: Colors.white38),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  itemCount: _sauces.length,
                  itemBuilder: (context, index) {
                    final sauce = _sauces[index];
                    return Card(
                      color: cardColor,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: secondaryColor.withOpacity(0.18),
                          child: const Icon(Icons.local_pizza,
                              color: secondaryColor),
                        ),
                        title: Text(
                          sauce['name'],
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showSauceDialog(sauce: sauce),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: accentColor),
                              onPressed: () => _deleteSauce(sauce['id']),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSauceDialog(),
        icon: const Icon(Icons.add, color: textColor),
        label: const Text('Add Sauce', style: TextStyle(color: textColor)),
        backgroundColor: accentColor,
        elevation: 3,
      ),
    );
  }
}
