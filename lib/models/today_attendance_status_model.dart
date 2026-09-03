class SedeInfo {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int allowedRadiusMeters;

  SedeInfo({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.allowedRadiusMeters,
  });

  factory SedeInfo.fromJson(Map<String, dynamic> json) {
    return SedeInfo(
      name: json['name'] as String? ?? 'Sede Principal IIAP - Iquitos',
      address: json['address'] as String? ?? 'Av. José Abelardo Quiñones km 2.5, San Juan Bautista, Loreto',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -3.7719,
      longitude: (json['longitude'] as num?)?.toDouble() ?? -73.2690,
      allowedRadiusMeters: (json['allowed_radius_meters'] as num?)?.toInt() ?? 1000,
    );
  }
}

class TodayMarkRecord {
  final String id;
  final String time;
  final String timestamp;
  final String status;
  final String? observations;

  TodayMarkRecord({
    required this.id,
    required this.time,
    required this.timestamp,
    required this.status,
    this.observations,
  });

  factory TodayMarkRecord.fromJson(Map<String, dynamic> json) {
    return TodayMarkRecord(
      id: json['id'] as String? ?? '',
      time: json['time'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      status: json['status'] as String? ?? 'ON_TIME',
      observations: json['observations'] as String?,
    );
  }
}

class ShiftDetail {
  final String shift;
  final String shiftLabel;
  final bool hasCheckedIn;
  final TodayMarkRecord? checkIn;
  final bool hasCheckedOut;
  final TodayMarkRecord? checkOut;

  ShiftDetail({
    required this.shift,
    required this.shiftLabel,
    required this.hasCheckedIn,
    this.checkIn,
    required this.hasCheckedOut,
    this.checkOut,
  });

  factory ShiftDetail.fromJson(Map<String, dynamic> json) {
    return ShiftDetail(
      shift: json['shift'] as String? ?? 'MORNING',
      shiftLabel: json['shift_label'] as String? ?? json['shiftLabel'] as String? ?? '',
      hasCheckedIn: json['has_checked_in'] as bool? ?? json['hasCheckedIn'] as bool? ?? false,
      checkIn: json['check_in'] is Map<String, dynamic>
          ? TodayMarkRecord.fromJson(json['check_in'])
          : (json['checkIn'] is Map<String, dynamic> ? TodayMarkRecord.fromJson(json['checkIn']) : null),
      hasCheckedOut: json['has_checked_out'] as bool? ?? json['hasCheckedOut'] as bool? ?? false,
      checkOut: json['check_out'] is Map<String, dynamic>
          ? TodayMarkRecord.fromJson(json['check_out'])
          : (json['checkOut'] is Map<String, dynamic> ? TodayMarkRecord.fromJson(json['checkOut']) : null),
    );
  }
}

class TodayAttendanceStatusModel {
  final String date;
  final String dayFormatted;
  final SedeInfo? sede;
  final bool hasCheckedIn;
  final TodayMarkRecord? checkIn;
  final bool hasCheckedOut;
  final TodayMarkRecord? checkOut;
  final ShiftDetail? morning;
  final ShiftDetail? afternoon;

  TodayAttendanceStatusModel({
    required this.date,
    required this.dayFormatted,
    this.sede,
    required this.hasCheckedIn,
    this.checkIn,
    required this.hasCheckedOut,
    this.checkOut,
    this.morning,
    this.afternoon,
  });

  factory TodayAttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceStatusModel(
      date: json['date'] as String? ?? '',
      dayFormatted: json['day_formatted'] as String? ?? json['dayFormatted'] as String? ?? '',
      sede: json['sede'] is Map<String, dynamic> ? SedeInfo.fromJson(json['sede']) : null,
      hasCheckedIn: json['has_checked_in'] as bool? ?? json['hasCheckedIn'] as bool? ?? false,
      checkIn: json['check_in'] is Map<String, dynamic>
          ? TodayMarkRecord.fromJson(json['check_in'])
          : (json['checkIn'] is Map<String, dynamic> ? TodayMarkRecord.fromJson(json['checkIn']) : null),
      hasCheckedOut: json['has_checked_out'] as bool? ?? json['hasCheckedOut'] as bool? ?? false,
      checkOut: json['check_out'] is Map<String, dynamic>
          ? TodayMarkRecord.fromJson(json['check_out'])
          : (json['checkOut'] is Map<String, dynamic> ? TodayMarkRecord.fromJson(json['checkOut']) : null),
      morning: json['morning'] is Map<String, dynamic> ? ShiftDetail.fromJson(json['morning']) : null,
      afternoon: json['afternoon'] is Map<String, dynamic> ? ShiftDetail.fromJson(json['afternoon']) : null,
    );
  }
}
