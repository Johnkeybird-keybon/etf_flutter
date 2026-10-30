import 'package:intl/intl.dart';

class Formats {
  static final _money = NumberFormat('#,##0.00', 'en_US');
  static final _date = DateFormat('yyyy-MM-dd');

  static String money(num? v) => _money.format(v ?? 0);
  static String date(DateTime d) => _date.format(d);
}