import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/users_service.dart';
import '../../services/api_client.dart';
import '../qr/qr_display_screen.dart';

class SupervisorsTab extends StatefulWidget {
  const SupervisorsTab({super.key});

  @override
  State<SupervisorsTab> createState() => _SupervisorsTabState();
}

class _SupervisorsTabState extends State<SupervisorsTab> {
  bool _isLoading = true;
  int _activeSupervisorsCount = 0;
  int _maxSupervisors = 3;
  int _availableSlots = 3;
  List<dynamic> _supervisorsList = [];
  List<UserModel> _allUsers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supData = await UsersService.getSupervisors();
      final usersData = await UsersService.findAll();

      if (mounted) {
        setState(() {
          _activeSupervisorsCount = supData['current_count'] is int ? supData['current_count'] : 0;
          _maxSupervisors = supData['max_supervisors'] is int ? supData['max_supervisors'] : 3;
          _availableSlots = supData['available_slots'] is int ? supData['available_slots'] : 3;
          _supervisorsList = supData['supervisors'] is List ? supData['supervisors'] : [];
          _allUsers = usersData;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar supervisores: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmRevoke(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revocar Cargo de Supervisor'),
        content: Text(
          '¿Estás seguro de que deseas revocar a $name? Volverá a ser usuario regular (EMPLOYEE).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, Revocar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await UsersService.revokeSupervisor(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Supervisor revocado exitosamente.'),
            backgroundColor: const Color(0xFF2D5E2A),
          ),
        );
        _loadData();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Supervisores y Personal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // Tarjeta de Cupos de Supervisores
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 10,
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
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.shield_rounded, color: Color(0xFF9333EA), size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Cupos de Supervisores',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              'Límite institucional estricto: 3',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _availableSlots > 0
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_activeSupervisorsCount / $_maxSupervisors',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _availableSlots > 0
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _activeSupervisorsCount / _maxSupervisors,
                                minHeight: 8,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _availableSlots > 0 ? const Color(0xFF9333EA) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _availableSlots > 0
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const QrDisplayScreen(
                                              mode: QrMode.supervisorAssignment,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.qr_code_rounded, size: 20),
                                label: Text(
                                  _availableSlots > 0
                                      ? 'Generar QR para Nombrar Supervisor'
                                      : 'Límite de 3 Supervisores Alcanzado',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Lista de Supervisores Activos
                      const Text(
                        'Supervisores Activos Designados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      if (_supervisorsList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Aún no hay supervisores designados. Puedes generar un QR para que un colaborador ascienda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        ..._supervisorsList.map((s) {
                          final id = s['id']?.toString() ?? '';
                          final name = s['full_name']?.toString() ?? 'Sin nombre';
                          final email = s['email']?.toString() ?? '';
                          final position = s['position']?.toString() ?? 'Supervisor';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF9333EA).withValues(alpha: 0.15),
                                  child: const Icon(Icons.shield_rounded, color: Color(0xFF9333EA), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        position,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF9333EA)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444)),
                                  tooltip: 'Revocar cargo',
                                  onPressed: () => _confirmRevoke(id, name),
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Directorio General de Usuarios en BD
                      Text(
                        'Directorio Institucional en BD (${_allUsers.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ..._allUsers.map((u) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                child: Text(
                                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF2D5E2A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      u.email,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: u.isAdmin
                                      ? const Color(0xFFFEE2E2)
                                      : (u.isSupervisor ? const Color(0xFFF3E8FF) : const Color(0xFFDCFCE7)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  u.role.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: u.isAdmin
                                        ? const Color(0xFFDC2626)
                                        : (u.isSupervisor ? const Color(0xFF9333EA) : const Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
