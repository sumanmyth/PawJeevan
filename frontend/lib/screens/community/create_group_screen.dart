import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Create Group',
        showBackButton: true,
      ),
      body: Center(
        child: Text('Group Creation Form - Coming Soon'),
      ),
    );
  }
}