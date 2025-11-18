import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';

class CreateLostFoundScreen extends StatelessWidget {
  const CreateLostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Create Report',
        showBackButton: true,
      ),
      body: Center(
        child: Text('Lost & Found Report Form - Coming Soon'),
      ),
    );
  }
}