import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/course_service.dart';
import '../services/storage_service.dart';

class UserCoursesScreen extends StatefulWidget {
  const UserCoursesScreen({super.key});

  @override
  State<UserCoursesScreen> createState() => _UserCoursesScreenState();
}

class _UserCoursesScreenState extends State<UserCoursesScreen> {
  List<CourseModel> _courses = [];
  List<CourseModel> _filteredCourses = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAndCourses();
  }

  Future<void> _loadUserAndCourses() async {
    final user = await StorageService.getUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
    await _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final data = await CourseService.getCourses();
      if (mounted) {
        setState(() {
          _courses = data;
          _filteredCourses = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar cursos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredCourses = _courses);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredCourses = _courses.where((c) {
          final titleMatch = c.title.toLowerCase().contains(q);
          final descMatch = (c.description ?? '').toLowerCase().contains(q);
          return titleMatch || descMatch;
        }).toList();
      });
    }
  }

  void _showAddEditCourseDialog([CourseModel? course]) {
    final isEditing = course != null;
    final nameCtrl = TextEditingController(text: course?.title ?? '');
    final descCtrl = TextEditingController(text: course?.description ?? '');
    final linkCtrl = TextEditingController(text: course?.link ?? '');
    final timeLimitCtrl = TextEditingController(text: course?.timeLimit ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF166534) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing ? 'Editar Curso' : 'Nuevo Curso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E4720),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Curso *',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese el nombre del curso' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: linkCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Enlace / URL de Acceso *',
                      hintText: 'https://...',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Ingrese el enlace del curso';
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return 'Debe ser una URL válida (http:// o https://)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: timeLimitCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Tiempo Límite / Duración *',
                      hintText: 'Ej: 4 semanas, 40 horas',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese el tiempo límite o duración' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        final payload = {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          'link': linkCtrl.text.trim(),
                          'time_limit': timeLimitCtrl.text.trim(),
                        };

                        if (isEditing) {
                          await CourseService.updateCourse(course.id, payload);
                        } else {
                          await CourseService.createCourse(payload);
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(isEditing ? 'Curso actualizado con éxito' : 'Curso creado con éxito'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF2D5E2A),
                            ),
                          );
                          _loadCourses();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al guardar curso: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              icon: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isEditing ? Icons.save_outlined : Icons.add, size: 18),
              label: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(CourseModel course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text('Eliminar Curso')),
            ],
          ),
          content: Text(
            '¿Está seguro de eliminar el curso "${course.title}"? Esta acción no se puede deshacer.',
            style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        await CourseService.deleteCourse(course.id);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Curso eliminado exitosamente'),
                              backgroundColor: Color(0xFF2D5E2A),
                            ),
                          );
                          _loadCourses();
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al eliminar curso: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              icon: isDeleting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.delete_forever, size: 18),
              label: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseDetails(CourseModel course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E4720),
                        ),
                      ),
                      if (course.timeLimit != null)
                        Text(
                          'Duración: ${course.timeLimit}',
                          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF374151)),
            ),
            const SizedBox(height: 4),
            Text(
              course.description ?? 'Sin descripción detallada disponible.',
              style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (course.link != null && course.link!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 20, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course.link!,
                        style: const TextStyle(fontSize: 13, color: Colors.blueAccent),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, size: 18, color: isDark ? Colors.white70 : null),
                      tooltip: 'Copiar enlace',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: course.link!));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enlace copiado al portapapeles')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (course.link != null && course.link!.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: course.link!));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Enlace copiado: ${course.link}'),
                      backgroundColor: const Color(0xFF2D5E2A),
                    ),
                  );
                } else {
                  Navigator.pop(ctx);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Acceder al Curso', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage = _currentUser?.canManageResources ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Cursos de Capacitación'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditCourseDialog(),
              backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Curso', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Buscar cursos por título o tema...',
                hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: isDark ? Colors.white70 : null),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)))
                : _filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron cursos disponibles.',
                              style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCourses,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCourses.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final c = _filteredCourses[index];
                            return Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _showCourseDetails(c),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.school, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 24),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  c.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isDark ? Colors.white : const Color(0xFF1E4720),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  c.description ?? 'Sin descripción detallada',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (canManage) ...[
                                            PopupMenuButton<String>(
                                              icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
                                              ),
                                              onSelected: (val) {
                                                if (val == 'edit') {
                                                  _showAddEditCourseDialog(c);
                                                } else if (val == 'delete') {
                                                  _confirmDeleteCourse(c);
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_outlined, size: 18, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
                                                      const SizedBox(width: 8),
                                                      Text('Editar', style: TextStyle(color: isDark ? Colors.white : null)),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          if (c.timeLimit != null) ...[
                                            const Icon(Icons.access_time, size: 14, color: Color(0xFFD97706)),
                                            const SizedBox(width: 4),
                                            Text(
                                              c.timeLimit!,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          Text(
                                            'Ver detalles →',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
