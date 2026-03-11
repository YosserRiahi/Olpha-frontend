import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  static const _categories = [
    'Jewelry', 'Ceramics', 'Textiles', 'Leather',
    'Wood', 'Candles', 'Paintings', 'Pottery', 'Other',
  ];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingProduct());
    }
  }

  void _loadExistingProduct() {
    final products = ref.read(myProductsProvider).valueOrNull;
    if (products == null) return;
    try {
      final product = products.firstWhere((p) => p.id == widget.productId);
      _nameCtrl.text  = product.name;
      _descCtrl.text  = product.description ?? '';
      _priceCtrl.text = product.price.toString();
      _stockCtrl.text = product.stock.toString();
      setState(() => _selectedCategory = product.category);
    } catch (_) {
      // product not found — nothing to prefill
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final price = double.parse(_priceCtrl.text.trim());
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
      final name  = _nameCtrl.text.trim();
      final desc  =
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

      if (_isEdit) {
        final updates = <String, dynamic>{
          'name': name,
          'description': desc,
          'price': price,
          'stock': stock,
          'category': _selectedCategory,
        };
        await ref
            .read(myProductsProvider.notifier)
            .updateProduct(widget.productId!, updates);
      } else {
        await ref.read(myProductsProvider.notifier).createProduct(
              name: name,
              description: desc,
              price: price,
              stock: stock,
              category: _selectedCategory,
            );
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name ───────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a product name'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Description ────────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 14),

              // ── Price + Stock ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price (TND) *',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final p = double.tryParse(v.trim());
                        if (p == null || p < 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock qty',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Category ───────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppTheme.textDark),
              ),
              const SizedBox(height: 28),

              // ── Error ──────────────────────────────────────────────────
              if (_error != null) ...[
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFFBA1A1A)),
                ),
                const SizedBox(height: 12),
              ],

              // ── Submit ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _isEdit
                              ? Icons.save_rounded
                              : Icons.add_business_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _isLoading
                        ? (_isEdit ? 'Saving…' : 'Adding…')
                        : (_isEdit ? 'Save changes' : 'Add product'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
