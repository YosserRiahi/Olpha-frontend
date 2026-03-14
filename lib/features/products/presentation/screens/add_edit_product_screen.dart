import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../providers/product_provider.dart';
import '../../../seller/presentation/screens/seller_dashboard_screen.dart'
    show kCategoryMeta;

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _category;
  int _stock = 0;
  bool _saving = false;
  String? _error;

  /// Mixed list: String (existing URL) or XFile (newly picked)
  final List<dynamic> _images = [];

  static const _categories = [
    'Jewelry', 'Ceramics', 'Textiles', 'Leather',
    'Wood', 'Candles', 'Paintings', 'Pottery', 'Other',
  ];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  void _loadProduct() {
    final products = ref.read(myProductsProvider).valueOrNull ?? [];
    final p = products.where((x) => x.id == widget.productId).firstOrNull;
    if (p == null) return;
    setState(() {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price.toString();
      _category = p.category;
      _stock = p.stock;
      _images
        ..clear()
        ..addAll(p.imageUrls);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    if (_images.length >= 5) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (xFile != null) setState(() => _images.add(xFile));
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  // ── Save / submit ─────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      // Upload any newly picked XFile images
      final finalUrls = <String>[];
      for (final img in _images) {
        if (img is String) {
          finalUrls.add(img);
        } else if (img is XFile) {
          final url = await ImageUploadService.uploadImage(File(img.path));
          finalUrls.add(url);
        }
      }

      final price = double.parse(_priceCtrl.text.trim());

      if (_isEdit) {
        await ref.read(myProductsProvider.notifier).updateProduct(
          widget.productId!,
          {
            'name': _nameCtrl.text.trim(),
            'description': _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            'price': price,
            'stock': _stock,
            'category': _category,
            'imageUrls': finalUrls,
          },
        );
      } else {
        await ref.read(myProductsProvider.notifier).createProduct(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          price: price,
          stock: _stock,
          category: _category,
          imageUrls: finalUrls,
        );
      }

      if (mounted) Navigator.of(context).pop();
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
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(title,
                style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: Text('Save',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
            ],
          ),

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Images section ─────────────────────────────────────
                    _SectionLabel(label: 'Photos'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add button
                          if (_images.length < 5)
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 88,
                                height: 88,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFD0CCB8)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: AppTheme.primary, size: 24),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_images.length}/5',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: const Color(0xFF9E9B97)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Image previews
                          ..._images.asMap().entries.map((entry) {
                            final i = entry.key;
                            final img = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  margin: const EdgeInsets.only(right: 10),
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF2EFEA),
                                  ),
                                  child: img is String
                                      ? CachedNetworkImage(
                                          imageUrl: img,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
                                                  Icons.broken_image_outlined),
                                        )
                                      : Image.file(
                                          File((img as XFile).path),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(i),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Product info card ──────────────────────────────────
                    _SectionLabel(label: 'Product Info'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Product name *',
                              prefixIcon: Icon(Icons.label_outline_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _categories.map((c) {
                              final meta = kCategoryMeta[c]!;
                              return DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(meta.icon,
                                        color: meta.color, size: 18),
                                    const SizedBox(width: 10),
                                    Text(c,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _category = v),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 56),
                                child: Icon(Icons.notes_rounded),
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pricing & stock card ───────────────────────────────
                    _SectionLabel(label: 'Pricing & Stock'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            decoration: InputDecoration(
                              labelText: 'Price *',
                              prefixIcon: const Icon(Icons.sell_outlined),
                              suffix: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('TND',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    )),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Price is required';
                              }
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 20,
                                  color: Color(0xFF9E9B97)),
                              const SizedBox(width: 12),
                              Text('Stock',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF7A7570))),
                              const Spacer(),
                              _StepperBtn(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  if (_stock > 0) setState(() => _stock--);
                                },
                              ),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  '$_stock',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
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
                        ],
                      ),
                    ),

                    // ── Error ──────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFFBA1A1A))),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Text(
                                _isEdit ? 'Update Product' : 'Save Product',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                      ),
                    ),
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
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      );
}

// ── Stepper button ────────────────────────────────────────────────────────────
class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
      );
}
