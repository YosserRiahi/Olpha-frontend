import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/shops/providers/shop_provider.dart';
import '../../../../features/products/providers/product_provider.dart';
import '../../../../features/products/data/product_model.dart';

// ── Category icon map (shared across seller screens) ─────────────────────────
const Map<String, ({IconData icon, Color color})> kCategoryMeta = {
  'Jewelry':   (icon: Icons.diamond_outlined,               color: Color(0xFF7B61FF)),
  'Ceramics':  (icon: Icons.water_drop_outlined,            color: Color(0xFF0097A7)),
  'Textiles':  (icon: Icons.texture_outlined,               color: Color(0xFFE91E8C)),
  'Leather':   (icon: Icons.wallet_outlined,                color: Color(0xFF8D6E63)),
  'Wood':      (icon: Icons.forest_outlined,                color: Color(0xFF558B2F)),
  'Candles':   (icon: Icons.local_fire_department_outlined, color: Color(0xFFFF6F00)),
  'Paintings': (icon: Icons.palette_outlined,               color: Color(0xFFD32F2F)),
  'Pottery':   (icon: Icons.emoji_nature_outlined,          color: Color(0xFF5D4037)),
  'Other':     (icon: Icons.category_outlined,              color: Color(0xFF607D8B)),
};

// ── Sub-categories per store category ─────────────────────────────────────────
const Map<String, List<String>> kSubCategories = {
  'Jewelry':   ['Rings', 'Necklaces', 'Earrings', 'Bracelets', 'Anklets', 'Brooches', 'Sets'],
  'Ceramics':  ['Bowls', 'Plates', 'Mugs', 'Vases', 'Pots', 'Decorative', 'Tiles'],
  'Textiles':  ['Scarves', 'Rugs', 'Blankets', 'Cushions', 'Clothing', 'Bags', 'Table Linens'],
  'Leather':   ['Bags', 'Wallets', 'Belts', 'Shoes', 'Sandals', 'Accessories', 'Notebooks'],
  'Wood':      ['Furniture', 'Frames', 'Bowls', 'Toys', 'Sculptures', 'Kitchenware', 'Decorative'],
  'Candles':   ['Scented', 'Unscented', 'Pillar', 'Container', 'Floating', 'Beeswax', 'Soy'],
  'Paintings': ['Oil', 'Watercolor', 'Acrylic', 'Mixed Media', 'Calligraphy', 'Prints', 'Portraits'],
  'Pottery':   ['Bowls', 'Plates', 'Cups', 'Figurines', 'Sculptures', 'Vases', 'Decorative'],
  'Other':     ['Handmade', 'Art & Craft', 'Accessories', 'Home Decor', 'Gifts', 'Other'],
};

enum _Filter { all, active, hidden }

/// Products management tab (part of SellerShellScreen).
class SellerProductsTab extends ConsumerStatefulWidget {
  final VoidCallback onGoToHome;
  const SellerProductsTab({super.key, required this.onGoToHome});

  @override
  ConsumerState<SellerProductsTab> createState() => _SellerProductsTabState();
}

class _SellerProductsTabState extends ConsumerState<SellerProductsTab> {
  _Filter _filter = _Filter.all;

