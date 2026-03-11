import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/shops/providers/shop_provider.dart';

class CreateShopForm extends ConsumerStatefulWidget {
  const CreateShopForm({super.key});

  @override
  ConsumerState<CreateShopForm> createState() => _CreateShopFormState();
}

class _CreateShopFormState extends ConsumerState<CreateShopForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    'Jewelry', 'Ceramics', 'Textiles', 'Leather',
    'Wood', 'Candles', 'Paintings', 'Pottery', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(myShopProvider.notifier).createShop(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          category: _selectedCategory,
        );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(myShopProvider);
    final isLoading = shopState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop name
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Shop name *',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a shop name'
                : null,
          ),
          const SizedBox(height: 14),

          // Description
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLines: 3,
            maxLength: 300,
          ),
          const SizedBox(height: 14),

          // Location
          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'City (e.g. Tunis, Sfax…)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          // Category dropdown
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

          // Error from provider
          if (shopState.hasError) ...[
            Text(
              shopState.error.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFFBA1A1A)),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_business_rounded, size: 18),
              label: Text(isLoading ? 'Creating…' : 'Create my shop'),
            ),
          ),
        ],
      ),
    );
  }
}
