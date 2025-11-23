import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/user/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_app_bar.dart';

/// Helper class for notification icon and color mapping
class NotificationTypeHelper {
  static IconData getIcon(String type) {
    switch (type) {
      case 'vaccination':
        return Icons.vaccines;
      case 'food_restock':
        return Icons.food_bank;
      case 'vet_checkup':
        return Icons.medical_services;
      case 'order':
        return Icons.shopping_bag;
      case 'community':
        return Icons.people;
      case 'message':
        return Icons.message;
      case 'event_joined':
        return Icons.event;
      case 'event_starting':
        return Icons.event_available;
      case 'event_ended':
        return Icons.event_busy;
      default:
        return Icons.notifications;
    }
  }

  static Color getColor(String type) {
    switch (type) {
      case 'vaccination':
        return Colors.blue;
      case 'food_restock':
        return Colors.orange;
      case 'vet_checkup':
        return Colors.red;
      case 'order':
        return Colors.green;
      case 'community':
        return Colors.purple;
      case 'message':
        return Colors.blue;
      case 'event_joined':
        return Colors.green;
      case 'event_starting':
        return Colors.orange;
      case 'event_ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// Notification bell icon with unread count badge
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    provider.unreadCount <= 99 
                        ? '${provider.unreadCount}' 
                        : '99+',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
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
              padding: EdgeInsets.only(top: topPadding + 8, left: 8, right: 8, bottom: 8),
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
    // Check if this is an event notification with deleted event
    final isEventNotification = notification.type.startsWith('event_');
    final eventDeleted = isEventNotification && 
                        (notification.type == 'event_ended' || 
                         notification.message.contains('ended') ||
                         notification.message.contains('enjoyed'));

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Notification'),
              content: const Text('Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await context.read<NotificationProvider>().deleteNotification(notification.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification deleted')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete notification')),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: () {
            if (!notification.isRead) {
              context
                  .read<NotificationProvider>()
                  .markAsRead(notification.id);
            }
            // Handle notification tap based on type
            // Don't navigate if event is deleted
            if (!eventDeleted) {
              // TODO: Implement navigation based on notification type
            }
          },
          leading: _getIcon(),
          title: Row(
            children: [
              Expanded(child: Text(notification.title)),
              if (eventDeleted)
                const Chip(
                  label: Text('Event Ended', style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.grey,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
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
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Notification'),
                    content: const Text('Are you sure you want to delete this notification?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true && context.mounted) {
                try {
                  await context.read<NotificationProvider>().deleteNotification(notification.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete notification')),
                    );
                  }
                }
              }
            },
          ),
          tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _getIcon() {
    final iconData = NotificationTypeHelper.getIcon(notification.type);
    final color = NotificationTypeHelper.getColor(notification.type);

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }
}