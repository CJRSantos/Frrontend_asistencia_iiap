import '../config/api_config.dart';
import '../models/birthday_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class BirthdayService {
  // GET /api/birthdays/today: Retorna los colaboradores que cumplen años el día de hoy.
  static Future<List<BirthdayModel>> getTodayBirthdays() async {
    try {
      final response = await ApiService.get(
        ApiConfig.birthdaysToday,
        requiresAuth: true,
      );

      final list = (response is List)
          ? response
          : ((response is Map && response['data'] is List)
              ? (response['data'] as List)
              : null);

      if (list != null) {
        await StorageService.saveCachedBirthdays('today', list);
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => BirthdayModel.fromJson(
                  item,
                  defaultDay: DateTime.now().day,
                  defaultMonth: DateTime.now().month,
                ))
            .toList();
      }
    } catch (_) {
      final cached = await StorageService.getCachedBirthdays('today');
      if (cached != null) {
        return cached
            .whereType<Map<String, dynamic>>()
            .map((item) => BirthdayModel.fromJson(
                  item,
                  defaultDay: DateTime.now().day,
                  defaultMonth: DateTime.now().month,
                ))
            .toList();
      }
    }
    return [];
  }

  // GET /api/birthdays/upcoming: Retorna la lista de próximos cumpleaños formateados (D/M, is_today, etc.).
  static Future<List<BirthdayModel>> getUpcomingBirthdays() async {
    try {
      final response = await ApiService.get(
        ApiConfig.birthdaysUpcoming,
        requiresAuth: true,
      );

      final list = (response is List)
          ? response
          : ((response is Map && response['data'] is List)
              ? (response['data'] as List)
              : null);

      if (list != null) {
        await StorageService.saveCachedBirthdays('upcoming', list);
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => BirthdayModel.fromJson(item))
            .toList();
      }
    } catch (_) {
      final cached = await StorageService.getCachedBirthdays('upcoming');
      if (cached != null) {
        return cached
            .whereType<Map<String, dynamic>>()
            .map((item) => BirthdayModel.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  // GET /api/birthdays: Retorna el calendario anual agrupado por meses y días.
  static Future<List<BirthdayModel>> getCalendarBirthdays() async {
    try {
      final response = await ApiService.get(
        ApiConfig.birthdaysCalendar,
        requiresAuth: true,
      );

      return _extractBirthdays(response);
    } catch (_) {}
    return [];
  }

  static List<BirthdayModel> _extractBirthdays(dynamic data) {
    final List<BirthdayModel> results = [];

    if (data == null) return results;

    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final monthNum = int.tryParse(item['month']?.toString() ?? '');
          final monthName = item['month_name'] ?? item['name'] ?? (item['month'] is String ? item['month'] : null);
          final resolvedMonth = monthNum ?? _monthNameToNumber(monthName?.toString());

          if (item['birthdays'] is List) {
            for (final b in (item['birthdays'] as List)) {
              if (b is Map<String, dynamic>) {
                results.add(BirthdayModel.fromJson(b, defaultMonth: resolvedMonth));
              }
            }
          } else if (item['users'] is List) {
            for (final u in (item['users'] as List)) {
              if (u is Map<String, dynamic>) {
                results.add(BirthdayModel.fromJson(u, defaultMonth: resolvedMonth));
              }
            }
          } else if (item['collaborators'] is List) {
            for (final c in (item['collaborators'] as List)) {
              if (c is Map<String, dynamic>) {
                results.add(BirthdayModel.fromJson(c, defaultMonth: resolvedMonth));
              }
            }
          } else if (item['days'] is List) {
            for (final dayItem in (item['days'] as List)) {
              if (dayItem is Map<String, dynamic>) {
                final dayNum = int.tryParse(dayItem['day']?.toString() ?? '');
                final dayUsers = dayItem['users'] ?? dayItem['birthdays'] ?? dayItem['collaborators'];
                if (dayUsers is List) {
                  for (final u in dayUsers) {
                    if (u is Map<String, dynamic>) {
                      results.add(BirthdayModel.fromJson(u, defaultMonth: resolvedMonth, defaultDay: dayNum));
                    }
                  }
                }
              }
            }
          } else {
            results.add(BirthdayModel.fromJson(item, defaultMonth: resolvedMonth));
          }
        }
      }
    } else if (data is Map<String, dynamic>) {
      if (data['data'] != null) {
        return _extractBirthdays(data['data']);
      }
      if (data['months'] != null) {
        return _extractBirthdays(data['months']);
      }

      data.forEach((key, value) {
        final monthNum = int.tryParse(key) ?? _monthNameToNumber(key);
        if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              results.add(BirthdayModel.fromJson(item, defaultMonth: monthNum));
            }
          }
        }
      });
    }

    return results;
  }

  static int? _monthNameToNumber(String? name) {
    if (name == null) return null;
    final clean = name.trim().toLowerCase();
    const months = {
      'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
      'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
      'septiembre': 9, 'setiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12,
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    return months[clean];
  }
}
