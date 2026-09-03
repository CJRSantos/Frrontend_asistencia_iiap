import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../services/project_service.dart';
import '../services/storage_service.dart';

class UserProjectsScreen extends StatefulWidget {
  const UserProjectsScreen({super.key});

  @override
  State<UserProjectsScreen> createState() => _UserProjectsScreenState();
}

class _UserProjectsScreenState extends State<UserProjectsScreen> {
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAndProjects();
  }

  Future<void> _loadUserAndProjects() async {
    final user = await StorageService.getUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
    await _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final data = await ProjectService.getProjects();
      if (mounted) {
        setState(() {
          _projects = data;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar proyectos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<ProjectModel> list = _projects;

    if (_selectedStatusFilter != 'ALL') {
      list = list.where((p) => p.status == _selectedStatusFilter).toList();
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final descMatch = (p.description ?? '').toLowerCase().contains(query);
        return nameMatch || descMatch;
      }).toList();
    }

    setState(() {
      _filteredProjects = list;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'COMPLETED':
        return const Color(0xFF2563EB);
      case 'ON_HOLD':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Activo';
      case 'COMPLETED':
        return 'Completado';
      case 'ON_HOLD':
        return 'En Pausa';
      default:
        return status;
    }
  }

  void _showAddEditProjectDialog([ProjectModel? project]) {
    final isEditing = project != null;
    final nameCtrl = TextEditingController(text: project?.name ?? '');
    final descCtrl = TextEditingController(text: project?.description ?? '');
    String currentStatus = project?.status ?? 'ACTIVE';
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
                  color: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto',
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
                      labelText: 'Nombre del Proyecto *',
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
                      if (val == null || val.trim().isEmpty) return 'Ingrese el nombre del proyecto';
                      if (val.trim().length < 3) return 'Mínimo 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Descripción del Proyecto (Opcional)',
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
                  if (isEditing) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Estado del Proyecto',
                        labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Activo')),
                        DropdownMenuItem(value: 'ON_HOLD', child: Text('En Pausa')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('Completado')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => currentStatus = val);
                        }
                      },
                    ),
                  ],
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
                        if (isEditing) {
                          final payload = {
                            'name': nameCtrl.text.trim(),
                            'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            'status': currentStatus,
                          };
                          await ProjectService.updateProject(project.id, payload);
                        } else {
                          await ProjectService.createProject(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          );
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(isEditing ? 'Proyecto actualizado con éxito' : 'Proyecto creado con éxito'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF2D5E2A),
                            ),
                          );
                          _loadProjects();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al guardar proyecto: $e'), backgroundColor: Colors.red),
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

  void _confirmDeleteProject(ProjectModel project) {
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
              Expanded(child: Text('Eliminar Proyecto')),
            ],
          ),
          content: Text(
            '¿Está seguro de eliminar el proyecto "${project.name}"? Esta acción no se puede deshacer.',
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
                        await ProjectService.deleteProject(project.id);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Proyecto eliminado exitosamente'),
                              backgroundColor: Color(0xFF2D5E2A),
                            ),
                          );
                          _loadProjects();
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al eliminar proyecto: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canManage = _currentUser?.canManageResources ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Proyectos de Investigación'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditProjectDialog(),
              backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Proyecto', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilters(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Buscar proyectos...',
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
                    prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: isDark ? Colors.white70 : null),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilters();
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'ALL', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Activos', 'ACTIVE', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completados', 'COMPLETED', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('En Pausa', 'ON_HOLD', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A)))
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_special_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron proyectos.',
                              style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProjects,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProjects.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final p = _filteredProjects[index];
                            final statusColor = _getStatusColor(p.status);
                            final statusLabel = _getStatusLabel(p.status);

                            return Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF166534) : const Color(0xFFC7F3BF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.folder_special, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A), size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: isDark ? Colors.white : const Color(0xFF1E4720),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
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
                                                _showAddEditProjectDialog(p);
                                              } else if (val == 'delete') {
                                                _confirmDeleteProject(p);
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
                                    if (p.description != null && p.description!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        p.description!,
                                        style: TextStyle(fontSize: 13.5, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563), height: 1.4),
                                      ),
                                    ],
                                  ],
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

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151)),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.5,
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
      side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
      onSelected: (_) {
        setState(() {
          _selectedStatusFilter = value;
          _applyFilters();
        });
      },
    );
  }
}
