enum TxType { income, expense }

class TransactionItem {
  final String id;
  final int amount; // in IDR
  final String category;
  final TxType type;
  final DateTime date;
  final String? notes;

  TransactionItem({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'category': category,
    'type': type.name,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory TransactionItem.fromMap(String id, Map<String, dynamic> map) =>
      TransactionItem(
        id: id,
        amount: (map['amount'] ?? 0) as int,
        category: map['category'] ?? '',
        type: (map['type'] == 'income') ? TxType.income : TxType.expense,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'],
      );
}
