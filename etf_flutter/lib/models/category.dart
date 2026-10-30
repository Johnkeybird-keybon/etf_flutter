enum TxType { income, expense }

extension TxTypeX on TxType {
  String get dbValue => name.toUpperCase();
  String get label => name.toUpperCase();
}

TxType txTypeFromString(String s) =>
    s.toUpperCase() == 'INCOME' ? TxType.income : TxType.expense;

class Category {
  final int id;
  final String name;
  final TxType type;

  Category({required this.id, required this.name, required this.type});

  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id: m['category_id'] as int,
    name: m['name'] as String,
    type: txTypeFromString(m['type'] as String),
  );
}