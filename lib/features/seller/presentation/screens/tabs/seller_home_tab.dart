import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../shops/providers/shop_provider.dart';
import '../../../../products/providers/product_provider.dart';
import '../../../../products/data/product_model.dart';
import '../../widgets/create_shop_bottom_sheet.dart';
import '../seller_dashboard_screen.dart' show kCategoryMeta;

class SellerHomeTab extends ConsumerWidget {
  final VoidCallback onGoToProducts;
  const SellerHomeTab({super.key, required this.onGoToProducts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final shopAsync = ref.watch(myShopProvider);
    final productsAsync = ref.watch(myProductsProvider);

    final sellerName = auth.user?.name ?? 'Seller';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return shopAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (shop) {
        if (shop == null) {
          return _NoStoreView(onCreateTap: () => _openCreateSheet(context));
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppTheme.primary,
                expandedHeight: 110,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Olpha Seller',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              )),
                          Text('$greeting, $sellerName!',
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Stats cards ──────────────────────────────────────────
              productsAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox(height: 16)),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (products) {
                  final active = products.where((p) => p.isActive).length;
                  final hidden = products.length - active;
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overview',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              )),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Total Products',
                                value: products.length.toString(),
                                icon: Icons.inventory_2_outlined,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Active',
                                value: active.toString(),
                                icon: Icons.check_circle_outline_rounded,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Hidden',
                                value: hidden.toString(),
                                icon: Icons.visibility_off_outlined,
                                color: Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Coming soon',
                                value: '—',
                                icon: Icons.receipt_long_outlined,
                                color: const Color(0xFFBDB9B4),
                                subtitle: 'Orders',
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Store card ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Store',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          )),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_outlined,
                                  color: AppTheme.primary, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shop.name,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      )),
                                  if (shop.category != null)
                                    Text(shop.category!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF9E9B97),
                                        )),
                                  if (shop.location != null)
                                    Row(children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 12, color: Color(0xFF9E9B97)),
                                      const SizedBox(width: 2),
                                      Text(shop.location!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF9E9B97),
                                          )),
                                    ]),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/seller-shop-edit'),
                              child: Text('Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent products header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Products',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          )),
                      GestureDetector(
                        onTap: onGoToProducts,
                        child: Text('See all',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent products list ──────────────────────────────────
              productsAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (products) {
                  if (products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_box_outlined,
                                  size: 40,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text('No products yet',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      color: const Color(0xFFAEAA9F))),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: onGoToProducts,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Add your first product',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final recent = products.take(3).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _MiniProductRow(product: recent[i]),
                        childCount: recent.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateShopBottomSheet(),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                )),
            const SizedBox(height: 2),
            Text(subtitle ?? label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9E9B97),
                )),
          ],
        ),
      );
}

// ── Mini product row ───────────────────────────────────────────────────────────
class _MiniProductRow extends StatelessWidget {
  final ProductModel product;
  const _MiniProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final meta = kCategoryMeta[product.category] ?? kCategoryMeta['Other']!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: product.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFF0EDE8)),
                      errorWidget: (_, __, ___) => Container(
                        color: meta.color.withValues(alpha: 0.12),
                        child: Icon(meta.icon, color: meta.color, size: 24),
                      ),
                    )
                  : Container(
                      color: meta.color.withValues(alpha: 0.12),
                      child: Icon(meta.icon, color: meta.color, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    )),
                const SizedBox(height: 2),
                Text('${product.price.toStringAsFixed(2)} TND',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.isActive
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.isActive ? 'Active' : 'Hidden',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: product.isActive
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No store view ──────────────────────────────────────────────────────────────
class _NoStoreView extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _NoStoreView({required this.onCreateTap});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  "You don't have a store yet",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your shop to start selling on Olpha.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF7A7570),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onCreateTap,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Create my store',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
        ),
      );
}
