import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _nprFormat = NumberFormat.currency(
    locale: 'en_NP',
    symbol: 'NPR ',
    decimalDigits: 0,
  );

  static String formatNPR(num amount) => _nprFormat.format(amount);

  static String formatCompactNPR(num amount) =>
      _nprFormat.format(amount).replaceAll('.00', '');
}
