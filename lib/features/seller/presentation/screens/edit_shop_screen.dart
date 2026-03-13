import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/shops/providers/shop_provider.dart';

class EditShopScreen extends ConsumerStatefulWidget {
  const EditShopScreen({super.key});

  @override
  ConsumerState<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends ConsumerState<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _logoUrlCtrl     = TextEditingController();
  final _bannerUrlCtrl   = TextEditingController();
  String? _selectedCategory;
  bool _initialised = false;
  bool _saving = false;
  String? _error;

  static const _categories = [
    'Jewelry', 'Ceramics', 'Textiles', 'Leather',
    'Wood', 'Candles', 'Paintings', 'Pottery', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _logoUrlCtrl.dispose();
    _bannerUrlCtrl.dispose();
    super.dispose();
  }

  void _initFromShop() {
    if (_initialised) return;
    final shop = ref.read(myShopProvider).valueOrNull;
    if (shop == null) return;
    _nameCtrl.text      = shop.name;
    _descCtrl.text      = shop.description ?? '';
    _locationCtrl.text  = shop.location ?? '';
    _logoUrlCtrl.text   = shop.logoUrl ?? '';
    _bannerUrlCtrl.text = shop.bannerUrl ?? '';
    _selectedCategory   = shop.category;
    _initialised = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(myShopProvider.notifier).updateShop({
        'name':        _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'location':    _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'category':    _selectedCategory,
        'logoUrl':     _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
        'bannerUrl':   _bannerUrlCtrl.text.trim().isEmpty ? null : _bannerUrlCtrl.text.trim(),
      });
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);

    // Pre-fill once data is ready
    shopAsync.whenData((_) => WidgetsBinding.instance
        .addPostFrameCallback((_) => _initFromShop()));

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
                            'Edit Shop',
                            style: GoogleFonts.fredoka(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          _saving
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  ),
                                )
                              : FilledButton(
                                  onPressed: _save,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    textStyle: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Save'),
                                ),
                        ],
                      ),
                      Text(
                        'Update your shop profile',
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

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: shopAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(e.toString(),
                      style: GoogleFonts.poppins(color: const Color(0xFF9E9B97))),
                ),
              ),
              data: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Shop avatar placeholder ──────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.2),
                                    width: 2),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  size: 44, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Shop Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9E9B97),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Section: Basics ──────────────────────────
                      _SectionLabel(label: 'Basics'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Shop name *',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Shop name is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categories
                                  .map((c) =>
                                      DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v),
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section: About ───────────────────────────
                      _SectionLabel(label: 'About your shop'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 64),
                              child: Icon(Icons.notes_rounded),
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          maxLength: 300,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section: Location ────────────────────────
                      _SectionLabel(label: 'Location'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextFormField(
                          controller: _locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City (e.g. Tunis, Sfax…)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Section: Visuals ─────────────────────────
                      _SectionLabel(label: 'Visuals (optional)'),
                      const SizedBox(height: 4),
                      Text(
                        'Paste an image URL for your logo or banner.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9E9B97),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _logoUrlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Logo URL',
                                prefixIcon: Icon(Icons.image_outlined),
                                hintText: 'https://…',
                              ),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bannerUrlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Banner URL',
                                prefixIcon: Icon(Icons.panorama_outlined),
                                hintText: 'https://…',
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),

                      // ── Error ────────────────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFFBA1A1A),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Save button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_saving ? 'Saving…' : 'Save Changes'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }
}
