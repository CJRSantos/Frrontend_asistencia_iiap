import 'package:flutter/material.dart';
import '../models/delegation_model.dart';
import '../models/user_model.dart';
import '../services/delegation_service.dart';
import '../services/user_service.dart';

class DelegationsScreen extends StatefulWidget {
  const DelegationsScreen({super.key});

  @override
  State<DelegationsScreen> createState() => _DelegationsScreenState();
}

class _DelegationsScreenState extends State<DelegationsScreen> {
  List<DelegationModel> _delegations = [];
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
      final delegations = await DelegationService.getMyDelegations();
      final users = await UserService.getAllUsers();
      if (mounted) {
        setState(() {
          _delegations = delegations;
          _users = users;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDelegation() async {
    String? selectedDelegateId = _users.isNotEmpty ? _users.first.id : null;
    final startDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final endDateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10));

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Delegación de Escaneo'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedDelegateId,
                  decoration: const InputDecoration(labelText: 'Usuario Delegado'),
                  items: _users.map((u) {
                    return DropdownMenuItem(value: u.id, child: Text(u.fullName));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedDelegateId = val),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: startDateCtrl,
                  decoration: const InputDecoration(labelText: 'Fecha Inicio (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(labelText: 'Fecha Fin (YYYY-MM-DD)'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (selectedDelegateId != null) {
                try {
                  await DelegationService.createDelegation(
                    delegateId: selectedDelegateId!,
                    startDate: startDateCtrl.text.trim(),
                    endDate: endDateCtrl.text.trim(),
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

  Future<void> _deactivate(String id) async {
    try {
      await DelegationService.deactivateDelegation(id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delegaciones de Escaneo'),
        backgroundColor: const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D5E2A),
        onPressed: _addDelegation,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _delegations.isEmpty
              ? const Center(child: Text('No hay delegaciones activas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _delegations.length,
                  itemBuilder: (ctx, index) {
                    final d = _delegations[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.swap_horiz_rounded,
                          color: d.isActive ? Colors.green : Colors.grey,
                        ),
                        title: Text('Delegado a: ${d.delegate?.fullName ?? d.delegateId}'),
                        subtitle: Text('Del ${d.startDate} al ${d.endDate}\nEstado: ${d.isActive ? "Activo" : "Inactivo"}'),
                        trailing: d.isActive
                            ? IconButton(
                                icon: const Icon(Icons.block, color: Colors.orange),
                                onPressed: () => _deactivate(d.id),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
