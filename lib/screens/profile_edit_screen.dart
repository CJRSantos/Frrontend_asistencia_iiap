import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

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
  late TextEditingController _dobController;
  String? _currentPhotoUrl;

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _docController = TextEditingController(text: widget.user.documentNumber ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _positionController = TextEditingController(text: widget.user.position ?? '');
    _departmentController = TextEditingController(text: widget.user.department ?? '');
    _dobController = TextEditingController(text: widget.user.dateOfBirth ?? '');
    _currentPhotoUrl = widget.user.photoUrl;
  }
    void _showPhotoZoomViewer(BuildContext context, String photoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // 🔍 Visor interactivo con Zoom y Arrastre
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.8,
                  maxScale: 4.5, // Permite hasta 4.5x de Zoom
                  child: Hero(
                    tag: 'profile_photo_hero',
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
                            SizedBox(height: 8),
                            Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Botón de cerrar en la esquina superior
              Positioned(
                top: 40,
                right: 20,
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  void dispose() {
    _fullNameController.dispose();
    _docController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime(1995, 1, 1);
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D5E2A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E4720),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final y = picked.year.toString();
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dobController.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final response = await UserService.uploadProfilePhoto(filePath: image.path);

      if (mounted) {
        final newUrl = response['photo_url']?.toString() ??
            (response['user'] is Map ? response['user']['photo_url']?.toString() : null);

        setState(() {
          if (newUrl != null && newUrl.isNotEmpty) {
            _currentPhotoUrl = newUrl;
          }
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Foto de perfil actualizada exitosamente.')),
              ],
            ),
            backgroundColor: Color(0xFF2D5E2A),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePhotoBottomSheet() {
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
                'Foto de Perfil',
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
                subtitle: const Text('Selecciona una foto guardada en tu teléfono', style: TextStyle(fontSize: 12.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
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
                subtitle: const Text('Captura una nueva foto para tu perfil', style: TextStyle(fontSize: 12.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded, color: Color(0xFF1976D2)),
                ),
                title: const Text('Ingresar URL Directa', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Usa una imagen web o avatar por URL', style: TextStyle(fontSize: 12.5)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlCtrl = TextEditingController(text: _currentPhotoUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link, color: Color(0xFF2D5E2A)),
            SizedBox(width: 8),
            Expanded(child: Text('URL de Imagen')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresa la URL pública de la imagen para tu avatar.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de Imagen',
                hintText: 'http://localhost:3000/uploads/profiles/...',
                prefixIcon: Icon(Icons.image),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5E2A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = urlCtrl.text.trim();
              Navigator.pop(ctx);
              if (newUrl.isNotEmpty) {
                setState(() => _isUploadingPhoto = true);
                try {
                  final updated = await AuthService.updateProfile({'photo_url': newUrl});
                  if (mounted) {
                    setState(() {
                      _currentPhotoUrl = updated.photoUrl ?? newUrl;
                      _isUploadingPhoto = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto actualizada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isUploadingPhoto = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
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
        if (_dobController.text.trim().isNotEmpty) 'date_of_birth': _dobController.text.trim(),
        if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) 'photo_url': _currentPhotoUrl,
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
            // Avatar Selector with Camera Badge
           // Avatar Selector con Zoom y cámara
Center(
  child: Stack(
    children: [
      // 1. Tocar la foto abre el visor con Zoom
      GestureDetector(
        onTap: () {
          if (_currentPhotoUrl != null &&
              _currentPhotoUrl!.isNotEmpty) {
            _showPhotoZoomViewer(
              context,
              _currentPhotoUrl!,
            );
          }
        },
        child: Hero(
          tag: 'profile_photo_hero',
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2D5E2A),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFF2D5E2A),
              backgroundImage:
                  (_currentPhotoUrl != null &&
                          _currentPhotoUrl!.isNotEmpty)
                      ? NetworkImage(_currentPhotoUrl!)
                      : null,
              child: (_currentPhotoUrl == null ||
                      _currentPhotoUrl!.isEmpty)
                  ? Text(
                      widget.user.fullName.isNotEmpty
                          ? widget.user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),

      // 2. Tocar la cámara abre las opciones de foto
      Positioned(
        bottom: 2,
        right: 2,
        child: GestureDetector(
          onTap: _showChangePhotoBottomSheet,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5E2A),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 8),
            const SizedBox(height: 16),

            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo *', prefixIcon: Icon(Icons.person)),
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
            const SizedBox(height: 14),
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDateOfBirth,
              decoration: InputDecoration(
                labelText: 'Fecha de Nacimiento (Cumpleaños)',
                hintText: 'YYYY-MM-DD',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: _selectDateOfBirth,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5E2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                label: const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
