import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../data/product_model.dart';
import '../../../seller/presentation/screens/seller_dashboard_screen.dart'
    show kCategoryMeta;

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync =
        ref.watch(productByIdProvider(widget.productId));
    final isFav = ref.watch(
        favoritesProvider.select((s) => s.contains(widget.productId)));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString().replaceFirst('Exception: ', ''),
          onBack: () => context.pop(),
        ),
        data: (product) => _Body(
          product: product,
          imageIndex: _imageIndex,
          isFav: isFav,
          onImageChanged: (i) => setState(() => _imageIndex = i),
          onToggleFav: () => ref
              .read(favoritesProvider.notifier)
              .toggle(product.id),
        ),
      ),
    );
  }
}

// ── Main body ────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final ProductModel product;
  final int imageIndex;
  final bool isFav;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onToggleFav;

  const _Body({
    required this.product,
    required this.imageIndex,
    required this.isFav,
    required this.onImageChanged,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    final meta =
        kCategoryMeta[product.category] ?? kCategoryMeta['Other']!;
    final hasImages = product.imageUrls.isNotEmpty;
    final currentImage =
        hasImages ? product.imageUrls[imageIndex] : null;

    return CustomScrollView(
      slivers: [
        // ── Hero image app bar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppTheme.primary,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red.shade400 : Colors.white,
                    size: 20,
                  ),
                  onPressed: onToggleFav,
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                currentImage != null
                    ? CachedNetworkImage(
                        imageUrl: currentImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: meta.color.withValues(alpha: 0.15),
                          child: Center(
                            child: Icon(meta.icon,
                                color: meta.color, size: 48),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: meta.color.withValues(alpha: 0.15),
                          child: Center(
                            child: Icon(meta.icon,
                                color: meta.color, size: 48),
                          ),
                        ),
                      )
                    : Container(
                        color: meta.color.withValues(alpha: 0.15),
                        child: Center(
                          child: Icon(meta.icon,
                              color: meta.color, size: 48),
                        ),
                      ),

                // Gradient overlay at bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),

                // Image dots (if multiple images)
                if (product.imageUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.imageUrls.length,
                        (i) => GestureDetector(
                          onTap: () => onImageChanged(i),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: i == imageIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == imageIndex
                                  ? Colors.white
                                  : Colors.white
                                      .withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Product info card ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2C2B2A).withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.price.toStringAsFixed(2)} TND',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Chips row: category + stock
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Category
                    if (product.category != null)
                      _Chip(
                        icon: meta.icon,
                        label: product.category!,
                        iconColor: meta.color,
                        bgColor: meta.color.withValues(alpha: 0.1),
                        textColor: meta.color,
                      ),
                    // Stock
                    _StockChip(stock: product.stock),
                  ],
                ),

                // Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0EDE9)),
                  const SizedBox(height: 12),
                  Text(
                    'About this product',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B6864),
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Thumbnail strip (if multiple images) ────────────────────────
        if (product.imageUrls.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.imageUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = i == imageIndex;
                    return GestureDetector(
                      onTap: () => onImageChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrls[i],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // ── Shop card ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2C2B2A).withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppTheme.primary.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sold by',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF9E9B97),
                        ),
                      ),
                      Text(
                        product.shopName ?? 'Artisan Shop',
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () =>
                      context.push('/shops/${product.shopId}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Visit Shop',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom padding ───────────────────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

}

// ── Chip widgets ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final Color textColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final int stock;
  const _StockChip({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (stock == 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade600;
      label = 'Out of stock';
    } else if (stock <= 5) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = 'Only $stock left';
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = '$stock in stock';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Error body ───────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorBody({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 52, color: Colors.red.shade200),
            const SizedBox(height: 16),
            Text(
              'Product not found',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: const Color(0xFF9E9B97)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
