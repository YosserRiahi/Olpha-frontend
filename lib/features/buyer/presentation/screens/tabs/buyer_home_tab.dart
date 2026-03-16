import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/providers/auth_provider.dart';
import '../../../../../features/products/data/product_model.dart';
import '../../../../../features/products/providers/product_provider.dart';
import '../../../../../features/seller/presentation/screens/seller_dashboard_screen.dart'
    show kCategoryMeta;

class BuyerHomeTab extends ConsumerStatefulWidget {
  const BuyerHomeTab({super.key});

  @override
  ConsumerState<BuyerHomeTab> createState() => _BuyerHomeTabState();
}

class _BuyerHomeTabState extends ConsumerState<BuyerHomeTab> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    'All',
    'Jewelry',
    'Ceramics',
    'Textiles',
    'Leather',
    'Wood',
    'Candles',
    'Paintings',
    'Pottery',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final filter = AllProductsFilter(
      category: (_selectedCategory == null || _selectedCategory == 'All')
          ? null
          : _selectedCategory,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    final productsAsync = ref.watch(allProductsProvider(filter));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            expandedHeight: 130,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Olpha',
                            style: GoogleFonts.fredoka(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          // Notification icon placeholder
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Hi${user?.name != null ? ', ${user!.name}' : ''} 👋  Find something handcrafted',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppTheme.textDark),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search products…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFF9E9B97)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF9E9B97), size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF9E9B97)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // ── Category chips ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = (_selectedCategory ?? 'All') == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.primary
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppTheme.primary
                              : const Color(0xFFDDD9D4),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Section heading ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Newest Products',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  productsAsync.maybeWhen(
                    data: (list) => Text(
                      '${list.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9E9B97),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // ── Product grid ───────────────────────────────────────────────
          productsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 52, color: Colors.red.shade200),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load products',
                        style: GoogleFonts.fredoka(
                            fontSize: 18,
                            color: const Color(0xFFAEAA9F)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(allProductsProvider(filter)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (products) => products.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.search_off_rounded,
                                  size: 36,
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different category or search term.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF9E9B97),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _BuyerProductCard(
                            product: products[i]),
                        childCount: products.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Product card ───────────────────────────────────────────────────────────────
class _BuyerProductCard extends ConsumerWidget {
  final ProductModel product;
  const _BuyerProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(
        favoritesProvider.select((s) => s.contains(product.id)));
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
            // ── Image ────────────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product image
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

                  // Favorite button
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
                          color:
                              Colors.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFav
                              ? Colors.red.shade600
                              : const Color(0xFF9E9B97),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
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

                    // Price
                    Text(
                      '${product.price.toStringAsFixed(2)} TND',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),

                    // Shop chip
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
