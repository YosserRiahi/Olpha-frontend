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
    show kCategoryMeta, kSubCategories;
import '../../../shops/providers/shop_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _category;
  int     _stock   = 1;
  bool    _saving  = false;
  String? _error;

  /// Mixed list: String (existing URL) | XFile (newly picked)
  final List<dynamic> _images = [];

  // ── Upload progress tracking ──────────────────────────────────────────────
  int? _uploadingImageIndex; // index in _images that is currently uploading
  int  _xFilesUploaded = 0;  // how many XFiles have been uploaded so far
  int  _xFilesTotal    = 0;  // total XFiles to upload in this save

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
      _nameCtrl.text  = p.name;
      _descCtrl.text  = p.description ?? '';
      _priceCtrl.text = p.price.toString();
      _category       = p.category;
      _stock          = p.stock;
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

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 5 photos allowed',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.white)),
          backgroundColor: const Color(0xFF3C3A38),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final xFile  = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (xFile != null) setState(() => _images.add(xFile));
  }

  void _removeImage(int index) {
    if (_saving) return;
    setState(() => _images.removeAt(index));
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final xFilesTotal =
        _images.whereType<XFile>().length;

    setState(() {
      _saving              = true;
      _error               = null;
      _xFilesTotal         = xFilesTotal;
      _xFilesUploaded      = 0;
      _uploadingImageIndex = null;
    });

    try {
      final finalUrls = <String>[];

      for (int i = 0; i < _images.length; i++) {
        final img = _images[i];
        if (img is String) {
          finalUrls.add(img);
        } else if (img is XFile) {
          if (mounted) setState(() => _uploadingImageIndex = i);
          final url =
              await ImageUploadService.uploadImage(File(img.path));
          if (mounted) {
            setState(() {
              _xFilesUploaded++;
              _uploadingImageIndex = null;
            });
          }
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
            'price':     price,
            'stock':     _stock,
            'category':  _category,
            'imageUrls': finalUrls,
          },
        );
      } else {
        await ref.read(myProductsProvider.notifier).createProduct(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          price:     price,
          stock:     _stock,
          category:  _category,
          imageUrls: finalUrls,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _saving              = false;
          _uploadingImageIndex = null;
          _xFilesTotal         = 0;
          _xFilesUploaded      = 0;
        });
      }
    }
  }

  // ── Button label ──────────────────────────────────────────────────────────
  String get _saveButtonLabel {
    if (!_saving) return _isEdit ? 'Update Product' : 'Save Product';
    if (_uploadingImageIndex != null) {
      return 'Uploading photo ${_xFilesUploaded + 1}/$_xFilesTotal…';
    }
    return 'Saving…';
  }

  @override
  Widget build(BuildContext context) {
    final title        = _isEdit ? 'Edit Product' : 'New Product';
    final shopCategory = ref.watch(myShopProvider).valueOrNull?.category;
    final shopMeta     = kCategoryMeta[shopCategory] ?? kCategoryMeta['Other']!;
    final categories   = kSubCategories[shopCategory] ?? kSubCategories['Other']!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.primary,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
            title: Text(
              title,
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
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
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Photos section ─────────────────────────────────────
                    Row(
                      children: [
                        _SectionLabel(label: 'Photos'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _images.length >= 5
                                ? Colors.orange.shade50
                                : const Color(0xFFF0EDE8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_images.length}/5',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _images.length >= 5
                                  ? Colors.orange.shade700
                                  : const Color(0xFF9E9B97),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add button (always visible, snackbar when full)
                          GestureDetector(
                            onTap: _saving ? null : _pickImage,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 88,
                              height: 88,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: _images.length >= 5
                                    ? const Color(0xFFF5F3F0)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _images.length >= 5
                                      ? const Color(0xFFE0DDD8)
                                      : AppTheme.primary
                                            .withValues(alpha: 0.4),
                                  width: _images.length >= 5 ? 1 : 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: _images.length >= 5
                                        ? const Color(0xFFBDB9B4)
                                        : AppTheme.primary,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: _images.length >= 5
                                          ? const Color(0xFFBDB9B4)
                                          : AppTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Image thumbnails
                          ..._images.asMap().entries.map((entry) {
                            final i   = entry.key;
                            final img = entry.value;
                            final isUploading =
                                _uploadingImageIndex == i;

                            return Stack(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 88,
                                  height: 88,
                                  margin:
                                      const EdgeInsets.only(right: 10),
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    color: const Color(0xFFF2EFEA),
                                    border: isUploading
                                        ? Border.all(
                                            color: AppTheme.primary,
                                            width: 2)
                                        : null,
                                  ),
                                  child: img is String
                                      ? CachedNetworkImage(
                                          imageUrl: img,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(
                                                  Icons
                                                      .broken_image_outlined),
                                        )
                                      : Image.file(
                                          File((img as XFile).path),
                                          fit: BoxFit.cover,
                                        ),
                                ),

                                // Upload progress overlay
                                if (isUploading)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    width: 88,
                                    height: 88,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Remove button
                                if (!isUploading)
                                  Positioned(
                                    top: 3,
                                    right: 13,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(i),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 13),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Product info ───────────────────────────────────────
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
                          // Name
                          TextFormField(
                            controller: _nameCtrl,
                            enabled: !_saving,
                            textCapitalization:
                                TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Product name *',
                              prefixIcon:
                                  Icon(Icons.label_outline_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Category
                          DropdownButtonFormField<String>(
                            value: categories.contains(_category)
                                ? _category
                                : null,
                            hint: Text(
                              'Select a category',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF9E9B97),
                              ),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon:
                                  Icon(Icons.category_outlined),
                            ),
                            items: categories.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(shopMeta.icon,
                                        color: shopMeta.color,
                                        size: 18),
                                    const SizedBox(width: 10),
                                    Text(c,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: _saving
                                ? null
                                : (v) =>
                                    setState(() => _category = v),
                          ),
                          const SizedBox(height: 14),

                          // Description
                          TextFormField(
                            controller: _descCtrl,
                            enabled: !_saving,
                            maxLines: 4,
                            maxLength: 500,
                            textCapitalization:
                                TextCapitalization.sentences,
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

                    // ── Pricing & stock ────────────────────────────────────
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
                          // Price
                          TextFormField(
                            controller: _priceCtrl,
                            enabled: !_saving,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Price *',
                              prefixIcon:
                                  const Icon(Icons.sell_outlined),
                              suffix: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TND',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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
                          const SizedBox(height: 18),

                          // Stock stepper
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 20,
                                  color: Color(0xFF9E9B97)),
                              const SizedBox(width: 12),
                              Text(
                                'Stock',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF7A7570),
                                ),
                              ),
                              const Spacer(),
                              _StepperBtn(
                                icon: Icons.remove_rounded,
                                onTap: (_saving || _stock == 0)
                                    ? null
                                    : () =>
                                        setState(() => _stock--),
                              ),
                              SizedBox(
                                width: 52,
                                child: Text(
                                  '$_stock',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              _StepperBtn(
                                icon: Icons.add_rounded,
                                onTap: _saving
                                    ? null
                                    : () =>
                                        setState(() => _stock++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Error banner ───────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFBDBD)),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 18,
                                color: const Color(0xFFBA1A1A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFFBA1A1A),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Save button ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _saveButtonLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _isEdit
                                    ? 'Update Product'
                                    : 'Save Product',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      );
}

// ── Stepper button ─────────────────────────────────────────────────────────────
class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: onTap != null
            ? AppTheme.primary.withValues(alpha: 0.1)
            : const Color(0xFFF0EDE8),
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: onTap != null
                  ? AppTheme.primary
                  : const Color(0xFFBDB9B4),
            ),
          ),
        ),
      );
}
