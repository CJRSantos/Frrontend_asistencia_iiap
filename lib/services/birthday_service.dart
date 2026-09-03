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
        final now = DateTime.now();
        return list
            .whereType<Map>()
            .map((item) => BirthdayModel.fromJson(
                  Map<String, dynamic>.from(item),
                  defaultDay: now.day,
                  defaultMonth: now.month,
                ))
            .toList();
      }
    } catch (_) {
      final cached = await StorageService.getCachedBirthdays('today');
      if (cached != null) {
        final now = DateTime.now();
        return cached
            .whereType<Map>()
            .map((item) => BirthdayModel.fromJson(
                  Map<String, dynamic>.from(item),
                  defaultDay: now.day,
                  defaultMonth: now.month,
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
            .whereType<Map>()
            .map((item) => BirthdayModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      final cached = await StorageService.getCachedBirthdays('upcoming');
      if (cached != null) {
        return cached
            .whereType<Map>()
            .map((item) => BirthdayModel.fromJson(Map<String, dynamic>.from(item)))
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

      final list = (response is List)
          ? response
          : ((response is Map && response['data'] is List)
              ? (response['data'] as List)
              : null);

      if (list != null) {
        await StorageService.saveCachedBirthdays('calendar', list);
        return _extractBirthdays(list);
      }

      final extracted = _extractBirthdays(response);
      return extracted;
    } catch (_) {}

    final cached = await StorageService.getCachedBirthdays('calendar');
    if (cached != null) {
      return _extractBirthdays(cached);
    }
    return [];
  }

  static List<BirthdayModel> _extractBirthdays(dynamic data) {
    final List<BirthdayModel> results = [];

    if (data == null) return results;

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final mapItem = Map<String, dynamic>.from(item);

          final monthNum = int.tryParse(mapItem['month_number']?.toString() ?? '') ??
              int.tryParse(mapItem['monthNumber']?.toString() ?? '') ??
              int.tryParse(mapItem['month']?.toString() ?? '');
          final monthName = mapItem['month_name'] ??
              mapItem['monthName'] ??
              mapItem['name'] ??
              (mapItem['month'] is String ? mapItem['month'] : null);
          final resolvedMonth = monthNum ?? _monthNameToNumber(monthName?.toString());

          final dynamic birthdaysList = mapItem['birthdays'] ??
              mapItem['users'] ??
              mapItem['collaborators'] ??
              mapItem['items'] ??
              mapItem['colaboradores'];

          if (birthdaysList is List) {
            for (final b in birthdaysList) {
              if (b is Map) {
                final bMap = Map<String, dynamic>.from(b);
                final dayNum = int.tryParse(bMap['day_number']?.toString() ?? '') ??
                    int.tryParse(bMap['dayNumber']?.toString() ?? '') ??
                    int.tryParse(bMap['day']?.toString() ?? '');
                final mNum = int.tryParse(bMap['month_number']?.toString() ?? '') ??
                    int.tryParse(bMap['month']?.toString() ?? '') ??
                    resolvedMonth;
                results.add(BirthdayModel.fromJson(bMap, defaultMonth: mNum, defaultDay: dayNum));
              }
            }
          } else if (mapItem['days'] is List) {
            for (final dayItem in (mapItem['days'] as List)) {
              if (dayItem is Map) {
                final dayMap = Map<String, dynamic>.from(dayItem);
                final dayNum = int.tryParse(dayMap['day_number']?.toString() ?? '') ??
                    int.tryParse(dayMap['dayNumber']?.toString() ?? '') ??
                    int.tryParse(dayMap['day']?.toString() ?? '');
                final dayUsers = dayMap['users'] ?? dayMap['birthdays'] ?? dayMap['collaborators'];
                if (dayUsers is List) {
                  for (final u in dayUsers) {
                    if (u is Map) {
                      results.add(BirthdayModel.fromJson(
                        Map<String, dynamic>.from(u),
                        defaultMonth: resolvedMonth,
                        defaultDay: dayNum,
                      ));
                    }
                  }
                }
              }
            }
          } else {
            // Elemento directo de usuario/cumpleañero
            final dayNum = int.tryParse(mapItem['day_number']?.toString() ?? '') ??
                int.tryParse(mapItem['dayNumber']?.toString() ?? '') ??
                int.tryParse(mapItem['day']?.toString() ?? '');
            results.add(BirthdayModel.fromJson(mapItem, defaultMonth: resolvedMonth, defaultDay: dayNum));
          }
        }
      }
    } else if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);
      if (mapData['data'] != null) {
        return _extractBirthdays(mapData['data']);
      }
      if (mapData['months'] != null) {
        return _extractBirthdays(mapData['months']);
      }

      mapData.forEach((key, value) {
        final monthNum = int.tryParse(key) ?? _monthNameToNumber(key);
        if (value is List) {
          for (final item in value) {
            if (item is Map) {
              final itemMap = Map<String, dynamic>.from(item);
              final dayNum = int.tryParse(itemMap['day_number']?.toString() ?? '') ??
                  int.tryParse(itemMap['day']?.toString() ?? '');
              results.add(BirthdayModel.fromJson(itemMap, defaultMonth: monthNum, defaultDay: dayNum));
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
