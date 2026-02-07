import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/store_service.dart';
import '../../utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ProductReviewsScreen extends StatefulWidget {
  final int productId;
  final String? productName;
  const ProductReviewsScreen(
      {super.key, required this.productId, this.productName});

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];
  int? _filterRating;
  final Set<int> _voted = {}; // local set of review ids the user just voted for

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      _reviews = await _store.fetchReviewsForProduct(widget.productId);
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to load reviews: $e');
      }
      _reviews = [];
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _markHelpful(int reviewId, int index) async {
    try {
      final res = await _store.markReviewHelpful(reviewId);
      if (res != null) {
        final count = res['helpful_count'] as int? ?? 0;
        final marked = res['marked'] == true;
        if (!mounted) return;
        setState(() {
          _reviews[index]['helpful_count'] = count;
          _reviews[index]['helpful_given'] = marked;
          if (marked) {
            _voted.add(reviewId);
          } else {
            _voted.remove(reviewId);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to toggle helpful: $e');
    }
  }

  List<Map<String, dynamic>> _visibleReviews() {
    if (_filterRating == null) return _reviews;
    return _reviews.where((r) {
      final rating = r['rating'] is int
          ? r['rating'] as int
          : int.tryParse(r['rating']?.toString() ?? '') ?? 0;
      return rating == _filterRating;
    }).toList();
  }

  Widget _buildFilterChips() {
    final counts = <int, int>{};
    for (var i = 1; i <= 5; i++) {
      counts[i] = 0;
    }
    for (var r in _reviews) {
      final rating = r['rating'] is int
          ? r['rating'] as int
          : int.tryParse(r['rating']?.toString() ?? '') ?? 0;
      if (rating >= 1 && rating <= 5) {
        counts[rating] = (counts[rating] ?? 0) + 1;
      }
    }

    List<Widget> chips = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedLabelColor = isDark ? Colors.white70 : Colors.black87;

    chips.add(Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text('All (${_reviews.length})'),
        selected: _filterRating == null,
        onSelected: (_) => setState(() => _filterRating = null),
        selectedColor: const Color(0xFF7C3AED),
        labelStyle: TextStyle(
            color: _filterRating == null ? Colors.white : unselectedLabelColor),
      ),
    ));

    for (var i = 5; i >= 1; i--) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ChoiceChip(
          label: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$i'),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 6),
            Text('(${counts[i]})', style: const TextStyle(fontSize: 12))
          ]),
          selected: _filterRating == i,
          onSelected: (_) => setState(() => _filterRating = i),
          selectedColor: const Color(0xFF7C3AED),
          labelStyle: TextStyle(
              color: _filterRating == i ? Colors.white : unselectedLabelColor),
        ),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: chips),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(i < rating ? Icons.star : Icons.star_border,
            size: 18, color: Colors.amber);
      }),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> r, int idx, AuthProvider auth) {
    // product field intentionally unused here (kept for future use)
    final title = r['title'] ?? '';
    final comment = r['comment'] ?? '';
    final rating = r['rating'] is int
        ? r['rating'] as int
        : int.tryParse(r['rating']?.toString() ?? '') ?? 0;
    final helpful = r['helpful_count'] is int
        ? r['helpful_count'] as int
        : int.tryParse(r['helpful_count']?.toString() ?? '') ?? 0;
    final helpfulGiven = r['helpful_given'] == true || _voted.contains(r['id']);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final commentColor = isDark ? Colors.white70 : Colors.black87;
    final metaColor = isDark ? Colors.white54 : Colors.black54;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStars(rating),
                const SizedBox(width: 8),
                if (title.isNotEmpty)
                  Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: titleColor)))
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment, style: TextStyle(color: commentColor)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Helpful: $helpful', style: TextStyle(color: metaColor)),
                const SizedBox(width: 12),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    if (!auth.isAuthenticated) {
                      Helpers.showSnackBar(
                          context, 'Please login to mark helpful');
                      return;
                    }
                    _markHelpful(r['id'] as int, idx);
                  },
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: Text(helpfulGiven ? 'Marked' : 'Helpful'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: helpfulGiven
                        ? const Color(0xFF6B46C1)
                        : const Color(0xFF7C3AED),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.productName ?? 'Reviews';
    final auth = Provider.of<AuthProvider>(context);
    final visible = _visibleReviews();

    return Scaffold(
      appBar: CustomAppBar(title: title, showBackButton: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilterChips(),
                  if (visible.isEmpty)
                    Expanded(
                      child: ListView(children: const [
                        SizedBox(height: 40),
                        Center(child: Text('No reviews found.'))
                      ]),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 0, bottom: 20),
                        itemCount: visible.length,
                        itemBuilder: (context, idx) =>
                            _buildReviewTile(visible[idx], idx, auth),
                      ),
                    )
                ],
              ),
      ),
    );
  }
}
