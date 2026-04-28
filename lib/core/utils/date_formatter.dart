import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _dbFormat = DateFormat('yyyy-MM-dd');
  static final _dayDateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id');

  /// Format untuk tampilan: 15/04/2025
  static String toDisplay(String dbDate) {
    try {
      final date = _dbFormat.parse(dbDate);
      return _dateFormat.format(date);
    } catch (_) {
      return dbDate;
    }
  }

  /// Format untuk database: 2025-04-15
  static String toDb(DateTime date) => _dbFormat.format(date);

  /// Format hari ini untuk database
  static String todayDb() => _dbFormat.format(DateTime.now());

  /// Format lengkap: Selasa, 15 April 2025
  static String toLongDisplay(String dbDate) {
    try {
      final date = _dbFormat.parse(dbDate);
      return _dayDateFormat.format(date);
    } catch (_) {
      return dbDate;
    }
  }

  /// Format datetime untuk tampilan: 15/04/2025 09:30
  static String toDisplayDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return _dateTimeFormat.format(date);
    } catch (_) {
      return isoString;
    }
  }

  /// Waktu sekarang dalam format ISO string
  static String nowIso() => DateTime.now().toIso8601String();
}
