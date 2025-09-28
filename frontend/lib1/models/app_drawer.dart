import 'package:flutter/material.dart';
import 'package:hackathon/about_page.dart';
import 'package:hackathon/product_comparison_page.dart';
import 'package:hackathon/product_history_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _goTo(BuildContext context, Widget page) {
    Navigator.pop(context); // close drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      surfaceTintColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            height: 155,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Color.fromRGBO(3, 63, 99, 1)),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.only(left: 20, top: 30),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Product Comparison'),
            onTap: () => _goTo(context, const ProductComparisonPage()),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Product History'),
            onTap: () => _goTo(context, const ProductHistoryPage()),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () => _goTo(context, const AboutPage()),
              ),
        ],
      ),
    );
  }
}
