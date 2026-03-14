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
  'Jewelry':    (icon: Icons.diamond_outlined,        color: Color(0xFF7B61FF)),
  'Ceramics':   (icon: Icons.water_drop_outlined,     color: Color(0xFF0097A7)),
  'Textiles':   (icon: Icons.texture_outlined,        color: Color(0xFFE91E8C)),
  'Leather':    (icon: Icons.wallet_outlined,         color: Color(0xFF8D6E63)),
  'Wood':       (icon: Icons.forest_outlined,         color: Color(0xFF558B2F)),
  'Candles':    (icon: Icons.local_fire_department_outlined, color: Color(0xFFFF6F00)),
  'Paintings':  (icon: Icons.palette_outlined,        color: Color(0xFFD32F2F)),
  'Pottery':    (icon: Icons.emoji_nature_outlined,   color: Color(0xFF5D4037)),
  'Other':      (icon: Icons.category_outlined,       color: Color(0xFF607D8B)),
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
    final shopAsync = ref.watch(myShopProvider);
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (shop) {
          if (shop == null) {
            return _NoShopView(onGoToHome: widget.onGoToHome);
          }
          return productsAsync.when(
            loading: () => _buildInventory(shop.name, [], loading: true),
            error: (e, _) => _buildInventory(shop.name, [], error: e.toString()),
            data: (products) => _buildInventory(shop.name, products),
          );
        },
      ),
      floatingActionButton: shopAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => context.push('/seller-products/add'),
              icon: const Icon(Icons.add_rounded),
              label: Text('New Product',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildInventory(
    String shopName,
    List<ProductModel> products, {
    bool loading = false,
    String? error,
  }) {
    final filtered = _filtered(products);
    final total  = products.length;
    final active = products.where((p) => p.isActive).length;
    final hidden = total - active;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.primary,
          expandedHeight: 100,
          pinned: true,
          automaticallyImplyLeading: false,
          actions: [
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
                    Text('Products',
                        style: GoogleFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    Text(shopName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            color: AppTheme.primary.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    SellerStatChip(label: 'Total',  value: total),
                    const SizedBox(width: 8),
                    SellerStatChip(label: 'Active', value: active, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    SellerStatChip(label: 'Hidden', value: hidden, color: Colors.orange.shade700),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: _Filter.values.map((f) {
                    final label = switch (f) {
                      _Filter.all    => 'All',
                      _Filter.active => 'Active',
                      _Filter.hidden => 'Hidden',
                    };
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? AppTheme.primary : const Color(0xFFD0CCB8),
                            ),
                          ),
                          child: Text(label,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selected ? Colors.white : const Color(0xFF6B6761),
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        if (loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          SliverFillRemaining(
            child: Center(child: Text(error, style: GoogleFonts.poppins(color: Colors.red))),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(child: _EmptyProducts(onAdd: () => context.push('/seller-products/add')))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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

// ── No-shop view for products tab ─────────────────────────────────────────────
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
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: AppTheme.primary.withValues(alpha: 0.35)),
                const SizedBox(height: 20),
                Text('No store yet',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    )),
                const SizedBox(height: 8),
                Text(
                  'Set up your store on the Home tab to start adding products.',
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

// ── Product row card ───────────────────────────────────────────────────────────
class _ProductRow extends ConsumerWidget {
  final ProductModel product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = kCategoryMeta[product.category] ?? kCategoryMeta['Other']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 88,
              height: 88,
              child: product.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFF2EFEA),
                        child: const Icon(Icons.image_outlined,
                            color: Color(0xFFBDB9B4)),
                      ),
                      errorWidget: (_, __, ___) => SellerCategoryIconBox(meta: meta),
                    )
                  : SellerCategoryIconBox(meta: meta),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                      const SizedBox(width: 8),
                      Text('·',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: const Color(0xFFBDB9B4))),
                      const SizedBox(width: 8),
                      Text('Stock: ${product.stock}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: const Color(0xFF9E9B97))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.75,
                        alignment: Alignment.centerLeft,
                        child: Switch(
                          value: product.isActive,
                          activeColor: AppTheme.primary,
                          onChanged: (_) => ref
                              .read(myProductsProvider.notifier)
                              .toggleProduct(product.id),
                        ),
                      ),
                      Text(
                        product.isActive ? 'Active' : 'Hidden',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: product.isActive
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context
                            .push('/seller-products/edit/${product.id}'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: const Color(0xFF9E9B97),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: Colors.red.shade300,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from your shop?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: Colors.red.shade600))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(myProductsProvider.notifier).deleteProduct(product.id);
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class SellerCategoryIconBox extends StatelessWidget {
  final ({IconData icon, Color color}) meta;
  const SellerCategoryIconBox({super.key, required this.meta});

  @override
  Widget build(BuildContext context) => Container(
        color: meta.color.withValues(alpha: 0.12),
        child: Center(
          child: Icon(meta.icon, color: meta.color, size: 32),
        ),
      );
}

class SellerStatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;
  const SellerStatChip({super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _EmptyProducts extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProducts({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('No products yet',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  )),
              const SizedBox(height: 8),
              Text(
                'Add your first product to start selling.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF9E9B97)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add product',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}
