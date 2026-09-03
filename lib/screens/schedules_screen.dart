import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../services/schedule_service.dart';
import '../services/user_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  List<ScheduleModel> _schedules = [];
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await ScheduleService.getAllSchedules();
      final users = await UserService.getAllUsers();
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _users = users;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addSchedule() async {
    String? selectedUserId = _users.isNotEmpty ? _users.first.id : null;
    int selectedDay = 1;
    final startTimeCtrl = TextEditingController(text: '08:00');
    final endTimeCtrl = TextEditingController(text: '17:00');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Horario de Trabajo'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedUserId,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                    items: _users.map((u) {
                      return DropdownMenuItem(value: u.id, child: Text(u.fullName));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedUserId = val),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'Día de la Semana'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lunes')),
                      DropdownMenuItem(value: 2, child: Text('Martes')),
                      DropdownMenuItem(value: 3, child: Text('Miércoles')),
                      DropdownMenuItem(value: 4, child: Text('Jueves')),
                      DropdownMenuItem(value: 5, child: Text('Viernes')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 0, child: Text('Domingo')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: startTimeCtrl,
                    decoration: const InputDecoration(labelText: 'Hora Inicio (HH:mm)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: endTimeCtrl,
                    decoration: const InputDecoration(labelText: 'Hora Fin (HH:mm)'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (selectedUserId != null) {
                try {
                  await ScheduleService.createSchedule(
                    userId: selectedUserId!,
                    dayOfWeek: selectedDay,
                    startTime: startTimeCtrl.text.trim(),
                    endTime: endTimeCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created == true) _loadData();
  }

  Future<void> _editSchedule(ScheduleModel item) async {
    int selectedDay = item.dayOfWeek;
    final startTimeCtrl = TextEditingController(text: item.startTime);
    final endTimeCtrl = TextEditingController(text: item.endTime);

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Horario de Trabajo'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'Día de la Semana'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lunes')),
                      DropdownMenuItem(value: 2, child: Text('Martes')),
                      DropdownMenuItem(value: 3, child: Text('Miércoles')),
                      DropdownMenuItem(value: 4, child: Text('Jueves')),
                      DropdownMenuItem(value: 5, child: Text('Viernes')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 0, child: Text('Domingo')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: startTimeCtrl,
                    decoration: const InputDecoration(labelText: 'Hora Inicio (HH:mm)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: endTimeCtrl,
                    decoration: const InputDecoration(labelText: 'Hora Fin (HH:mm)'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ScheduleService.updateSchedule(
                  item.id,
                  {
                    'day_of_week': selectedDay,
                    'start_time': startTimeCtrl.text.trim(),
                    'end_time': endTimeCtrl.text.trim(),
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (updated == true) _loadData();
  }

  Future<void> _deleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Horario'),
        content: const Text('¿Estás seguro de eliminar este horario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ScheduleService.deleteSchedule(id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios de Trabajo'),
        backgroundColor: const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D5E2A),
        onPressed: _addSchedule,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('No hay horarios registrados.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _schedules.length,
                  itemBuilder: (ctx, index) {
                    final item = _schedules[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled, color: Color(0xFF2D5E2A)),
                        title: Text('${item.dayName}: ${item.startTime} - ${item.endTime}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.user?.fullName ?? 'Usuario ID: ${item.userId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _editSchedule(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteSchedule(item.id),
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
