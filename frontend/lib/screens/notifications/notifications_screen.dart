import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui' as ui;

import '../../models/user/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/helpers.dart';

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
        return const Color(0xFF7C3AED);
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade700 : Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirm(context);
      },
      onDismissed: (direction) async {
                                  try {
                                    await context.read<NotificationProvider>().deleteNotification(notification.id);
                                    if (context.mounted) {
                                      Helpers.showInstantSnackBar(
                                        context,
                                        const SnackBar(content: Text('Notification deleted')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Helpers.showInstantSnackBar(
                                        context,
                                        const SnackBar(content: Text('Failed to delete notification')),
                                      );
                                    }
                                  }
      },
        child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.6)
                  : Colors.black.withOpacity(0.04),
              blurRadius: Theme.of(context).brightness == Brightness.dark ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF7C3AED).withOpacity(0.18)
                    : const Color(0xFF7C3AED).withOpacity(0.08)),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (!notification.isRead) {
                context.read<NotificationProvider>().markAsRead(notification.id);
              }
              if (!eventDeleted) {
                // TODO: Implement navigation based on notification type
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent column with circular icon
                    Container(
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      child: _getIconUpdated(context), // Using updated icon method
                    ),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  notification.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ) ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                            ),
                            if (eventDeleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Event Ended', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                              ) ?? TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              timeago.format(notification.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirm(context);

                                if (confirm == true && context.mounted) {
                                    try {
                                      await context.read<NotificationProvider>().deleteNotification(notification.id);
                                      if (context.mounted) {
                                        Helpers.showInstantSnackBar(
                                          context,
                                          const SnackBar(content: Text('Notification deleted')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Helpers.showInstantSnackBar(
                                          context,
                                          const SnackBar(content: Text('Failed to delete notification')),
                                        );
                                      }
                                    }
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    // Use showGeneralDialog so we can blur the background behind the dialog
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Notification',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(false),
          child: SafeArea(
            child: Stack(
              children: [
                // Full-screen backdrop filter
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Material(
                      color: Theme.of(ctx).dialogBackgroundColor,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delete Notification', style: Theme.of(ctx).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            const Text('Are you sure you want to delete this notification?'),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text('Cancel', style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _getIconUpdated(BuildContext context) {
    final iconData = NotificationTypeHelper.getIcon(notification.type);
    final color = NotificationTypeHelper.getColor(notification.type);

    // Make gradient a bit stronger in dark mode so it reads against dark background
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final startOpacity = dark ? 0.18 : 0.14;
    final endOpacity = dark ? 0.42 : 0.34;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(startOpacity), color.withOpacity(endOpacity)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(iconData, color: dark ? Colors.white : color, size: 20)),
    );
  }
}