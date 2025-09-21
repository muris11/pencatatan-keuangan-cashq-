import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);
String idr(int value) => _idr.format(value);
String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
