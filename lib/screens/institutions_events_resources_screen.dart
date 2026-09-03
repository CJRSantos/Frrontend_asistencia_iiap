import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/event_model.dart';
import '../models/institution_model.dart';
import '../models/resource_model.dart';
import '../models/video_model.dart';
import '../services/course_service.dart';
import '../services/event_service.dart';
import '../services/institution_service.dart';
import '../services/resource_service.dart';
import '../services/video_service.dart';

class InstitutionsEventsResourcesScreen extends StatefulWidget {
  const InstitutionsEventsResourcesScreen({super.key});

  @override
  State<InstitutionsEventsResourcesScreen> createState() =>
      _InstitutionsEventsResourcesScreenState();
}

class _InstitutionsEventsResourcesScreenState
    extends State<InstitutionsEventsResourcesScreen> {
  bool _isLoading = true;
  List<InstitutionModel> _institutions = [];
  List<EventModel> _events = [];
  List<ResourceModel> _resources = [];
  List<CourseModel> _courses = [];
  List<VideoModel> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final insts = await InstitutionService.getAllInstitutions();
      final evts = await EventService.getAllEvents();
      final res = await ResourceService.getAllResources();
      final crs = await CourseService.getCourses();
      final vds = await VideoService.getVideos();
      if (mounted) {
        setState(() {
          _institutions = insts;
          _events = evts;
          _resources = res;
          _courses = crs;
          _videos = vds;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SEDES / INSTITUCIONES ---
  Future<void> _addInstitution() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Sede / Institución'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Sede *')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código (ej: SEDE-01)')),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Ciudad')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                try {
                  final code = codeCtrl.text.trim().isNotEmpty
                      ? codeCtrl.text.trim()
                      : 'SEDE-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                  await InstitutionService.createInstitution({
                    'code': code,
                    'name': nameCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (created == true) _loadAll();
  }

  Future<void> _editInstitution(InstitutionModel item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final codeCtrl = TextEditingController(text: item.code ?? '');
    final addressCtrl = TextEditingController(text: item.address ?? '');
    final cityCtrl = TextEditingController(text: item.city ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Sede'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Sede *')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código')),
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Ciudad')),
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
                    'name': nameCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                  };
                  if (codeCtrl.text.trim().isNotEmpty) data['code'] = codeCtrl.text.trim();
                  await InstitutionService.updateInstitution(item.id, data);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
    if (updated == true) _loadAll();
  }

  Future<void> _deleteInstitution(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Sede'),
        content: const Text('¿Estás seguro de eliminar esta sede?'),
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
        await InstitutionService.deleteInstitution(id);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- EVENTOS ---
  Future<void> _addEvent() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final endCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10));

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Evento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título del Evento *')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 8),
              TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Fecha Inicio (YYYY-MM-DD) *')),
              const SizedBox(height: 8),
              TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Fecha Fin (YYYY-MM-DD) *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                try {
                  await EventService.createEvent({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'start_date': startCtrl.text.trim(),
                    'end_date': endCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Crear Evento'),
          ),
        ],
      ),
    );
    if (created == true) _loadAll();
  }

  Future<void> _editEvent(EventModel item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description ?? '');
    final startCtrl = TextEditingController(text: item.startDate ?? DateTime.now().toIso8601String().substring(0, 10));
    final endCtrl = TextEditingController(text: item.endDate ?? DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10));

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Evento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título del Evento *')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 8),
              TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Fecha Inicio (YYYY-MM-DD) *')),
              const SizedBox(height: 8),
              TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Fecha Fin (YYYY-MM-DD) *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                try {
                  await EventService.updateEvent(item.id, {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'start_date': startCtrl.text.trim(),
                    'end_date': endCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
    if (updated == true) _loadAll();
  }

  Future<void> _deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: const Text('¿Estás seguro de eliminar este evento?'),
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
        await EventService.deleteEvent(id);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- RECURSOS / ACTIVOS ---
  Future<void> _addResource() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'EQUIPAMIENTO');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Recurso / Activo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Recurso *')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código de Inventario *')),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Tipo / Categoría *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty && codeCtrl.text.trim().isNotEmpty) {
                try {
                  await ResourceService.createResource({
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim(),
                    'type': typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : 'GENERAL',
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Crear Recurso'),
          ),
        ],
      ),
    );
    if (created == true) _loadAll();
  }

  Future<void> _editResource(ResourceModel item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final codeCtrl = TextEditingController(text: item.id);
    final typeCtrl = TextEditingController(text: item.type ?? 'EQUIPAMIENTO');
    String selectedStatus = item.status;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Recurso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
                const SizedBox(height: 8),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código')),
                const SizedBox(height: 8),
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Tipo')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'AVAILABLE', child: Text('Disponible (AVAILABLE)')),
                    DropdownMenuItem(value: 'ASSIGNED', child: Text('Asignado (ASSIGNED)')),
                    DropdownMenuItem(value: 'MAINTENANCE', child: Text('En Mantenimiento (MAINTENANCE)')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedStatus = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  try {
                    await ResourceService.updateResource(item.id, {
                      'name': nameCtrl.text.trim(),
                      'code': codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : item.id,
                      'type': typeCtrl.text.trim(),
                      'status': selectedStatus,
                    });
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
    if (updated == true) _loadAll();
  }

  Future<void> _deleteResource(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Recurso'),
        content: const Text('¿Estás seguro de eliminar este recurso?'),
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
        await ResourceService.deleteResource(id);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- CURSOS ---
  Future<void> _addCourse() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController(text: 'https://campus.iiap.gob.pe');
    final timeLimitCtrl = TextEditingController(text: '30 días');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Curso de Capacitación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Curso *')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción *')),
              const SizedBox(height: 8),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Enlace al Curso (URL) *')),
              const SizedBox(height: 8),
              TextField(controller: timeLimitCtrl, decoration: const InputDecoration(labelText: 'Límite de Tiempo / Duración *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty && linkCtrl.text.trim().isNotEmpty) {
                try {
                  await CourseService.createCourse({
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Curso de capacitación institucional',
                    'link': linkCtrl.text.trim(),
                    'time_limit': timeLimitCtrl.text.trim().isNotEmpty ? timeLimitCtrl.text.trim() : '30 días',
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Crear Curso'),
          ),
        ],
      ),
    );
    if (created == true) _loadAll();
  }

  // --- VIDEOS ---
  Future<void> _addVideo() async {
    final nameCtrl = TextEditingController();
    final linkCtrl = TextEditingController(text: 'https://youtube.com/watch?v=');
    final thumbCtrl = TextEditingController(text: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Video Institucional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Título del Video *')),
              const SizedBox(height: 8),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Enlace del Video (URL) *')),
              const SizedBox(height: 8),
              TextField(controller: thumbCtrl, decoration: const InputDecoration(labelText: 'URL Miniatura (Thumbnail)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty && linkCtrl.text.trim().isNotEmpty) {
                try {
                  await VideoService.createVideo({
                    'name': nameCtrl.text.trim(),
                    'link': linkCtrl.text.trim(),
                    'thumbnail': thumbCtrl.text.trim().isNotEmpty ? thumbCtrl.text.trim() : 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Guardar Video'),
          ),
        ],
      ),
    );
    if (created == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión General IIAP'),
          backgroundColor: const Color(0xFF2D5E2A),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.location_city), text: 'Sedes'),
              Tab(icon: Icon(Icons.event), text: 'Eventos'),
              Tab(icon: Icon(Icons.category), text: 'Recursos'),
              Tab(icon: Icon(Icons.school), text: 'Cursos'),
              Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // 1. Sedes
                  Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: const Color(0xFF2D5E2A),
                      onPressed: _addInstitution,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    body: _institutions.isEmpty
                        ? const Center(child: Text('No hay sedes registradas.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _institutions.length,
                            itemBuilder: (ctx, i) {
                              final item = _institutions[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.location_on, color: Color(0xFF2D5E2A)),
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.code ?? "SEDE"} • ${item.address ?? ""} - ${item.city ?? ""}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _editInstitution(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteInstitution(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // 2. Eventos
                  Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: const Color(0xFF2D5E2A),
                      onPressed: _addEvent,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    body: _events.isEmpty
                        ? const Center(child: Text('No hay eventos registrados.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _events.length,
                            itemBuilder: (ctx, i) {
                              final item = _events[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.event, color: Color(0xFF2D5E2A)),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.description ?? "Sin descripción"}\nFechas: ${item.startDate ?? "N/A"} a ${item.endDate ?? "N/A"}'),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _editEvent(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteEvent(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // 3. Recursos
                  Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: const Color(0xFF2D5E2A),
                      onPressed: _addResource,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    body: _resources.isEmpty
                        ? const Center(child: Text('No hay recursos registrados.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _resources.length,
                            itemBuilder: (ctx, i) {
                              final item = _resources[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.inventory, color: Color(0xFF2D5E2A)),
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Tipo: ${item.type ?? "GENERAL"} • Estado: ${item.status}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _editResource(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteResource(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // 4. Cursos
                  Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: const Color(0xFF2D5E2A),
                      onPressed: _addCourse,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    body: _courses.isEmpty
                        ? const Center(child: Text('No hay cursos registrados.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _courses.length,
                            itemBuilder: (ctx, i) {
                              final item = _courses[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.book, color: Color(0xFF2D5E2A)),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.description ?? "Sin descripción"}\nEnlace: ${item.link ?? "N/A"} • Límite: ${item.timeLimit ?? "N/A"}'),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),

                  // 5. Videos
                  Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: const Color(0xFF2D5E2A),
                      onPressed: _addVideo,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    body: _videos.isEmpty
                        ? const Center(child: Text('No hay videos registrados.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _videos.length,
                            itemBuilder: (ctx, i) {
                              final item = _videos[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.play_circle_fill, color: Color(0xFF2D5E2A)),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(item.url ?? 'Sin URL'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

