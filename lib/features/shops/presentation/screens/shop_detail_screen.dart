import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/product_model.dart';
import '../../../products/providers/product_provider.dart';
import '../../providers/shop_provider.dart';

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(shopId));
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFCCC8C4)),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: GoogleFonts.poppins(color: const Color(0xFF9E9B97))),
              TextButton(
                onPressed: () => ref.invalidate(shopByIdProvider(shopId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (shop) => CustomScrollView(
          slivers: [
            // ── Banner + back button ──────────────────────────────────
            SliverAppBar(
              backgroundColor: AppTheme.primary,
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: shop.bannerUrl != null
                    ? Image.network(shop.bannerUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bannerPlaceholder())
                    : _bannerPlaceholder(),
              ),
            ),

            // ── Shop info ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (shop.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Color(0xFF9E9B97)),
                          const SizedBox(width: 4),
                          Text(
                            shop.location!,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: const Color(0xFF9E9B97)),
                          ),
                        ],
                      ),
                    ],
                    if (shop.category != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shop.category!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (shop.description != null && shop.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        shop.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF7A7570),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Products section heading ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Products',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),

            // ── Products ──────────────────────────────────────────────
            productsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Failed to load products',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: const Color(0xFF9E9B97)),
                    ),
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 48, color: Color(0xFFCCC8C4)),
                            const SizedBox(height: 12),
                            Text(
                              'No products yet',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                color: const Color(0xFFAEAA9F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This shop hasn\'t added any products yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFFAEAA9F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ProductCard(product: products[i]),
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.storefront_outlined,
            size: 56, color: Colors.white54),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrls.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: product.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(color: const Color(0xFFF0EDE8)),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(2)} TND',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (product.stock > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.stock} left',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE9E7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Out of stock',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0EDE8),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 36, color: Color(0xFFCCC8C4)),
      ),
    );
  }
}
