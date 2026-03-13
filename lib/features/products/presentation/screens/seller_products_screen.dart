import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../data/product_model.dart';

// ── Category icon map ─────────────────────────────────────────────────────────
const _categoryMeta = <String, ({IconData icon, Color color})>{
  'Jewelry':  (icon: Icons.diamond_outlined,                color: Color(0xFF7B61FF)),
  'Ceramics': (icon: Icons.water_drop_outlined,             color: Color(0xFF0097A7)),
  'Textiles': (icon: Icons.texture_rounded,                 color: Color(0xFFE57373)),
  'Leather':  (icon: Icons.workspace_premium_outlined,      color: Color(0xFF6B4A3A)),
  'Wood':     (icon: Icons.forest_outlined,                 color: Color(0xFF558B2F)),
  'Candles':  (icon: Icons.local_fire_department_outlined,  color: Color(0xFFFF8F00)),
  'Paintings':(icon: Icons.palette_outlined,                color: Color(0xFFE91E63)),
  'Pottery':  (icon: Icons.egg_alt_outlined,                color: Color(0xFF795548)),
  'Other':    (icon: Icons.category_outlined,               color: Color(0xFF9E9B97)),
};

({IconData icon, Color color}) _metaFor(String? category) =>
    _categoryMeta[category] ??
    (icon: Icons.inventory_2_outlined, color: const Color(0xFF9E9B97));

enum _Filter { all, active, hidden }

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            expandedHeight: 110,
            pinned: true,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'My Products',
                            style: GoogleFonts.fredoka(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                context.push('/seller-products/add'),
                            icon: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 28),
                            tooltip: 'Add product',
                          ),
                        ],
                      ),
                      Text(
                        'Manage your listings',
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

          // ── Content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: productsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(e.toString(),
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF9E9B97))),
                ),
              ),
              data: (products) {
                final total  = products.length;
                final active = products.where((p) => p.isActive).length;
                final hidden = total - active;

                final filtered = switch (_filter) {
                  _Filter.active => products.where((p) => p.isActive).toList(),
                  _Filter.hidden => products.where((p) => !p.isActive).toList(),
                  _Filter.all    => products,
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats bar ──────────────────────────────────
                    Container(
                      color: AppTheme.primary,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          _StatChip(label: 'Total', value: '$total'),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Active',
                            value: '$active',
                            color: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Hidden',
                            value: '$hidden',
                            color: const Color(0xFF6D4C41),
                            bgColor: const Color(0xFFFBE9E7),
                          ),
                        ],
                      ),
                    ),

                    // ── Filter tabs ────────────────────────────────
                    Container(
                      color: AppTheme.cardWhite,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: _Filter.values.map((f) {
                          final labels = {
                            _Filter.all:    'All ($total)',
                            _Filter.active: 'Active ($active)',
                            _Filter.hidden: 'Hidden ($hidden)',
                          };
                          final isSelected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.inputFill,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  labels[f]!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF7A7570),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Empty state ────────────────────────────────
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 44,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _filter == _Filter.all
                                  ? 'No products yet'
                                  : 'No ${_filter.name} products',
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filter == _Filter.all
                                  ? 'Add your first product and start selling!'
                                  : 'Switch the filter to see other products.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF7A7570),
                                height: 1.5,
                              ),
                            ),
                            if (_filter == _Filter.all) ...[
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.push('/seller-products/add'),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add your first product'),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      // ── Product list ───────────────────────────────
                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ProductCard(
                          product: filtered[i],
                          onEdit: () => context.push(
                              '/seller-products/edit/${filtered[i].id}'),
                          onDelete: () => _confirmDelete(filtered[i]),
                          onToggle: () => ref
                              .read(myProductsProvider.notifier)
                              .toggleProduct(filtered[i].id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller-products/add'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete product?',
            style: GoogleFonts.fredoka(
                fontSize: 20, fontWeight: FontWeight.w600)),
        content: Text(
          'Remove "${product.name}" from your shop? This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF7A7570))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A)),
            child: Text('Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(myProductsProvider.notifier).deleteProduct(product.id);
    }
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.value,
    this.color = Colors.white,
    this.bgColor = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color.withValues(alpha: color == Colors.white ? 0.8 : 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(product.category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category icon ────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(meta.icon, color: meta.color, size: 26),
          ),
          const SizedBox(width: 12),

          // ── Info ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.8,
                      alignment: Alignment.topRight,
                      child: Switch(
                        value: product.isActive,
                        onChanged: (_) => onToggle(),
                        activeColor: AppTheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price + stock + category row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.price.toStringAsFixed(0)} TND',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stock: ${product.stock}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF7A7570),
                        ),
                      ),
                    ),
                    if (product.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: meta.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action row
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: AppTheme.primary,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: const Color(0xFFBA1A1A),
                      onTap: onDelete,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isActive
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.isActive ? '● Active' : '● Hidden',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: product.isActive
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF6D4C41),
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
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
