import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserListTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
        child: user.avatar == null ? Text(user.username[0].toUpperCase()) : null,
      ),
      title: Text(user.username),
      subtitle: (user.firstName?.isNotEmpty == true || user.lastName?.isNotEmpty == true) 
          ? Text('${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()) 
          : null,
      onTap: onTap,
    );
  }
}