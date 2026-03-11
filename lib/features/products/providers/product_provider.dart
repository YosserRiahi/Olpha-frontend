import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_model.dart';
import '../data/product_service.dart';

// ── Seller: own products notifier ────────────────────────────────────────────
class MyProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  final _service = ProductService();

  @override
  Future<List<ProductModel>> build() async {
    return _service.listMyProducts();
  }

  Future<void> createProduct({
    required String name,
    String? description,
    required double price,
    int stock = 0,
    String? category,
  }) async {
    final product = await _service.createProduct(
      name: name,
      description: description,
      price: price,
      stock: stock,
      category: category,
    );
    state = AsyncData([product, ...?state.valueOrNull]);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    final updated = await _service.updateProduct(id, updates);
    state = AsyncData(
      state.valueOrNull
              ?.map((p) => p.id == id ? updated : p)
              .toList() ??
          [updated],
    );
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    state = AsyncData(
      state.valueOrNull?.where((p) => p.id != id).toList() ?? [],
    );
  }

  Future<void> toggleProduct(String id) async {
    final updated = await _service.toggleProduct(id);
    state = AsyncData(
      state.valueOrNull
              ?.map((p) => p.id == id ? updated : p)
              .toList() ??
          [updated],
    );
  }
}

final myProductsProvider =
    AsyncNotifierProvider<MyProductsNotifier, List<ProductModel>>(
  MyProductsNotifier.new,
);

// ── Public: products for a given shop ────────────────────────────────────────
final shopProductsProvider =
    FutureProvider.family<List<ProductModel>, String>(
  (ref, shopId) => ProductService().listProductsByShop(shopId),
);

// ── Public: single product by id ─────────────────────────────────────────────
final productByIdProvider = FutureProvider.family<ProductModel, String>(
  (ref, id) => ProductService().getProduct(id),
);
