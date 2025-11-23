import 'package:flutter/material.dart';

/// Full Screen Image Viewer with pinch-to-zoom functionality.
///
/// Shows the image using `BoxFit.contain` by default so the whole image is visible.
/// When the user zooms (scale > 1.0) the viewer switches to `BoxFit.cover` and
/// keeps the image sized to the screen so the zoomed image fully covers the display.
class FullScreenImage extends StatefulWidget {
  final String imageUrl;
  final String? title; // optional title to show in an AppBar
  final String? heroTag; // optional hero tag to match source Hero

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    this.title,
    this.heroTag,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    // Matrix4 stores scale on the diagonal; we take the max axis scale.
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.0 + 1e-3; // tiny epsilon to avoid flicker
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the interactive viewer content once and reuse inside either a
    // plain Scaffold (no AppBar) or a Scaffold with an AppBar when a title is set.
    final viewer = GestureDetector(
      onTap: () {
        if (_isZoomed) {
          _transformationController.value = Matrix4.identity();
        } else {
          Navigator.pop(context);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Hero(
                tag: widget.heroTag ?? 'pet_photo_${widget.imageUrl.hashCode}',
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 6.0,
                  panEnabled: true,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.title == null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.title != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.title!),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: viewer,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: viewer,
    );
  }
}
