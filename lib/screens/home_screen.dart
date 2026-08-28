import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/birthday_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/birthday_service.dart';
import '../services/storage_service.dart';
import '../widgets/leaf_logo.dart';
import 'admin_users_screen.dart';
import 'delegations_screen.dart';
import 'historial_screen.dart';
import 'institutions_events_resources_screen.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';
import 'projects_screen.dart';
import 'reports_screen.dart';
import 'schedules_screen.dart';
import 'settings_screen.dart';

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
  bool _isLoadingHistory = false;
  String? _historyError;

  // Birthdays State
  List<BirthdayModel> _birthdaysList = [];
  bool _isLoadingBirthdays = false;
  String? _birthdaysError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserProfile();
    _fetchHistory();
    _fetchBirthdays();
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
      final birthdays = await BirthdayService.getUpcomingBirthdays();
      if (mounted) {
        setState(() {
          _birthdaysList = birthdays;
          _isLoadingBirthdays = false;
        });
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
                Text('Registrando marcación...', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Default IIAP Iquitos coordinates as specified by DTO requirements
      await AttendanceService.markAttendance(
        type: type,
        latitude: -3.7491,
        longitude: -73.2538,
        observations: type == 'CHECK_IN' ? 'Ingreso desde app móvil' : 'Salida desde app móvil',
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        final isCheckIn = type == 'CHECK_IN';
        _showSuccessDialog(
          title: isCheckIn ? 'Ingreso Registrado' : 'Salida Registrada',
          message: isCheckIn
              ? 'Se ha registrado la entrada con éxito en el servidor.'
              : 'Se ha registrado la salida con éxito en el servidor.',
          icon: Icons.check_circle_outline,
          color: isCheckIn ? const Color(0xFF2D5E2A) : const Color(0xFFD97706),
        );

        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        final errorMessage = e is ApiException ? e.message : 'Ocurrió un error al registrar marcación.';
        _showErrorDialog(errorMessage);
      }
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: const Row(
          children: [
            LeafLogo(size: 26, color: Color(0xFF2D5E2A)),
            SizedBox(width: 8),
            Text(
              'IIAP Asistencia',
              style: TextStyle(
                color: Color(0xFF1E4720),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1E4720)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No tienes nuevas notificaciones'),
                  duration: Duration(seconds: 2),
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

  Widget _buildDrawer() {
    final role = _currentUser?.role ?? 'EMPLOYEE';
    final isAdmin = role == 'ADMIN' || role == 'SUPERADMIN';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D5E2A), Color(0xFF386641)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              _currentUser?.fullName ?? 'Usuario IIAP',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentUser?.email ?? 'usuario@iiap.gob.pe'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ROL: $role',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _currentUser?.fullName.isNotEmpty == true
                    ? _currentUser!.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5E2A)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF2D5E2A)),
            title: const Text('Editar Mi Perfil'),
            onTap: () async {
              Navigator.pop(context);
              if (_currentUser != null) {
                final updated = await Navigator.push<UserModel>(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileEditScreen(user: _currentUser!)),
                );
                if (updated != null) {
                  setState(() => _currentUser = updated);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF2D5E2A)),
            title: const Text('Mi Historial de Actividades'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialScreen(isAdminView: false)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2D5E2A)),
            title: const Text('Mis Delegaciones de Escaneo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DelegationsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D5E2A)),
            title: const Text('Reportes y Notificaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            },
          ),
          if (isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'PANEL DE ADMINISTRACIÓN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF2D5E2A)),
              title: const Text('Gestión de Usuarios y Roles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time_rounded, color: Color(0xFF2D5E2A)),
              title: const Text('Horarios de Trabajo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_special_rounded, color: Color(0xFF2D5E2A)),
              title: const Text('Gestión de Proyectos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_rounded, color: Color(0xFF2D5E2A)),
              title: const Text('Sedes, Eventos y Recursos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InstitutionsEventsResourcesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF2D5E2A)),
              title: const Text('Auditoría Global del Sistema'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialScreen(isAdminView: true)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFF2D5E2A)),
              title: const Text('Ajustes del Sistema'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 1: INICIO (Registrar Ingreso y Registrar Salida) ---
  Widget _buildInicioTab() {
    final userName = _currentUser?.fullName.split(' ').first ?? 'Investigador';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de bienvenida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5E2A), Color(0xFF386641)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D5E2A).withValues(alpha: 0.2),
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
                  'Registra tu asistencia diaria de manera rápida y segura.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Control de Asistencia',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E4720),
            ),
          ),
          const SizedBox(height: 16),

          // Botón 1: Registrar Ingreso
          _buildActionButton(
            title: 'Registrar Ingreso',
            subtitle: 'Marca la hora de inicio de tu jornada laboral',
            icon: Icons.login_rounded,
            primaryColor: const Color(0xFF2D5E2A),
            accentColor: const Color(0xFFC7F3BF),
            onTap: () => _handleMarkAttendance('CHECK_IN'),
          ),
          const SizedBox(height: 16),

          // Botón 2: Registrar Salida
          _buildActionButton(
            title: 'Registrar Salida',
            subtitle: 'Marca la hora de término de tu jornada laboral',
            icon: Icons.logout_rounded,
            primaryColor: const Color(0xFFD97706),
            accentColor: const Color(0xFFFEF3C7),
            onTap: () => _handleMarkAttendance('CHECK_OUT'),
          ),
        ],
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: primaryColor.withValues(alpha: 0.1),
        highlightColor: primaryColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E6E3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 28),
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
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 2: REGISTRO (Historial de Asistencias) ---
  Widget _buildRegistroTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5E2A)),
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
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5E2A),
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
      color: const Color(0xFF2D5E2A),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _historyList.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _historyList[index];
          final isCheckIn = item.type == 'CHECK_IN';
          final title = isCheckIn ? 'Ingreso' : 'Salida';
          final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
          final color = isCheckIn ? const Color(0xFF2D5E2A) : const Color(0xFFD97706);
          final formattedDate = _formatTimestamp(item.timestamp);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E6E3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
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
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E4720),
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (item.observations != null && item.observations!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.observations!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 3: CUMPLEAÑOS ---
  Widget _buildCumpleanosTab() {
    if (_isLoadingBirthdays) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5E2A)),
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
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchBirthdays,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5E2A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_birthdaysList.isEmpty) {
      return _buildEmptyStateView(
        icon: Icons.cake_outlined,
        title: 'Sección de Cumpleaños',
        subtitle: 'No hay cumpleaños próximos registrados este mes.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBirthdays,
      color: const Color(0xFF2D5E2A),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _birthdaysList.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _birthdaysList[index];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E6E3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFC7F3BF),
                  child: Text(
                    item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'I',
                    style: const TextStyle(color: Color(0xFF1E4720), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4720),
                        ),
                      ),
                      if (item.position != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.position!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.cake, color: Color(0xFFD97706), size: 22),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- TAB 4: PERFIL ---
  Widget _buildPerfilTab() {
    final user = _currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E6E3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D5E2A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user != null && user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'I',
                      style: const TextStyle(
                        color: Color(0xFF9FE080),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.fullName ?? 'Investigador IIAP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E4720),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'investigador@iiap.gob.pe',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7F3BF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role ?? 'EMPLOYEE',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4720),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E6E3)),
            ),
            child: Column(
              children: [
                _buildProfileItem(
                  icon: Icons.work_outline,
                  title: 'Cargo / Posición',
                  value: user?.position ?? 'No especificado',
                ),
                const Divider(height: 1, indent: 54, endIndent: 16),
                _buildProfileItem(
                  icon: Icons.business_outlined,
                  title: 'Departamento',
                  value: user?.department ?? 'No especificado',
                ),
                const Divider(height: 1, indent: 54, endIndent: 16),
                _buildProfileItem(
                  icon: Icons.badge_outlined,
                  title: 'Documento de Identidad',
                  value: user?.documentNumber ?? 'No registrado',
                ),
                const Divider(height: 1, indent: 54, endIndent: 16),
                _buildProfileItem(
                  icon: Icons.phone_outlined,
                  title: 'Teléfono',
                  value: user?.phoneNumber ?? 'No registrado',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF2D5E2A)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
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
                color: const Color(0xFFC7F3BF).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF2D5E2A)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4720),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildCustomBottomNavigationBar() {
    final items = [
      _NavItemData(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Inicio'),
      _NavItemData(icon: Icons.fingerprint, selectedIcon: Icons.fingerprint, label: 'Registro'),
      _NavItemData(icon: Icons.cake_outlined, selectedIcon: Icons.cake, label: 'Cumpleaños'),
      _NavItemData(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFC7F3BF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        key: ValueKey<bool>(isSelected),
                        color: isSelected ? const Color(0xFF1E4720) : const Color(0xFF7A8A7D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF1E4720) : const Color(0xFF7A8A7D),
                      ),
                      child: Text(item.label),
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

  void _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
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
                backgroundColor: color,
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
