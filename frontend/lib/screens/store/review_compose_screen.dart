import 'package:flutter/material.dart';
import '../../services/store_service.dart';
// removed unused imports: custom_app_bar and helpers

class ReviewComposeScreen extends StatefulWidget {
  final int productId;
  final int? reviewId; // if provided, composer is in edit mode
  final int? initialRating;
  final String? initialTitle;
  final String? initialComment;

  const ReviewComposeScreen({
    super.key,
    required this.productId,
    this.reviewId,
    this.initialRating,
    this.initialTitle,
    this.initialComment,
  });

  @override
  State<ReviewComposeScreen> createState() => _ReviewComposeScreenState();
}

class _ReviewComposeScreenState extends State<ReviewComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final StoreService _store = StoreService();
  int _rating = 5;
  final TextEditingController _titleCtl = TextEditingController();
  final TextEditingController _commentCtl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtl.dispose();
    _commentCtl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialRating != null) _rating = widget.initialRating!;
    if (widget.initialTitle != null) _titleCtl.text = widget.initialTitle!;
    if (widget.initialComment != null)
      _commentCtl.text = widget.initialComment!;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      Map<String, dynamic>? result;
      if (widget.reviewId != null) {
        result = await _store.updateReview(
          reviewId: widget.reviewId!,
          rating: _rating,
          title: _titleCtl.text.trim(),
          comment: _commentCtl.text.trim(),
        );
      } else {
        result = await _store.createReview(
          productId: widget.productId,
          rating: _rating,
          title: _titleCtl.text.trim(),
          comment: _commentCtl.text.trim(),
        );
      }

      if (result != null) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit review')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _star(int i) {
    final filled = i <= _rating;
    return IconButton(
      onPressed: () => setState(() => _rating = i),
      icon: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
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
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        right: -60,
                        top: -40,
                        child: Opacity(
                          opacity: 0.05,
                          child:
                              Icon(Icons.pets, size: 180, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color.fromRGBO(124, 58, 237, 0.85)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.rate_review,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('Write a review',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Rating',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Row(
                                      children: List.generate(
                                          5, (index) => _star(index + 1))),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _titleCtl,
                                    decoration: InputDecoration(
                                      labelText: 'Title (short summary)',
                                      labelStyle: TextStyle(
                                          color:
                                              isDark ? Colors.grey[300] : null),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.grey[700]!
                                                : Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color.fromRGBO(
                                                124, 58, 237, 1.0),
                                            width: 2),
                                      ),
                                      prefixIcon: const Icon(
                                          Icons.title_outlined,
                                          color: Color(0xFF7C3AED)),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[50],
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Please enter a title'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 200,
                                    child: TextFormField(
                                      controller: _commentCtl,
                                      decoration: InputDecoration(
                                        hintText: 'Write your review',
                                        alignLabelWithHint: true,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: isDark
                                                  ? Colors.grey[700]!
                                                  : Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Color.fromRGBO(
                                                  124, 58, 237, 1.0),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                      expands: false,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Please add a comment'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _submitting ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7C3AED),
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: const Color.fromRGBO(
                                            124, 58, 237, 0.4),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: _submitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text('Submit review',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward,
                                                    size: 18),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Color(0xFF7C3AED)),
                                        foregroundColor:
                                            const Color(0xFF7C3AED),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Back',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
