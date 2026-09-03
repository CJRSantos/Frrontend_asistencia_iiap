import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await UserService.getAllUsers();
      if (mounted) {
        setState(() => _users = users);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(UserModel user) async {
    String selectedRole = user.role;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar Rol de ${user.fullName}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(labelText: 'Rol del usuario'),
              items: const [
                DropdownMenuItem(value: 'EMPLOYEE', child: Text('Empleado (EMPLOYEE)')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Administrador (ADMIN)')),
                DropdownMenuItem(value: 'SUPERADMIN', child: Text('Super Admin (SUPERADMIN)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() => selectedRole = val);
                }
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selectedRole),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result != user.role) {
      try {
        await UserService.assignRole(user.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rol de ${user.fullName} actualizado a $result')),
          );
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cambiar rol: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editUser(UserModel user) async {
    final nameCtrl = TextEditingController(text: user.fullName);
    final docCtrl = TextEditingController(text: user.documentNumber ?? '');
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');
    final posCtrl = TextEditingController(text: user.position ?? '');
    final deptCtrl = TextEditingController(text: user.department ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Usuario: ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo *')),
              const SizedBox(height: 8),
              TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Número de Documento (DNI/CE)')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono / Celular')),
              const SizedBox(height: 8),
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Cargo / Puesto')),
              const SizedBox(height: 8),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Departamento / Área')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                try {
                  final data = <String, dynamic>{
                    'full_name': nameCtrl.text.trim(),
                  };
                  if (docCtrl.text.trim().isNotEmpty) data['document_number'] = docCtrl.text.trim();
                  if (phoneCtrl.text.trim().isNotEmpty) data['phone_number'] = phoneCtrl.text.trim();
                  if (posCtrl.text.trim().isNotEmpty) data['position'] = posCtrl.text.trim();
                  if (deptCtrl.text.trim().isNotEmpty) data['department'] = deptCtrl.text.trim();

                  await UserService.updateUser(user.id, data);
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
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (updated == true) _loadUsers();
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de desactivar/eliminar a ${user.fullName}?'),
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
        await UserService.deleteUser(user.id);
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No hay usuarios registrados.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (ctx, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2D5E2A),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text('Rol: ${user.role} | Cargo: ${user.position ?? 'N/A'}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _editUser(user);
                            if (val == 'role') _changeRole(user);
                            if (val == 'delete') _deleteUser(user);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar Datos')),
                            const PopupMenuItem(value: 'role', child: Text('Cambiar Rol')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
