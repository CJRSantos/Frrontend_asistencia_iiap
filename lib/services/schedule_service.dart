import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'users_service.dart';

class ScheduleService {
  static const String _keyPrefix = 'user_schedule_';

  /// Notificador global reactivo para que cualquier cambio de horario se actualice al instante en la UI
  static final ValueNotifier<Map<String, ScheduleModel>> schedulesNotifier =
      ValueNotifier<Map<String, ScheduleModel>>({});

  /// Carga inicial de horarios guardados
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    final Map<String, ScheduleModel> map = {};

    for (final k in keys) {
      final jsonStr = prefs.getString(k);
      if (jsonStr != null) {
        try {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final schedule = ScheduleModel.fromJson(decoded);
          map[schedule.userId] = schedule;
        } catch (_) {}
      }
    }

    schedulesNotifier.value = map;
  }

  /// Obtiene el horario asignado a un usuario
  static ScheduleModel getSchedule(String userId, {String? position}) {
    if (schedulesNotifier.value.containsKey(userId)) {
      return schedulesNotifier.value[userId]!;
    }

    // Intentar inferir de la posición guardada en la base de datos
    final fromPos = ScheduleModel.tryParseFromPosition(userId, position);
    if (fromPos != null) {
      return fromPos;
    }

    return ScheduleModel.defaultGeneral(userId);
  }

  /// Guarda el horario del usuario localmente y en el servidor
  static Future<void> saveSchedule(ScheduleModel schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(schedule.toJson());
    await prefs.setString('$_keyPrefix${schedule.userId}', jsonStr);

    // Actualizar notificador reactivo
    final updated = Map<String, ScheduleModel>.from(schedulesNotifier.value);
    updated[schedule.userId] = schedule;
    schedulesNotifier.value = updated;

    // Sincronizar con el backend en el campo position
    try {
      await UsersService.updateUser(
        schedule.userId,
        {'position': schedule.toCompactPositionString()},
      );
    } catch (_) {
      // Si falla la red se mantendrá guardado localmente de forma segura
    }
  }
}
