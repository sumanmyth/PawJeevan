import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () {
          if (!notification.isRead) {
            context
                .read<NotificationProvider>()
                .markAsRead(notification.id);
          }
          // Handle notification tap based on type
          // TODO: Implement navigation based on notification type
        },
        leading: _getIcon(),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.1),
      ),
    );
  }

  Widget _getIcon() {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case 'vaccination':
        iconData = Icons.vaccines;
        color = Colors.blue;
        break;
      case 'food_restock':
        iconData = Icons.food_bank;
        color = Colors.orange;
        break;
      case 'vet_checkup':
        iconData = Icons.medical_services;
        color = Colors.red;
        break;
      case 'order':
        iconData = Icons.shopping_bag;
        color = Colors.green;
        break;
      case 'community':
        iconData = Icons.people;
        color = Colors.purple;
        break;
      case 'message':
        iconData = Icons.message;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }
}