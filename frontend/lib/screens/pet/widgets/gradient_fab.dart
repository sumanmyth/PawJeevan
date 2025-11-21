import 'package:flutter/material.dart';

/// Gradient styled Floating Action Button
class GradientFab extends StatelessWidget {
  final VoidCallback? onPressed;

  const GradientFab({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA), Color(0xFFB794F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
