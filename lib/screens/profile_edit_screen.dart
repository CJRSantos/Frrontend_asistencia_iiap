import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _docController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;
  late TextEditingController _departmentController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _docController = TextEditingController(text: widget.user.documentNumber ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _positionController = TextEditingController(text: widget.user.position ?? '');
    _departmentController = TextEditingController(text: widget.user.department ?? '');
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final updatedUser = await AuthService.updateProfile({
        'full_name': _fullNameController.text.trim(),
        'document_number': _docController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'position': _positionController.text.trim(),
        'department': _departmentController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, updatedUser);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar perfil'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mi Perfil'),
        backgroundColor: const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _docController,
              decoration: const InputDecoration(labelText: 'Documento (DNI)', prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(labelText: 'Cargo / Puesto', prefixIcon: Icon(Icons.work)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Área / Departamento', prefixIcon: Icon(Icons.business)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5E2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                label: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
