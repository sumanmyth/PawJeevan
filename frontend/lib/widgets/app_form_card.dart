import 'package:flutter/material.dart';

class AppFormCard extends StatefulWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool animate;
  final Duration duration;

  const AppFormCard({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding,
    this.animate = true,
    this.duration = const Duration(milliseconds: 360),
  });

  @override
  State<AppFormCard> createState() => _AppFormCardState();
}

class _AppFormCardState extends State<AppFormCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    if (widget.animate) {
      // small delay to allow build to complete for smoother animation
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color.fromRGBO(124, 58, 237, 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: widget.padding ?? const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    right: -50,
                    top: -30,
                    child: Opacity(
                      opacity: 0.05,
                      child: Icon(
                        Icons.pets,
                        size: 160,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: -40,
                    bottom: 50,
                    child: Opacity(
                      opacity: 0.05,
                      child: Icon(
                        Icons.pets,
                        size: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.2),
                              blurRadius: 30,
                              offset: Offset(0, 15),
                            ),
                          ],
                        ),
                        child: widget.child,
                      ),
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
}
