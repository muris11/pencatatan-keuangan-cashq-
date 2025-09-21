class CategoryItem {
  final String id;
  final String name;
  final int budget; // in IDR

  CategoryItem({required this.id, required this.name, this.budget = 0});

  Map<String, dynamic> toMap() => {'name': name, 'budget': budget};

  factory CategoryItem.fromMap(String id, Map<String, dynamic> map) =>
      CategoryItem(
        id: id,
        name: map['name'] ?? '',
        budget: (map['budget'] ?? 0) as int,
      );
}
