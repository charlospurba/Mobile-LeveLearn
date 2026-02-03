class TradeModel {
  final int id;
  final String title;
  final String image; // Akan berisi ID desain seperti "DESIGN_GOLD_ELITE"
  final String description;
  final String category;
  final String? requiredBadgeType;
  final int priceInPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool hasTrade = false;

  TradeModel({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.category,
    this.requiredBadgeType,
    required this.priceInPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      image: json['image'] ?? "", // Proteksi Null: memberikan string kosong jika null
      description: json['description'] ?? "",
      category: json['category'] ?? "REWARD",
      requiredBadgeType: json['requiredBadgeType'],
      priceInPoints: json['priceInPoints'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}