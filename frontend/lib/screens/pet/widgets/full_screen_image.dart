import 'package:flutter/material.dart';

/// Full Screen Image Viewer with pinch-to-zoom functionality.
///
/// Shows the image using `BoxFit.contain` by default so the whole image is visible.
/// When the user zooms (scale > 1.0) the viewer switches to `BoxFit.cover` and
/// keeps the image sized to the screen so the zoomed image fully covers the display.
class FullScreenImage extends StatefulWidget {
  // Support either a single `imageUrl` (backwards compatible) or a list of `images`.
  final List<String> images;
  final int initialIndex;
  final String? title; // optional title to show in an AppBar
  // Optional hero information: if provided, `heroTag` will be applied to the
  // page at `heroIndex` so the opening Hero animation works for that image.
  final String? heroTag;
  final int? heroIndex;

  FullScreenImage({
    super.key,
    String? imageUrl,
    List<String>? images,
    this.initialIndex = 0,
    this.title,
    this.heroTag,
    this.heroIndex,
  }) : images = images ?? (imageUrl != null ? [imageUrl] : <String>[]);

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late final PageController _pageController;
  late final List<TransformationController> _transformationControllers;
  bool _isZoomed = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.isNotEmpty ? widget.images.length - 1 : 0);
    _pageController = PageController(initialPage: _currentIndex);
    _transformationControllers = List.generate(widget.images.length, (_) => TransformationController());
    // Listen for the active page's transform changes
    if (_transformationControllers.isNotEmpty) {
      _transformationControllers[_currentIndex].addListener(_onTransformChanged);
    }
  }

  void _onTransformChanged() {
    // Matrix4 stores scale on the diagonal; we take the max axis scale.
    final ctrl = _transformationControllers[_currentIndex];
    final scale = ctrl.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.0 + 1e-3; // tiny epsilon to avoid flicker
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    // remove listeners and dispose controllers
    if (_transformationControllers.isNotEmpty) {
      for (final c in _transformationControllers) {
        c.removeListener(_onTransformChanged);
        c.dispose();
      }
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the interactive viewer content once and reuse inside either a
    // plain Scaffold (no AppBar) or a Scaffold with an AppBar when a title is set.
    // Note: do not close the viewer on a single tap of the image because
    // taps are used for interacting with the image (zoom/pan) and users
    // expect taps not to immediately dismiss the fullscreen viewer. The
    // close button in the top-right remains available. If the image is
    // zoomed, a tap will reset the zoom to identity.
    final viewer = GestureDetector(
      onTap: () {
        if (_isZoomed) {
          // reset current page's transform
          _transformationControllers[_currentIndex].value = Matrix4.identity();
        }
        // otherwise: do nothing (do not pop on single tap)
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (idx) {
                  // remove listener from previous and add to new
                  if (_transformationControllers.isNotEmpty) {
                    _transformationControllers[_currentIndex].removeListener(_onTransformChanged);
                    _transformationControllers[_currentIndex].value = Matrix4.identity();
                    _transformationControllers[idx].addListener(_onTransformChanged);
                  }
                  setState(() {
                    _currentIndex = idx;
                    _isZoomed = false;
                  });
                },
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final imageUrl = widget.images[index];
                  final isHero = (widget.heroTag != null && widget.heroIndex != null && widget.heroIndex == index);
                  Widget content = InteractiveViewer(
                    transformationController: _transformationControllers[index],
                    minScale: 0.5,
                    maxScale: 6.0,
                    panEnabled: true,
                    clipBehavior: Clip.none,
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        imageUrl,
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
                  );

                  if (isHero) {
                    content = Hero(tag: widget.heroTag!, child: content);
                  }

                  return content;
                },
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
          // Page indicator overlay (bottom center) for multi-image viewers
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.images.length, (i) {
                      final active = i == _currentIndex;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // jump to tapped page
                          if (_pageController.hasClients) {
                            _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else {
                            _pageController.jumpToPage(i);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 12 : 10,
                            height: active ? 12 : 10,
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF7C3AED) : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white70),
                            ),
                          ),
                        ),
                      );
                    }),
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
