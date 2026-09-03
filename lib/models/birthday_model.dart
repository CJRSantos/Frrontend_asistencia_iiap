class BirthdayModel {
  final String id;
  final String fullName;
  final String? position;
  final String? department;
  final String? photoUrl;
  final String? dateOfBirth;
  final bool isToday;
  final int? daysUntil;
  final String? customFormattedDate;
  final int? explicitMonth;
  final int? explicitDay;
  final String? dayName;          // ej: "Miércoles"
  final String? birthDayName;     // ej: "Martes"
  final String? birthdayFormatted; // ej: "Miércoles, 4 de Marzo"

  BirthdayModel({
    required this.id,
    required this.fullName,
    this.position,
    this.department,
    this.photoUrl,
    this.dateOfBirth,
    this.isToday = false,
    this.daysUntil,
    this.customFormattedDate,
    this.explicitMonth,
    this.explicitDay,
    this.dayName,
    this.birthDayName,
    this.birthdayFormatted,
  });

  DateTime? get parsedDate {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) return null;
    final str = dateOfBirth!.trim();
    try {
      return DateTime.parse(str);
    } catch (_) {}

    try {
      final parts = str.split(RegExp(r'[-/T ]')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3) {
        int first = int.parse(parts[0]);
        int second = int.parse(parts[1]);
        int third = int.parse(parts[2].substring(0, parts[2].length.clamp(0, 2)));

        if (first > 1000) {
          return DateTime(first, second, third);
        }
        if (third > 1000) {
          return DateTime(third, second, first);
        }
        return DateTime(first, second, third);
      }
    } catch (_) {}
    return null;
  }

  int get month => explicitMonth ?? parsedDate?.month ?? 0;
  int get day => explicitDay ?? parsedDate?.day ?? 0;

  bool get computedIsToday {
    if (isToday) return true;
    final d = parsedDate;
    if (d != null) {
      final now = DateTime.now();
      return d.month == now.month && d.day == now.day;
    }
    if (explicitMonth != null && explicitDay != null) {
      final now = DateTime.now();
      return explicitMonth == now.month && explicitDay == now.day;
    }
    return false;
  }

  String get formattedDayAndMonth {
    if (birthdayFormatted != null && birthdayFormatted!.isNotEmpty) {
      return birthdayFormatted!;
    }
    if (customFormattedDate != null && customFormattedDate!.isNotEmpty) {
      return customFormattedDate!;
    }
    final d = parsedDate;
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    if (d != null && d.month >= 1 && d.month <= 12) {
      final base = '${d.day} de ${months[d.month]}';
      if (dayName != null && dayName!.isNotEmpty) {
        return '$dayName, $base';
      }
      return base;
    }
    if (explicitMonth != null && explicitDay != null && explicitMonth! >= 1 && explicitMonth! <= 12) {
      final base = '$explicitDay de ${months[explicitMonth!]}';
      if (dayName != null && dayName!.isNotEmpty) {
        return '$dayName, $base';
      }
      return base;
    }
    return dateOfBirth ?? 'Fecha no disponible';
  }

  String get monthName {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final m = month;
    if (m >= 1 && m <= 12) {
      return months[m];
    }
    return 'Otros';
  }

  factory BirthdayModel.fromJson(Map<String, dynamic> json, {int? defaultMonth, int? defaultDay}) {
    int? m;
    int? d;
    if (json['month'] != null) {
      m = int.tryParse(json['month'].toString());
    }
    if (json['day'] != null) {
      d = int.tryParse(json['day'].toString());
    }
    m ??= defaultMonth;
    d ??= defaultDay;

    return BirthdayModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ??
          json['fullName']?.toString() ??
          json['name']?.toString() ??
          json['nombre']?.toString() ??
          json['nombres']?.toString() ??
          json['colaborador']?.toString() ??
          'Colaborador IIAP',
      position: json['position']?.toString() ?? json['cargo']?.toString(),
      department: json['department']?.toString() ?? json['area']?.toString(),
      photoUrl: json['photo_url']?.toString() ?? json['photoUrl']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString() ??
          json['dateOfBirth']?.toString() ??
          json['birth_date']?.toString() ??
          json['birthdate']?.toString() ??
          json['birthday']?.toString() ??
          json['fecha_nacimiento']?.toString() ??
          json['fechaNacimiento']?.toString() ??
          json['fecha']?.toString(),
      isToday: json['is_today'] as bool? ?? json['isToday'] as bool? ?? false,
      daysUntil: json['days_until'] is num
          ? (json['days_until'] as num).toInt()
          : (json['daysUntil'] is num ? (json['daysUntil'] as num).toInt() : null),
      customFormattedDate: json['formatted_date']?.toString() ?? json['formattedDate']?.toString(),
      explicitMonth: m,
      explicitDay: d,
      dayName: json['day_name']?.toString() ?? json['dayName']?.toString(),
      birthDayName: json['birth_day_name']?.toString() ?? json['birthDayName']?.toString(),
      birthdayFormatted: json['birthday_formatted']?.toString() ?? json['birthdayFormatted']?.toString(),
    );
  }
}
