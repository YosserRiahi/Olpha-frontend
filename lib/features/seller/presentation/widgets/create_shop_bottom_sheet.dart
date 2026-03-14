import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/shops/providers/shop_provider.dart';
import 'create_shop_form.dart';

/// Modal bottom sheet that wraps the shop creation form.
/// Automatically closes when the shop is successfully created.
class CreateShopBottomSheet extends ConsumerWidget {
  const CreateShopBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-close once shop is created
    ref.listen(myShopProvider, (prev, next) {
      if (next.hasValue && next.value != null && (prev?.value == null)) {
        Navigator.of(context).pop();
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0CCB8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Create your store',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF9E9B97),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF2EFEA)),

            // Form
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: const [CreateShopForm()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
