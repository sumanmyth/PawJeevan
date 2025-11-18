import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Create Event',
        showBackButton: true,
      ),
      body: Center(
        child: Text('Event Creation Form - Coming Soon'),
      ),
    );
  }
}