import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/products/providers/product_provider.dart';
import '../../../../../features/products/data/product_model.dart';
import '../../../../../features/seller/presentation/screens/seller_dashboard_screen.dart'
    show kCategoryMeta;

class BuyerFavoritesTab extends ConsumerWidget {
  const BuyerFavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            pinned: true,
            automaticallyImplyLeading: false,
            elevation: 0,
            title: Text(
              'My Favorites',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              if (favoriteIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${favoriteIds.length} saved',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Content ───────────────────────────────────────────────────────
          if (favoriteIds.isEmpty)
            SliverFillRemaining(
              child: _EmptyFavorites(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final id = favoriteIds.elementAt(i);
                    return _FavoriteProductCard(productId: id);
                  },
                  childCount: favoriteIds.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No favorites yet',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the ♥ on any product to save\nit here for later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9E9B97),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite product card ────────────────────────────────────────────────────
class _FavoriteProductCard extends ConsumerWidget {
  final String productId;
  const _FavoriteProductCard({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => _CardSkeleton(),
      error: (_, __) => _CardError(
        onRemove: () =>
            ref.read(favoritesProvider.notifier).toggle(productId),
      ),
      data: (product) => _ProductCard(product: product, ref: ref),
    );
  }
}

// ── Loaded product card ─────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final WidgetRef ref;
  const _ProductCard({required this.product, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta =
        kCategoryMeta[product.category] ?? kCategoryMeta['Other']!;

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C2B2A).withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: meta.color.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(meta.icon,
                                  color: meta.color, size: 32),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: meta.color.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(meta.icon,
                                  color: meta.color, size: 32),
                            ),
                          ),
                        )
                      : Container(
                          color: meta.color.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(meta.icon,
                                color: meta.color, size: 32),
                          ),
                        ),

                  // Remove from favorites
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(product.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(2)} TND',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (product.shopName != null)
                      GestureDetector(
                        onTap: () =>
                            context.push('/shops/${product.shopId}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 11,
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.7)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  product.shopName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton card (loading) ──────────────────────────────────────────────────
class _CardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2B2A).withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFFF0EDE9),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card ───────────────────────────────────────────────────────────────
class _CardError extends StatelessWidget {
  final VoidCallback onRemove;
  const _CardError({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD9D4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Unavailable',
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                textStyle:
                    GoogleFonts.poppins(fontSize: 11)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
