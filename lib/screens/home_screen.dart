import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/birthday_model.dart';
import '../models/today_attendance_status_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/birthday_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../widgets/leaf_logo.dart';
import '../services/location_service.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/report_pdf_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'user_courses_screen.dart';
import 'user_projects_screen.dart';
import 'user_videos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  
  // History State
  List<AttendanceModel> _historyList = [];
  TodayAttendanceStatusModel? _todayStatus;
  bool _isLoadingHistory = false;
  String? _historyError;

  // Birthdays State
  List<BirthdayModel> _todayBirthdays = [];
  List<BirthdayModel> _upcomingBirthdays = [];
  List<BirthdayModel> _calendarBirthdays = [];
  String _selectedBirthdayMonth = 'TODOS';
  final TextEditingController _birthdaySearchCtrl = TextEditingController();
  String _birthdaySearchQuery = '';
  bool _isLoadingBirthdays = false;
  String? _birthdaysError;

  // Estado de red y sincronización Offline / Online
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;
  Timer? _connectivityTimer;

  // Turnos de Trabajo: MORNING (8:30 - 13:00) | AFTERNOON (13:00 - 18:30)
  String _selectedShift = DateTime.now().hour < 13 ? 'MORNING' : 'AFTERNOON';

  String get _shiftDisplayName => _selectedShift == 'MORNING' ? 'Turno Mañana' : 'Turno Tarde';
  String get _shiftScheduleText => _selectedShift == 'MORNING' ? '8:30 AM – 1:00 PM' : '1:00 PM – 6:30 PM';

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkConnectivity());
    _loadInitialData();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _birthdaySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final pending = await StorageService.getPendingAttendances();
    final isAlive = await ApiService.checkServerHealth();
    if (mounted) {
      setState(() {
        _isOnline = isAlive;
        _pendingSyncCount = pending.length;
      });
    }
  }

  Future<void> _updatePendingCount() async {
    await _checkConnectivity();
  }

  Future<void> _loadInitialData() async {
    await _loadUserProfile();
    _fetchTodayStatus();
    _fetchHistory();
    _fetchBirthdays();
    _syncPendingAttendances();
  }

  Future<void> _syncPendingAttendances() async {
    try {
      final synced = await AttendanceService.syncPendingAttendances();
      await _updatePendingCount();
      if (synced > 0 && mounted) {
        _fetchTodayStatus();
        _fetchHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se sincronizaron $synced marcación(es) pendientes con el servidor.'),
            backgroundColor: const Color(0xFF2D5E2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted && _pendingSyncCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las marcaciones están sincronizadas con el servidor.'),
            backgroundColor: Color(0xFF2D5E2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchTodayStatus() async {
    try {
      final status = await AttendanceService.getTodayStatus(shift: _selectedShift);
      if (mounted) {
        setState(() {
          _todayStatus = status;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserProfile() async {
    final cachedUser = await StorageService.getUser();
    if (cachedUser != null && mounted) {
      setState(() {
        _currentUser = cachedUser;
      });
    }

    try {
      final user = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final history = await AttendanceService.getMyHistory();
      if (mounted) {
        setState(() {
          _historyList = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _historyError = e is ApiException ? e.message : 'No se pudo cargar el historial.';
        });
      }
    }
  }

  Future<void> _fetchBirthdays() async {
    setState(() {
      _isLoadingBirthdays = true;
      _birthdaysError = null;
    });

    try {
      final todayBirthdays = await BirthdayService.getTodayBirthdays();
      final upcomingBirthdays = await BirthdayService.getUpcomingBirthdays();
      final calendarBirthdays = await BirthdayService.getCalendarBirthdays();
      if (mounted) {
        // Consolidar todos los cumpleaños asegurando que ningún colaborador de la BD quede fuera
        final Map<String, BirthdayModel> allMap = {};
        for (final b in calendarBirthdays) {
          final key = b.id.isNotEmpty ? b.id : '${b.fullName}_${b.month}_${b.day}';
          allMap[key] = b;
        }
        for (final b in upcomingBirthdays) {
          final key = b.id.isNotEmpty ? b.id : '${b.fullName}_${b.month}_${b.day}';
          allMap.putIfAbsent(key, () => b);
        }
        for (final b in todayBirthdays) {
          final key = b.id.isNotEmpty ? b.id : '${b.fullName}_${b.month}_${b.day}';
          allMap.putIfAbsent(key, () => b);
        }

        final combinedCalendar = allMap.values.toList();

        // Determinar cumpleañeros de hoy (de endpoint /today o chequeando mes y día actual)
        List<BirthdayModel> effectiveToday = List.from(todayBirthdays);
        if (effectiveToday.isEmpty) {
          final now = DateTime.now();
          effectiveToday = combinedCalendar
              .where((b) => b.computedIsToday || (b.month == now.month && b.day == now.day))
              .toList();
        }

        setState(() {
          _todayBirthdays = effectiveToday;
          _upcomingBirthdays = upcomingBirthdays;
          _calendarBirthdays = combinedCalendar.isNotEmpty ? combinedCalendar : upcomingBirthdays;
          _isLoadingBirthdays = false;
        });

        if (effectiveToday.isNotEmpty) {
          NotificationService.checkAndNotifyBirthdays(effectiveToday);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBirthdays = false;
          _birthdaysError = e is ApiException ? e.message : 'No se pudieron cargar los cumpleaños.';
        });
      }
    }
  }

  Future<void> _handleMarkAttendance(String type) async {
    final isCheckIn = type == 'CHECK_IN';
    final typeLabel = isCheckIn ? 'Ingreso' : 'Salida';
    final actionColor = isCheckIn ? const Color(0xFF2D5E2A) : const Color(0xFFD97706);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
              color: actionColor,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Confirmar $typeLabel?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: actionColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de registrar tu Marcación de $typeLabel para el $_shiftDisplayName ($_shiftScheduleText)?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sí, Registrar $typeLabel',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Autenticación Biométrica obligatoria (Huella Dactilar / Face ID)
    final isBiometricValid = await BiometricService.authenticate(
      localizedReason: 'Por favor confirma tu identidad con tu huella digital para registrar tu $typeLabel',
    );
    if (!isBiometricValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticación biométrica no completada o cancelada. No se registró la asistencia.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2D5E2A)),
                SizedBox(height: 16),
                Text('Obteniendo ubicación GPS en tiempo real...', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );

    // Obtener ubicación GPS real del dispositivo
    final locationRes = await LocationService.getCurrentLocation();
    if (!locationRes.success || locationRes.position == null) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de progreso
        _showErrorDialog(locationRes.errorMessage ?? 'No se pudo obtener la ubicación GPS.');
      }
      return;
    }

    final realLat = locationRes.position!.latitude;
    final realLng = locationRes.position!.longitude;
    final distanceMeters = LocationService.getDistanceToSedeCentral(realLat, realLng).round();

    final now = DateTime.now();
    final recordedAtIso = now.toIso8601String();

    try {
      final response = await AttendanceService.markAttendance(
        type: type,
        shift: _selectedShift,
        latitude: realLat,
        longitude: realLng,
        recordedAt: recordedAtIso,
        observations: type == 'CHECK_IN'
            ? 'Ingreso registrado en Sede Central IIAP ($_shiftDisplayName) - GPS: ${distanceMeters}m'
            : 'Salida registrada en Sede Central IIAP ($_shiftDisplayName) - GPS: ${distanceMeters}m',
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        final isCheckIn = type == 'CHECK_IN';
        final message = (response is Map && response['message'] != null)
            ? response['message'].toString()
            : (isCheckIn
                ? 'Ingreso registrado correctamente para el $_shiftDisplayName'
                : 'Salida registrada correctamente para el $_shiftDisplayName');

        final data = (response is Map && response['data'] is Map<String, dynamic>)
            ? (response['data'] as Map<String, dynamic>)
            : null;

        _showDetailedAttendanceDialog(
          title: isCheckIn ? '¡Ingreso Registrado!' : '¡Salida Registrada!',
          message: message,
          time: data?['time']?.toString() ?? '',
          locationName: data?['location_name']?.toString() ?? 'Sede Central IIAP - Av. Quiñones km 2.5, Iquitos',
          distance: data?['distance_meters'] != null
              ? '${data!['distance_meters']} m de la Sede Central'
              : 'Dentro del radio de 1000m',
          dateFormatted: data?['date_formatted']?.toString() ?? '',
          status: data?['status']?.toString() ?? 'ON_TIME',
          isCheckIn: isCheckIn,
          shiftName: '$_shiftDisplayName ($_shiftScheduleText)',
          onConfirm: () {
            if (data != null) {
              try {
                final newRecord = AttendanceModel.fromJson(data);
                setState(() {
                  _historyList.removeWhere((h) => h.id == newRecord.id);
                  _historyList.insert(0, newRecord);
                });
              } catch (_) {
                setState(() {
                  _historyList.insert(
                    0,
                    AttendanceModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userId: _currentUser?.id ?? '',
                      timestamp: DateTime.now().toIso8601String(),
                      type: type,
                      status: data['status']?.toString() ?? 'ON_TIME',
                      latitude: AttendanceService.sedeCentralLatitude,
                      longitude: AttendanceService.sedeCentralLongitude,
                      observations: type == 'CHECK_IN'
                          ? 'Ingreso registrado en Sede Central IIAP ($_shiftDisplayName)'
                          : 'Salida registrada en Sede Central IIAP ($_shiftDisplayName)',
                    ),
                  );
                });
              }
            } else {
              setState(() {
                _historyList.insert(
                  0,
                  AttendanceModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: _currentUser?.id ?? '',
                    timestamp: DateTime.now().toIso8601String(),
                    type: type,
                    status: 'ON_TIME',
                    latitude: AttendanceService.sedeCentralLatitude,
                    longitude: AttendanceService.sedeCentralLongitude,
                    observations: type == 'CHECK_IN'
                        ? 'Ingreso registrado en Sede Central IIAP ($_shiftDisplayName)'
                        : 'Salida registrada en Sede Central IIAP ($_shiftDisplayName)',
                  ),
                );
              });
            }

            if (!isCheckIn && _selectedShift == 'MORNING') {
              setState(() {
                _selectedShift = 'AFTERNOON';
              });
            }

            _fetchTodayStatus();
            _fetchHistory();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        final isNetworkError = e is ApiException &&
            (e.message.toLowerCase().contains('conexión') ||
             e.message.toLowerCase().contains('comunicación') ||
             e.message.toLowerCase().contains('servidor') ||
             e.statusCode == null);

        if (isNetworkError) {
          final now = DateTime.now();
          final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          final formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

          final offlineData = <String, dynamic>{
            'type': type,
            'shift': _selectedShift,
            'latitude': realLat,
            'longitude': realLng,
            'verification_method': 'MANUAL',
            'observations': type == 'CHECK_IN'
                ? 'Ingreso (Modo Offline) en Sede Central IIAP ($_shiftDisplayName) - GPS: ${distanceMeters}m'
                : 'Salida (Modo Offline) en Sede Central IIAP ($_shiftDisplayName) - GPS: ${distanceMeters}m',
            'recorded_at': recordedAtIso,
          };

          await StorageService.savePendingAttendance(offlineData);
          await _updatePendingCount();

          final offlineRecord = AttendanceModel(
            id: 'offline_${now.millisecondsSinceEpoch}',
            userId: _currentUser?.id ?? '',
            timestamp: now.toIso8601String(),
            type: type,
            status: 'PENDING_SYNC',
            latitude: AttendanceService.sedeCentralLatitude,
            longitude: AttendanceService.sedeCentralLongitude,
            observations: 'Marcación Offline (Pendiente de sincronizar)',
          );

          final markRecord = TodayMarkRecord(
            id: 'offline_${now.millisecondsSinceEpoch}',
            time: formattedTime,
            timestamp: now.toIso8601String(),
            status: 'ON_TIME',
            observations: 'Marcación Offline',
          );

          setState(() {
            _historyList.insert(0, offlineRecord);
            if (isCheckIn) {
              _todayStatus = TodayAttendanceStatusModel(
                date: formattedDate,
                dayFormatted: 'Hoy',
                hasCheckedIn: true,
                checkIn: markRecord,
                hasCheckedOut: _todayStatus?.hasCheckedOut ?? false,
                checkOut: _todayStatus?.checkOut,
              );
            } else {
              _todayStatus = TodayAttendanceStatusModel(
                date: formattedDate,
                dayFormatted: 'Hoy',
                hasCheckedIn: _todayStatus?.hasCheckedIn ?? true,
                checkIn: _todayStatus?.checkIn,
                hasCheckedOut: true,
                checkOut: markRecord,
              );
            }
          });

          _showDetailedAttendanceDialog(
            title: isCheckIn ? '¡Ingreso Guardado Offline!' : '¡Salida Guardada Offline!',
            message: 'El servidor no está activo en este momento. Tu marcación ha sido guardada en tu dispositivo y se sincronizará automáticamente cuando se conecte al servidor.',
            time: formattedTime,
            locationName: 'Sede Central IIAP (Modo Offline)',
            distance: 'Dentro del radio de 1000m',
            dateFormatted: formattedDate,
            status: 'GUARDADO LOCAL',
            isCheckIn: isCheckIn,
            shiftName: '$_shiftDisplayName ($_shiftScheduleText)',
            onConfirm: () {
              if (!isCheckIn && _selectedShift == 'MORNING') {
                setState(() {
                  _selectedShift = 'AFTERNOON';
                });
              }
            },
          );
        } else {
          final errorMessage = e is ApiException ? e.message : 'Ocurrió un error al registrar marcación.';
          _showErrorDialog(errorMessage);
        }
      }
    }
  }

  Future<void> _exportPdfReport() async {
    if (_currentUser == null) {
      _showErrorDialog('No se pudo cargar la información del colaborador para generar el reporte.');
      return;
    }

    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final currentMonth = months[DateTime.now().month - 1];
    final currentYear = DateTime.now().year;

    try {
      await ReportPdfService.exportMonthlyReport(
        user: _currentUser!,
        historyList: _historyList,
        monthName: currentMonth,
        year: currentYear,
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al exportar reporte en PDF: ${e.toString()}');
      }
    }
  }

  Widget _buildNetworkStatusBadge(bool isDark) {
    if (_isSyncing) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF3B82F6)),
            ),
            SizedBox(width: 5),
            Text(
              'Sincronizando...',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
            ),
          ],
        ),
      );
    }

    final isAllSynced = _isOnline && _pendingSyncCount == 0;

    if (isAllSynced) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🟢 En línea: Conexión activa y todas las marcaciones sincronizadas.'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14532D) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF22C55E), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'En línea (Sincronizado)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Modo Offline con marcaciones pendientes o servidor desconectado
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _handleManualSync,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _pendingSyncCount > 0
                  ? 'Modo Offline ($_pendingSyncCount pendiente${_pendingSyncCount > 1 ? "s" : ""})'
                  : 'Modo Offline',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded, size: 10, color: Colors.white),
                  SizedBox(width: 2),
                  Text(
                    'Sincronizar ahora',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleManualSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final isAlive = await ApiService.checkServerHealth();
      if (!isAlive) {
        if (mounted) {
          setState(() {
            _isOnline = false;
            _isSyncing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El servidor backend no está disponible en este momento. Las marcaciones se mantienen guardadas localmente.'),
              backgroundColor: Color(0xFFD97706),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final syncedCount = await AttendanceService.syncPendingAttendances();
      final pending = await StorageService.getPendingAttendances();

      if (mounted) {
        setState(() {
          _isOnline = true;
          _pendingSyncCount = pending.length;
          _isSyncing = false;
        });

        _fetchTodayStatus();
        _fetchHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncedCount > 0
                ? '¡Se sincronizaron $syncedCount marcación(es) exitosamente con el servidor!'
                : 'Conexión restablecida. Todas tus marcaciones están sincronizadas.'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error durante la sincronización: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDetailedAttendanceDialog({
    required String title,
    required String message,
    required String time,
    required String locationName,
    required String distance,
    required String dateFormatted,
    required String status,
    required bool isCheckIn,
    String? shiftName,
    VoidCallback? onConfirm,
  }) {
    final primaryColor = isCheckIn ? const Color(0xFF2D5E2A) : const Color(0xFFD97706);
    final accentBg = isCheckIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                color: primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  if (shiftName != null && shiftName.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          _selectedShift == 'MORNING' ? Icons.wb_sunny_rounded : Icons.wb_twilight_rounded,
                          size: 16,
                          color: const Color(0xFF2D5E2A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Turno: $shiftName',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E4720)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                  ],
                  if (time.isNotEmpty || dateFormatted.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Color(0xFF2D5E2A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            time.isNotEmpty ? 'Hora: $time' : dateFormatted,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationName,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              distance,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm?.call();
                },
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            LeafLogo(size: 26, color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D5E2A)),
            const SizedBox(width: 8),
            Text(
              'IIAP Asistencia',
              style: TextStyle(
                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1E4720),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          _buildNetworkStatusBadge(isDark),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.themeModeNotifier,
            builder: (context, mode, _) {
              final activeDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  activeDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: activeDark ? const Color(0xFFFFB74D) : const Color(0xFF1E4720),
                ),
                tooltip: activeDark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
                onPressed: () {
                  ThemeService.toggleDarkMode(!activeDark);
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : const Color(0xFF1E4720)),
            tooltip: 'Actualizar',
            onPressed: () {
              _loadInitialData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Actualizando información...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildInicioTab(),
            _buildRegistroTab(),
            _buildCumpleanosTab(),
            _buildPerfilTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }



  // --- TAB 1: INICIO (Registrar Ingreso, Salida y Accesos a Recursos) ---
  Widget _buildInicioTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = _currentUser?.fullName.split(' ').first ?? 'Colaborador';

    final isMorning = _selectedShift == 'MORNING';
    final currentShiftDetail = isMorning ? _todayStatus?.morning : _todayStatus?.afternoon;

    final hasIn = currentShiftDetail?.hasCheckedIn ?? (isMorning ? (_todayStatus?.hasCheckedIn ?? false) : false);
    final hasOut = currentShiftDetail?.hasCheckedOut ?? (isMorning ? (_todayStatus?.hasCheckedOut ?? false) : false);
    final checkInTime = currentShiftDetail?.checkIn?.time ?? (isMorning ? _todayStatus?.checkIn?.time : null);
    final checkOutTime = currentShiftDetail?.checkOut?.time ?? (isMorning ? _todayStatus?.checkOut?.time : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de bienvenida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF166534), const Color(0xFF0F5128)]
                    : [const Color(0xFF2D5E2A), const Color(0xFF386641)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sistema de Control de Asistencia y Recursos del IIAP.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // SELECTOR DE TURNO DE TRABAJO (MAÑANA / TARDE)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFC7F3BF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Turno de Trabajo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1E4720),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _selectedShift == 'MORNING' ? 'Turno Mañana' : 'Turno Tarde',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Botón Turno Mañana
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedShift = 'MORNING');
                          _fetchTodayStatus();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _selectedShift == 'MORNING'
                                ? (isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedShift == 'MORNING'
                                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A))
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 16,
                                    color: _selectedShift == 'MORNING'
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mañana',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: _selectedShift == 'MORNING'
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '8:30 AM – 1:00 PM',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedShift == 'MORNING'
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Botón Turno Tarde
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedShift = 'AFTERNOON');
                          _fetchTodayStatus();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _selectedShift == 'AFTERNOON'
                                ? (isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedShift == 'AFTERNOON'
                                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A))
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.wb_twilight_rounded,
                                    size: 16,
                                    color: _selectedShift == 'AFTERNOON'
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tarde',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: _selectedShift == 'AFTERNOON'
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1:00 PM – 6:30 PM',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedShift == 'AFTERNOON'
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // CARD DE ESTADO DEL DÍA Y SEDE CENTRAL IIAP
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFC7F3BF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _todayStatus?.sede?.name ?? 'Sede Central IIAP - Iquitos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1E4720),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Radio: 1000m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_todayStatus?.dayFormatted != null && _todayStatus!.dayFormatted.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _todayStatus!.dayFormatted,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                Divider(height: 18, color: isDark ? const Color(0xFF334155) : null),
                Row(
                  children: [
                    // Columna Estado Ingreso
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasIn
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasIn ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: hasIn ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)) : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ingreso',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: hasIn
                                        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                        : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasIn ? (checkInTime ?? 'Marcado') : 'Pendiente',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasIn
                                    ? (isDark ? Colors.white : const Color(0xFF166534))
                                    : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Columna Estado Salida
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasOut
                              ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasOut ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: hasOut ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)) : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Salida',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: hasOut
                                        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                        : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasOut ? (checkOutTime ?? 'Marcada') : 'Pendiente',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasOut
                                    ? (isDark ? Colors.white : const Color(0xFF92400E))
                                    : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Marcación de Asistencia',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1E4720),
            ),
          ),
          const SizedBox(height: 12),

          // Botón 1: Registrar Ingreso
          _buildActionButton(
            title: hasIn ? 'Ingreso Registrado' : 'Registrar Ingreso · $_shiftDisplayName',
            subtitle: hasIn
                ? 'Marcado a las ${checkInTime ?? "hoy"}'
                : 'Marca la hora de entrada de tu jornada ($_shiftScheduleText)',
            icon: hasIn ? Icons.check_circle : Icons.login_rounded,
            primaryColor: const Color(0xFF2D5E2A),
            accentColor: hasIn ? const Color(0xFFC7F3BF) : const Color(0xFFE8F5E9),
            onTap: () => _handleMarkAttendance('CHECK_IN'),
          ),
          const SizedBox(height: 12),

          // Botón 2: Registrar Salida
          _buildActionButton(
            title: hasOut ? 'Salida Registrada' : 'Registrar Salida · $_shiftDisplayName',
            subtitle: hasOut
                ? 'Marcada a las ${checkOutTime ?? "hoy"}'
                : 'Marca la hora de salida de tu jornada ($_shiftScheduleText)',
            icon: hasOut ? Icons.check_circle : Icons.logout_rounded,
            primaryColor: const Color(0xFFD97706),
            accentColor: hasOut ? const Color(0xFFFEF3C7) : const Color(0xFFFFF3E0),
            onTap: () => _handleMarkAttendance('CHECK_OUT'),
          ),
          const SizedBox(height: 28),

          // SECCIÓN DE ACCESOS DIRECTOS SOLICITADOS
          const Text(
            'Servicios y Recursos IIAP',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E4720),
            ),
          ),
          const SizedBox(height: 14),

          // Acceso Cursos
          _buildServiceCard(
            title: 'Cursos de Capacitación',
            subtitle: 'Explora cursos, talleres y programas formativos disponibles.',
            badgeText: 'Cursos',
            icon: Icons.school_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2D5E2A),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserCoursesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Acceso Videos
          _buildServiceCard(
            title: 'Videos Institucionales',
            subtitle: 'Visualiza grabaciones, tutoriales y material multimedia.',
            badgeText: 'Videos',
            icon: Icons.video_library_rounded,
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE65100),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserVideosScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Acceso Proyectos
          _buildServiceCard(
            title: 'Proyectos de Investigación',
            subtitle: 'Consulta el estado y avance de proyectos científicos del IIAP.',
            badgeText: 'Proyectos',
            icon: Icons.folder_special_rounded,
            iconBgColor: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProjectsScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.25) : iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: isDark ? Colors.white : iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E4720),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? iconColor.withValues(alpha: 0.25) : iconBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: isDark ? Colors.white : iconColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizable para los botones principales de Ingreso / Salida
  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGreen = primaryColor == const Color(0xFF2D5E2A);

    final displayPrimary = isDark
        ? (isGreen ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24))
        : primaryColor;
    final displayBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final displayAccentBg = isDark
        ? (isGreen ? const Color(0xFF064E3B) : const Color(0xFF78350F))
        : accentColor;

    return Material(
      color: displayBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: displayPrimary.withValues(alpha: 0.1),
        highlightColor: displayPrimary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: displayAccentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: displayPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: displayPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: displayPrimary),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 2: REGISTRO (Historial de Asistencias) ---
  Widget _buildRegistroTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingHistory) {
      return Center(
        child: CircularProgressIndicator(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                _historyError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyList.isEmpty) {
      return _buildEmptyStateView(
        icon: Icons.fingerprint,
        title: 'Historial de Registros',
        subtitle: 'Aún no cuentas con registros de asistencia registrados en el sistema.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registros (${_historyList.length})',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E4720),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _exportPdfReport,
                    icon: Icon(Icons.picture_as_pdf_rounded, size: 17, color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D5E2A)),
                    label: Text(
                      'PDF',
                      style: TextStyle(color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D5E2A), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showClearHistoryConfirmDialog,
                    icon: const Icon(Icons.delete_outline, size: 17, color: Colors.redAccent),
                    label: const Text(
                      'Borrar',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._historyList.map((item) {
            final isCheckIn = item.type == 'CHECK_IN';
            final title = isCheckIn ? 'Ingreso' : 'Salida';
            final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
            final color = isCheckIn
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A))
                : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));
            final formattedDate = _formatTimestamp(item.timestamp);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E4720),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(item.status),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatusLabel(item.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusTextColor(item.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
                          ),
                        ),
                        if (item.observations != null && item.observations!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.observations!,
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showClearHistoryConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(child: Text('¿Borrar Historial?')),
          ],
        ),
        content: const Text(
          'Esta acción borrará tus registros de asistencia de la pantalla actual.',
          style: TextStyle(fontSize: 14, color: Color(0xFF556B58)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AttendanceService.clearMyHistory();
                if (mounted) {
                  setState(() {
                    _historyList.clear();
                    _todayStatus = null;
                  });
                  _fetchTodayStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Limpiado correctamente'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2D5E2A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al borrar historial: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Borrar Historial'),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: CUMPLE 
  Widget _buildCumpleanosTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingBirthdays) {
      return Center(
        child: CircularProgressIndicator(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
      );
    }

    if (_birthdaysError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cake_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                _birthdaysError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchBirthdays,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filtrado por búsqueda y mes (Soporta Septiembre y Setiembre indistintamente)
    final monthsList = [
      'TODOS', 'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ];

    final displayList = _calendarBirthdays.where((b) {
      final matchesSearch = _birthdaySearchQuery.isEmpty ||
          b.fullName.toLowerCase().contains(_birthdaySearchQuery.toLowerCase()) ||
          (b.department != null && b.department!.toLowerCase().contains(_birthdaySearchQuery.toLowerCase())) ||
          (b.position != null && b.position!.toLowerCase().contains(_birthdaySearchQuery.toLowerCase()));

      bool matchesMonth = _selectedBirthdayMonth == 'TODOS';
      if (!matchesMonth) {
        final normSelected = _selectedBirthdayMonth.toUpperCase().replaceAll('SETIEMBRE', 'SEPTIEMBRE');
        final monthIdx = monthsList.indexOf(normSelected);
        if (monthIdx > 0) {
          matchesMonth = b.month == monthIdx;
        } else {
          final bMonthNorm = b.monthName.toUpperCase().replaceAll('SETIEMBRE', 'SEPTIEMBRE');
          matchesMonth = bMonthNorm == normSelected;
        }
      }

      return matchesSearch && matchesMonth;
    }).toList();

    // Ordenamiento cronológico anual por mes y por día
    displayList.sort((a, b) {
      final cmpMonth = a.month.compareTo(b.month);
      if (cmpMonth != 0) return cmpMonth;
      return a.day.compareTo(b.day);
    });

    return RefreshIndicator(
      onRefresh: _fetchBirthdays,
      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. SECCIÓN: CUMPLEAÑEROS DE HOY
          if (_todayBirthdays.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF78350F), const Color(0xFF92400E)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cake_rounded, color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Cumpleañeros de Hoy! 🎉',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._todayBirthdays.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFF59E0B),
                              backgroundImage: item.photoUrl != null && item.photoUrl!.isNotEmpty
                                  ? NetworkImage(item.photoUrl!)
                                  : null,
                              radius: 16,
                              child: (item.photoUrl == null || item.photoUrl!.isEmpty)
                                  ? Text(
                                      item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'C',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF78350F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. SECCIÓN: PRÓXIMOS CUMPLEAÑOS
          if (_upcomingBirthdays.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.upcoming_rounded, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Próximos Cumpleaños',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E4720),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Colaboradores que celebran su día en las próximas fechas.',
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _upcomingBirthdays.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) {
                  final up = _upcomingBirthdays[index];
                  final daysUntil = up.daysUntil ?? up.computedDaysUntil;
                  final daysText = daysUntil != null
                      ? (daysUntil == 0
                          ? '¡Hoy!'
                          : daysUntil == 1
                              ? 'Mañana'
                              : 'Faltan $daysUntil días')
                      : (up.computedIsToday ? '¡Hoy!' : up.formattedDayAndMonth);

                  return Container(
                    width: 250,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFC7F3BF), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                              backgroundImage: up.photoUrl != null && up.photoUrl!.isNotEmpty
                                  ? NetworkImage(up.photoUrl!)
                                  : null,
                              radius: 18,
                              child: (up.photoUrl == null || up.photoUrl!.isEmpty)
                                  ? Text(
                                      up.fullName.isNotEmpty ? up.fullName[0].toUpperCase() : 'C',
                                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E4720), fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                up.fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : const Color(0xFF1E4720),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  up.formattedDayAndMonth,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              daysText,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          // 3. SECCIÓN: CALENDARIO ANUAL COMPLETO
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 22),
              const SizedBox(width: 8),
              Text(
                'Calendario Anual Institucional',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E4720),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Todos los cumpleaños de la base de datos (${displayList.length} colaboradores)',
            style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),

          // Buscador de cumpleaños
          TextField(
            controller: _birthdaySearchCtrl,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
            onChanged: (val) {
              setState(() {
                _birthdaySearchQuery = val.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar cumpleañero por nombre o área...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
              prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
              suffixIcon: _birthdaySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: isDark ? Colors.white : Colors.black),
                      onPressed: () {
                        _birthdaySearchCtrl.clear();
                        setState(() => _birthdaySearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selector de Meses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: monthsList.map((m) {
                final isSelected = _selectedBirthdayMonth == m;
                final label = m == 'TODOS'
                    ? 'Todos los meses'
                    : m[0] + m.substring(1).toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
                    onSelected: (_) {
                      setState(() {
                        _selectedBirthdayMonth = m;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Cumpleañeros del Calendario
          if (displayList.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.cake_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _birthdaySearchQuery.isNotEmpty
                        ? 'No se encontraron colaboradores que coincidan con la búsqueda.'
                        : _selectedBirthdayMonth == 'TODOS'
                            ? 'No se encontraron registros de cumpleaños en la base de datos.'
                            : 'No hay cumpleaños registrados en el mes seleccionado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...displayList.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                      backgroundImage: item.photoUrl != null && item.photoUrl!.isNotEmpty
                          ? NetworkImage(item.photoUrl!)
                          : null,
                      radius: 22,
                      child: (item.photoUrl == null || item.photoUrl!.isEmpty)
                          ? Text(
                              item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'I',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E4720),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fullName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E4720),
                            ),
                          ),
                          if ((item.position != null && item.position!.trim().isNotEmpty) ||
                              (item.department != null && item.department!.trim().isNotEmpty)) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.position?.trim().isNotEmpty == true
                                  ? item.position!
                                  : item.department!,
                              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cake, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.formattedDayAndMonth,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.birthDayName != null && item.birthDayName!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nació un ${item.birthDayName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUploadProfilePhoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF2D5E2A))),
      );

      final response = await UserService.uploadProfilePhoto(filePath: image.path);

      if (mounted) {
        Navigator.pop(context); // close loader
        final newUrl = response['photo_url']?.toString() ??
            (response['user'] is Map ? response['user']['photo_url']?.toString() : null);

        if (newUrl != null && newUrl.isNotEmpty && _currentUser != null) {
          setState(() {
            _currentUser = _currentUser!.copyWith(photoUrl: newUrl);
          });
        }
        _fetchBirthdays();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Foto de perfil actualizada exitosamente.')),
              ],
            ),
            backgroundColor: Color(0xFF2D5E2A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPhotoOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cambiar Foto de Perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E4720)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2D5E2A)),
                ),
                title: const Text('Elegir de la Galería', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Selecciona una imagen desde tus fotos', style: TextStyle(fontSize: 12.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadProfilePhoto(ImageSource.gallery);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD97706)),
                ),
                title: const Text('Tomar Foto con la Cámara', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Captura una nueva foto al instante', style: TextStyle(fontSize: 12.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadProfilePhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullPhotoDialog(String? photoUrl, String? fullName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        final name = fullName ?? 'Foto de perfil';
        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                  maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: hasPhoto
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(40),
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, color: Colors.white54, size: 64),
                                SizedBox(height: 12),
                                Text(
                                  'No se pudo cargar la imagen',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: 260,
                          height: 260,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D5E2A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'C',
                              style: const TextStyle(
                                color: Color(0xFF9FE080),
                                fontSize: 96,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pellizca para acercar o alejar',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 4: PERFIL ---
  Widget _buildPerfilTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullPhotoDialog(user?.photoUrl, user?.fullName),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF15803D) : const Color(0xFF2D5E2A),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFFC7F3BF), width: 3),
                        ),
                        child: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  user.photoUrl!,
                                  fit: BoxFit.cover,
                                  width: 88,
                                  height: 88,
                                  errorBuilder: (ctx, err, stack) => Center(
                                    child: Text(
                                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'C',
                                      style: const TextStyle(
                                        color: Color(0xFF9FE080),
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  user != null && user.fullName.isNotEmpty
                                      ? user.fullName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Color(0xFF9FE080),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showPhotoOptionsBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user?.fullName ?? 'Colaborador IIAP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E4720),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'colaborador@iiap.gob.pe',
                  style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role ?? 'EMPLOYEE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E4720),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User Details List
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
            ),
            child: Column(
              children: [
                _buildProfileItem(
                  icon: Icons.work_outline,
                  title: 'Cargo / Posición',
                  value: user?.position ?? 'No especificado',
                ),
                Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? const Color(0xFF334155) : null),
                _buildProfileItem(
                  icon: Icons.business_outlined,
                  title: 'Departamento',
                  value: user?.department ?? 'No especificado',
                ),
                Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? const Color(0xFF334155) : null),
                _buildProfileItem(
                  icon: Icons.badge_outlined,
                  title: 'Documento de Identidad',
                  value: user?.documentNumber ?? 'No registrado',
                ),
                Divider(height: 1, indent: 54, endIndent: 16, color: isDark ? const Color(0xFF334155) : null),
                _buildProfileItem(
                  icon: Icons.phone_outlined,
                  title: 'Teléfono',
                  value: user?.phoneNumber ?? 'No registrado',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Edit Profile Button
          if (user != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileEditScreen(user: user)),
                  );
                  if (updated != null && mounted) {
                    setState(() => _currentUser = updated);
                  }
                },
                icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
                label: Text(
                  'Editar Datos de Mi Perfil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Settings & Preferences Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 20),
                label: const Text(
                  'Ajustes y Configuración',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable empty view
  Widget _buildEmptyStateView({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E4720),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildCustomBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NavItemData(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Inicio'),
      _NavItemData(icon: Icons.fingerprint, selectedIcon: Icons.fingerprint, label: 'Registro'),
      _NavItemData(icon: Icons.cake_outlined, selectedIcon: Icons.cake, label: 'Cumpleaños'),
      _NavItemData(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = _currentIndex == index;
          final item = items[index];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        key: ValueKey<bool>(isSelected),
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF1E4720))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8A7D)),
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF1E4720))
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8A7D)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Error de Marcación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year - $hour:$minute hrs';
    } catch (_) {
      return timestamp;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ON_TIME':
        return 'A TIEMPO';
      case 'LATE':
        return 'TARDANZA';
      case 'EARLY_DEPARTURE':
        return 'SALIDA TEMPRANA';
      case 'EXCUSED':
        return 'JUSTIFICADO';
      default:
        return status;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'ON_TIME':
        return const Color(0xFFDCFCE7);
      case 'LATE':
        return const Color(0xFFFEE2E2);
      case 'EARLY_DEPARTURE':
        return const Color(0xFFFEF3C7);
      case 'EXCUSED':
        return const Color(0xFFE0F2FE);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'ON_TIME':
        return const Color(0xFF15803D);
      case 'LATE':
        return const Color(0xFFB91C1C);
      case 'EARLY_DEPARTURE':
        return const Color(0xFFB45309);
      case 'EXCUSED':
        return const Color(0xFF0369A1);
      default:
        return const Color(0xFF4B5563);
    }
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
