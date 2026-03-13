import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';

// ── Category map (same as products screen) ────────────────────────────────────
const _categories = <String, IconData>{
  'Jewelry':   Icons.diamond_outlined,
  'Ceramics':  Icons.water_drop_outlined,
  'Textiles':  Icons.texture_rounded,
  'Leather':   Icons.workspace_premium_outlined,
  'Wood':      Icons.forest_outlined,
  'Candles':   Icons.local_fire_department_outlined,
  'Paintings': Icons.palette_outlined,
  'Pottery':   Icons.egg_alt_outlined,
  'Other':     Icons.category_outlined,
};

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();

  String? _selectedCategory;
  int _stock = 0;
  bool _saving = false;
  bool _initialised = false;
  String? _error;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _loadProduct() {
    if (_initialised) return;
    final products = ref.read(myProductsProvider).valueOrNull;
    if (products == null) return;
    final product = products.where((p) => p.id == widget.productId).firstOrNull;
    if (product == null) return;
    _nameCtrl.text       = product.name;
    _descCtrl.text       = product.description ?? '';
    _priceCtrl.text      = product.price.toStringAsFixed(0);
    _selectedCategory    = product.category;
    _stock               = product.stock;
    _initialised = true;
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      setState(() => _error = 'Please enter a valid price');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      if (_isEdit) {
        await ref.read(myProductsProvider.notifier).updateProduct(
          widget.productId!,
          {
            'name':        _nameCtrl.text.trim(),
            'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            'price':       price,
            'stock':       _stock,
            'category':    _selectedCategory,
          },
        );
      } else {
        await ref.read(myProductsProvider.notifier).createProduct(
          name:        _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          price:       price,
          stock:       _stock,
          category:    _selectedCategory,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Product' : 'New Product';

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
                            title,
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
                                  onPressed: _submit,
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
                        _isEdit
                            ? 'Update your product details'
                            : 'Add a new product to your shop',
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

          // ── Form ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section: Product Info ────────────────────
                    _SectionLabel(label: 'Product Info'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Product name *',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Product name is required'
                                    : null,
                          ),
                          const SizedBox(height: 12),

                          // Category with icon in items
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _categories.entries
                                .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Row(
                                        children: [
                                          Icon(e.value,
                                              size: 16,
                                              color: const Color(0xFF7A7570)),
                                          const SizedBox(width: 8),
                                          Text(e.key),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 48),
                                child: Icon(Icons.notes_rounded),
                              ),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            maxLength: 500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section: Pricing & Stock ─────────────────
                    _SectionLabel(label: 'Pricing & Stock'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Price field with TND badge
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Price *',
                              prefixIcon: const Icon(Icons.sell_outlined),
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'TND',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Price is required';
                              }
                              final p = double.tryParse(
                                  v.replaceAll(',', '.'));
                              if (p == null || p <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Stock stepper
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.layers_outlined,
                                    size: 20, color: Color(0xFF7A7570)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Stock quantity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF7A7570),
                                  ),
                                ),
                              ),
                              // Stepper
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StepperBtn(
                                      icon: Icons.remove_rounded,
                                      onTap: () {
                                        if (_stock > 0) {
                                          setState(() => _stock--);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: Text(
                                        '$_stock',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    _StepperBtn(
                                      icon: Icons.add_rounded,
                                      onTap: () => setState(() => _stock++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

                    // ── Submit button ────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _saving
                              ? 'Saving…'
                              : _isEdit
                                  ? 'Update Product'
                                  : 'Save Product',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
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

// ── Stepper button ────────────────────────────────────────────────────────────
class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}
