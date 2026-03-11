class ProductModel {
  final String id;
  final String shopId;
  final String name;
  final String? description;
  final double price;
  final List<String> imageUrls;
  final int stock;
  final String? category;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    required this.price,
    required this.imageUrls,
    required this.stock,
    this.category,
    required this.tags,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        imageUrls: (json['imageUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        stock: json['stock'] as int? ?? 0,
        category: json['category'] as String?,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'price': price,
        if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        'stock': stock,
        if (category != null) 'category': category,
        if (tags.isNotEmpty) 'tags': tags,
        'isActive': isActive,
      };

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    List<String>? imageUrls,
    int? stock,
    String? category,
    List<String>? tags,
    bool? isActive,
  }) =>
      ProductModel(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        imageUrls: imageUrls ?? this.imageUrls,
        stock: stock ?? this.stock,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
