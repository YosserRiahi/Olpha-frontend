class ShopModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? location;
  final String? category;
  final bool isApproved;
  final DateTime createdAt;

  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.location,
    this.category,
    required this.isApproved,
    required this.createdAt,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        logoUrl: json['logoUrl'] as String?,
        bannerUrl: json['bannerUrl'] as String?,
        location: json['location'] as String?,
        category: json['category'] as String?,
        isApproved: json['isApproved'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (bannerUrl != null) 'bannerUrl': bannerUrl,
        if (location != null) 'location': location,
        if (category != null) 'category': category,
      };
}
