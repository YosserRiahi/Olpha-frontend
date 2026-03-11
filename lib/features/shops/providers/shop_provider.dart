import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shop_model.dart';
import '../data/shop_service.dart';

// ── Async provider: list of approved shops ───────────────────────────────────
final shopsProvider = FutureProvider.family<List<ShopModel>, ShopsFilter>(
  (ref, filter) => ShopService().listShops(
    category: filter.category,
    search: filter.search,
  ),
);

class ShopsFilter {
  final String? category;
  final String? search;

  const ShopsFilter({this.category, this.search});

  @override
  bool operator ==(Object other) =>
      other is ShopsFilter &&
      other.category == category &&
      other.search == search;

  @override
  int get hashCode => Object.hash(category, search);
}

// ── Async provider: single shop by id ───────────────────────────────────────
final shopByIdProvider = FutureProvider.family<ShopModel, String>(
  (ref, id) => ShopService().getShop(id),
);

// ── StateNotifier: seller's own shop ────────────────────────────────────────
class MyShopNotifier extends AsyncNotifier<ShopModel?> {
  final _service = ShopService();

  @override
  Future<ShopModel?> build() async {
    try {
      return await _service.getMyShop();
    } catch (_) {
      return null; // No shop yet
    }
  }

  Future<void> createShop({
    required String name,
    String? description,
    String? location,
    String? category,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.createShop(
          name: name,
          description: description,
          location: location,
          category: category,
        ));
  }

  Future<void> updateShop(Map<String, dynamic> updates) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateMyShop(updates));
  }
}

final myShopProvider = AsyncNotifierProvider<MyShopNotifier, ShopModel?>(
  MyShopNotifier.new,
);
