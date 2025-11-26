import 'package:flutter/material.dart';

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    Widget line(double width, {double height = 12}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 0,
        color: isDark ? Colors.black12 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        line(double.infinity, height: 14),
                        const SizedBox(height: 8),
                        line(MediaQuery.of(context).size.width * 0.4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Large image placeholder
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              line(double.infinity),
              const SizedBox(height: 8),
              Row(
                children: [
                  line(80),
                  const SizedBox(width: 8),
                  line(80),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
