class Budget {
  final int id;
  final int categoryId;
  final String categoryName;
  final int month;
  final int year;
  final double limit;
  final double spent;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.month,
    required this.year,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;
  bool get isOverBudget => spent > limit;
}