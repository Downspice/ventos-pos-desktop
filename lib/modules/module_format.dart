import 'package:intl/intl.dart';
import 'package:ventos_pos/utils/money.dart';

String moduleFormatMoney(double amount) => formatMoneyMajor(amount, CurrencyCode.ghs);

String moduleFormatDateTime(String iso) {
  try {
    return DateFormat.yMMMd().add_jm().format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String moduleShortId(String id) => id.length > 8 ? id.substring(id.length - 8) : id;
