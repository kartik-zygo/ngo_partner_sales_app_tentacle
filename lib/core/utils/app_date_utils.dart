import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat short = DateFormat('dd MMM');
  static final DateFormat full = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat month = DateFormat('MMM yyyy');
  static final DateFormat weekday = DateFormat('EEE, dd MMM');
}
