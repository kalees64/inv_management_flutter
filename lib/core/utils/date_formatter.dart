import 'package:intl/intl.dart';

class DateFormatter {
  static String format(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd - MM - yyyy').format(date);
    } catch (e) {
      // If parsing fails, try to see if it's already customized or just return original
      return dateString;
    }
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd - MM - yyyy').format(date);
  }

  static String formatWithTime(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd - MM - yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
