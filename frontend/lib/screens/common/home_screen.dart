import 'package:flutter/material.dart';
import '../../widgets/notification_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PawJeevan'),
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.shopping_cart,
                  label: 'Shop',
                  color: Colors.blue.shade100,
                  onTap: () {
                    // Navigate to shop
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.camera_alt,
                  label: 'Scan Pet',
                  color: Colors.green.shade100,
                  onTap: () {
                    // Navigate to scan pet
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble,
                  label: 'AI Chat',
                  color: Colors.orange.shade100,
                  onTap: () {
                    // Navigate to AI chat
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.people,
                  label: 'Community',
                  color: Colors.pink.shade100,
                  onTap: () {
                    // Navigate to community
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}