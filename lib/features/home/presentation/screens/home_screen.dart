import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/shops/providers/shop_provider.dart';
import '../../../../features/shops/data/shop_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    'All', 'Jewelry', 'Ceramics', 'Textiles', 'Leather',
    'Wood', 'Candles', 'Paintings', 'Pottery',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final filter = ShopsFilter(
      category: (_selectedCategory == null || _selectedCategory == 'All')
          ? null
          : _selectedCategory,
    );
    final shopsAsync = ref.watch(shopsProvider(filter));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.favorite_border_rounded,
                                color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.shopping_cart_outlined,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hi${user?.name != null ? ', ${user!.name}' : ''} 👋 Find something handcrafted',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
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
                  controller: _searchController,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
                  onSubmitted: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search shops & crafts…',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFF9E9B97)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF9E9B97), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF9E9B97)),
                            onPressed: () {
                              _searchController.clear();
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

          // ── Category chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = (_selectedCategory ?? 'All') == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : const Color(0xFFDDD9D4),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Section heading ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Featured Shops',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Shop grid ────────────────────────────────────────────────
          shopsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 48, color: Color(0xFFCCC8C4)),
                    const SizedBox(height: 12),
                    Text('Could not load shops',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF9E9B97))),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(shopsProvider(filter)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (shops) => shops.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 56, color: Color(0xFFCCC8C4)),
                          const SizedBox(height: 12),
                          Text(
                            'No shops yet',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              color: const Color(0xFFAEAA9F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to open one!',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFFAEAA9F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _ShopCard(shop: shops[i]),
                        childCount: shops.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Shop card widget ─────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final ShopModel shop;

  const _ShopCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shops/${shop.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner / placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: shop.bannerUrl != null
                  ? Image.network(
                      shop.bannerUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _shopPlaceholder(),
                    )
                  : _shopPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (shop.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF9E9B97)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            shop.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: const Color(0xFF9E9B97)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (shop.category != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shop.category!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopPlaceholder() {
    return Container(
      height: 110,
      width: double.infinity,
      color: AppTheme.background,
      child: const Icon(Icons.storefront_outlined,
          size: 36, color: Color(0xFFCCC8C4)),
    );
  }
}
