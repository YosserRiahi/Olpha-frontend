import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../shops/providers/shop_provider.dart';
import '../../widgets/create_shop_bottom_sheet.dart';

class SellerProfileTab extends ConsumerWidget {
  const SellerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final shopAsync = ref.watch(myShopProvider);

    final user = auth.user;
    final name = user?.name ?? 'Seller';
    final email = user?.email ?? '';
    final initials = name.trim().split(' ')
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Profile',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // ── Avatar + info ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials.isEmpty ? 'S' : initials,
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          )),
                      const SizedBox(height: 2),
                      Text(email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9E9B97),
                          )),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Seller',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
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

          const SizedBox(height: 20),

          // ── Account ────────────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          _ProfileTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Name',
            onTap: () => _showEditNameSheet(context, ref, name),
          ),

          const SizedBox(height: 16),

          // ── Store ──────────────────────────────────────────────────
          _SectionHeader(title: 'Store'),
          shopAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (shop) => shop != null
                ? _ProfileTile(
                    icon: Icons.storefront_outlined,
                    label: 'Manage Store',
                    subtitle: shop.name,
                    onTap: () => context.push('/seller-shop-edit'),
                  )
                : _ProfileTile(
                    icon: Icons.add_business_outlined,
                    label: 'Create Store',
                    subtitle: 'Set up your shop on Olpha',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CreateShopBottomSheet(),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // ── Session ────────────────────────────────────────────────
          _SectionHeader(title: 'Session'),
          _ProfileTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            iconColor: Colors.red.shade400,
            labelColor: Colors.red.shade500,
            onTap: () => _confirmSignOut(context, ref),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showEditNameSheet(BuildContext context, WidgetRef ref, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0CCB8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Name',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your full name',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 14, color: const Color(0xFFBDB9B4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD0CCB8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(
                    fontSize: 15, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newName = ctrl.text.trim();
                    if (newName.isEmpty) return;
                    Navigator.pop(ctx);
                    await ref
                        .read(authProvider.notifier)
                        .updateProfile(name: newName);
                  },
                  child: Text('Save',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?',
            style: GoogleFonts.fredoka(
                fontSize: 18, color: AppTheme.textDark)),
        content: Text('You will be redirected to the login screen.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF7A7570))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF9E9B97))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: GoogleFonts.poppins(
                    color: Colors.red.shade500,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(authProvider.notifier).signOut();
    }
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9E9B97),
              letterSpacing: 0.5,
            )),
      );
}

// ── Profile tile ───────────────────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _ProfileTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: iconColor ?? AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: labelColor ?? AppTheme.textDark,
                          )),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF9E9B97),
                            )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: const Color(0xFFD0CCB8), size: 20),
              ],
            ),
          ),
        ),
      );
}
