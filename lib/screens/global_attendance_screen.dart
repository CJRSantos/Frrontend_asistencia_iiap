import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class GlobalAttendanceScreen extends StatefulWidget {
  const GlobalAttendanceScreen({super.key});

  @override
  State<GlobalAttendanceScreen> createState() => _GlobalAttendanceScreenState();
}

class _GlobalAttendanceScreenState extends State<GlobalAttendanceScreen> {
  List<AttendanceModel> _list = [];
  bool _isLoading = true;
  int _limit = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await AttendanceService.getAllHistory(limit: _limit);
      if (mounted) {
        setState(() {
          _list = res;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar asistencias: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ON_TIME':
        return Colors.green;
      case 'LATE':
        return Colors.orange;
      case 'EARLY_DEPARTURE':
        return Colors.amber.shade800;
      case 'EXCUSED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'ON_TIME':
        return 'A Tiempo';
      case 'LATE':
        return 'Tardanza';
      case 'EARLY_DEPARTURE':
        return 'Salida Temprana';
      case 'EXCUSED':
        return 'Justificado';
      case 'PENDING_REVIEW':
        return 'En Revisión';
      default:
        return status ?? 'Registrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Global de Asistencias'),
        backgroundColor: const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Límite de registros',
            onSelected: (val) {
              setState(() => _limit = val);
              _loadData();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 20, child: Text('Mostrar 20 registros')),
              PopupMenuItem(value: 50, child: Text('Mostrar 50 registros')),
              PopupMenuItem(value: 100, child: Text('Mostrar 100 registros')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5E2A)))
          : _list.isEmpty
              ? const Center(child: Text('No hay registros de asistencia en el sistema.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _list.length,
                  itemBuilder: (ctx, index) {
                    final item = _list[index];
                    final isCheckIn = item.type == 'CHECK_IN';
                    final color = _getStatusColor(item.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: isCheckIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                              radius: 22,
                              child: Icon(
                                isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                                color: isCheckIn ? const Color(0xFF2D5E2A) : Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.userName.isNotEmpty ? item.userName : 'Usuario Registrado',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _formatStatus(item.status),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.typeLabel} • ${item.formattedTime} - ${item.formattedDate}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  if (item.observations != null && item.observations!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Obs: ${item.observations}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