  List<ProductModel> _filtered(List<ProductModel> all) => switch (_filter) {
        _Filter.all    => all,
        _Filter.active => all.where((p) => p.isActive).toList(),
        _Filter.hidden => all.where((p) => !p.isActive).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final shopAsync     = ref.watch(myShopProvider);
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text(e.toString())),
        data: (shop) {
          if (shop == null) return _NoShopView(onGoToHome: widget.onGoToHome);
          return productsAsync.when(
            loading: () => _buildInventory(shop.name, [], loading: true),
            error:   (e, _) => _buildInventory(shop.name, [], error: e.toString()),
            data:    (products) => _buildInventory(shop.name, products),
          );
        },
      ),
    );
  }

  Widget _buildInventory(
    String shopName,
    List<ProductModel> products, {
    bool loading = false,
    String? error,
  }) {
    final filtered = _filtered(products);
    final total    = products.length;
    final active   = products.where((p) => p.isActive).length;
    final hidden   = total - active;

    return CustomScrollView(
      slivers: [
        // ── App bar ─────────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppTheme.primary,
          expandedHeight: 100,
          pinned: true,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => context.push('/seller-products/add'),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              tooltip: 'Add product',
            ),
            IconButton(
              onPressed: () => context.push('/seller-shop-edit'),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit shop',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Products',
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      shopName,
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
        ),

        // ── Stats + filter bar ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                // Stat cards row
                Row(
                  children: [
                    _StatCard(
                      label: 'Total',
                      value: total,
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Active',
                      value: active,
                      icon: Icons.visibility_outlined,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Hidden',
                      value: hidden,
                      icon: Icons.visibility_off_outlined,
                      color: Colors.orange.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter tabs with count badges
                Row(
                  children: _Filter.values.map((f) {
                    final count = switch (f) {
                      _Filter.all    => total,
                      _Filter.active => active,
                      _Filter.hidden => hidden,
                    };
                    final label = switch (f) {
                      _Filter.all    => 'All',
                      _Filter.active => 'Active',
                      _Filter.hidden => 'Hidden',
                    };
                    final sel = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : const Color(0xFFD0CCB8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF6B6761),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? Colors.white.withValues(alpha: 0.28)
                                      : const Color(0xFFEEEBE6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF6B6761),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 4),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF0EDE8)),
              ],
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────────
        if (loading)
          const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 52, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF9E9B97),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            child: _EmptyProducts(
              filter: _filter,
              onAdd: () => context.push('/seller-products/add'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ProductRow(product: filtered[i]),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── No-shop view ───────────────────────────────────────────────────────────────
class _NoShopView extends StatelessWidget {
  final VoidCallback onGoToHome;
  const _NoShopView({required this.onGoToHome});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.storefront_outlined,
                      size: 40,
                      color: AppTheme.primary.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 20),
                Text(
                  'No store yet',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your store on the Home tab\nto start adding products.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9E9B97),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: onGoToHome,
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text('Go to Home',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Product card ───────────────────────────────────────────────────────────────
class _ProductRow extends ConsumerWidget {
  final ProductModel product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = kCategoryMeta[product.category] ?? kCategoryMeta['Other']!;

    final Color stockColor;
    final String stockLabel;
    if (product.stock == 0) {
      stockColor = Colors.red.shade600;
      stockLabel = 'Out of stock';
    } else if (product.stock <= 5) {
      stockColor = const Color(0xFFE65100);
      stockLabel = 'Low: ${product.stock}';
    } else {
      stockColor = Colors.green.shade700;
      stockLabel = '${product.stock} in stock';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // ── Top content zone (tappable → edit) ────────────────────────
            InkWell(
              onTap: () =>
                  context.push('/seller-products/edit/${product.id}'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: product.imageUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrls.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _iconBox(meta),
                                errorWidget: (_, __, ___) => _iconBox(meta),
                              )
                            : _iconBox(meta),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info column
                    Expanded(
                      child: SizedBox(
                        height: 84,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Name + status pill
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _StatusPill(isActive: product.isActive),
                              ],
                            ),

                            // Category pill
                            _CategoryPill(
                                meta: meta,
                                label: product.category ?? 'Other'),

                            // Price
                            Text(
                              '${product.price.toStringAsFixed(2)} TND',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
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

            // ── Divider ──────────────────────────────────────────────────────
            const Divider(
                height: 1, thickness: 1, color: Color(0xFFF0EDE8)),

            // ── Action bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Stock badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: stockColor),
                        const SizedBox(width: 4),
                        Text(
                          stockLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Visibility toggle pill
                  GestureDetector(
                    onTap: () => ref
                        .read(myProductsProvider.notifier)
                        .toggleProduct(product.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: product.isActive
                            ? Colors.green.shade50
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: product.isActive
                              ? Colors.green.shade300
                              : const Color(0xFFDDDAD5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product.isActive
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 12,
                            color: product.isActive
                                ? Colors.green.shade700
                                : const Color(0xFF9E9B97),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isActive ? 'Active' : 'Hidden',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: product.isActive
                                  ? Colors.green.shade700
                                  : const Color(0xFF9E9B97),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Edit button
                  _CircleAction(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF7A7570),
                    onTap: () => context
                        .push('/seller-products/edit/${product.id}'),
                  ),
                  const SizedBox(width: 4),

                  // Delete button
                  _CircleAction(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                    bgColor: Colors.red.shade50,
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(({IconData icon, Color color}) meta) => Container(
        color: meta.color.withValues(alpha: 0.1),
        child: Center(child: Icon(meta.icon, color: meta.color, size: 30)),
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete product?',
          style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        content: Text(
          'Remove "${product.name}" from your shop?\nThis action cannot be undone.',
          style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B6761),
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E9B97))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(myProductsProvider.notifier)
          .deleteProduct(product.id);
    }
  }
}

// ── Status pill ────────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.green.shade200
                : Colors.orange.shade200,
          ),
        ),
        child: Text(
          isActive ? 'Active' : 'Hidden',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
        ),
      );
}

// ── Category pill ──────────────────────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  final ({IconData icon, Color color}) meta;
  final String label;
  const _CategoryPill({required this.meta, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meta.icon, size: 11, color: meta.color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: meta.color,
              ),
            ),
          ],
        ),
      );
}

// ── Circle action button ───────────────────────────────────────────────────────
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bgColor;
  final VoidCallback onTap;
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: bgColor ?? const Color(0xFFF5F4F2),
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      );
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: GoogleFonts.fredoka(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyProducts extends StatelessWidget {
  final VoidCallback onAdd;
  final _Filter filter;
  const _EmptyProducts({required this.onAdd, required this.filter});

  @override
  Widget build(BuildContext context) {
    final isFiltered = filter != _Filter.all;
    final title = isFiltered ? 'Nothing here' : 'No products yet';
    final message = switch (filter) {
      _Filter.active =>
        'No active products.\nToggle visibility on a card to show a product.',
      _Filter.hidden =>
        'No hidden products.\nAll your products are visible to buyers.',
      _Filter.all => 'Add your first product\nto start selling on Olpha.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_list_off_rounded
                    : Icons.inventory_2_outlined,
                size: 36,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF9E9B97),
                height: 1.55,
              ),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add product',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Public shared widgets (used by other screens) ─────────────────────────────

class SellerCategoryIconBox extends StatelessWidget {
  final ({IconData icon, Color color}) meta;
  const SellerCategoryIconBox({super.key, required this.meta});

  @override
  Widget build(BuildContext context) => Container(
        color: meta.color.withValues(alpha: 0.12),
        child: Center(child: Icon(meta.icon, color: meta.color, size: 32)),
      );
}

class SellerStatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;
  const SellerStatChip(
      {super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD0CCB8)),
        ),
        child: Text(
          '$label: $value',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color ?? AppTheme.textDark,
          ),
        ),
      );
}
