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

  Future<void> _addInstitution() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Sede / Institución'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
            TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Ciudad')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                try {
                  await InstitutionService.createInstitution({
                    'name': nameCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  // Sedes
                  Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: const Color(0xFF2D5E2A),
                      onPressed: _addInstitution,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    body: _institutions.isEmpty
                        ? const Center(child: Text('No hay sedes registradas.'))
                        : ListView.builder(
                            itemCount: _institutions.length,
                            itemBuilder: (ctx, i) {
                              final item = _institutions[i];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.location_on, color: Color(0xFF2D5E2A)),
                                  title: Text(item.name),
                                  subtitle: Text('${item.address ?? ""} - ${item.city ?? ""}'),
                                ),
                              );
                            },
                          ),
                  ),
                  // Eventos
                  _events.isEmpty
                      ? const Center(child: Text('No hay eventos registrados.'))
                      : ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (ctx, i) {
                            final item = _events[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.event, color: Color(0xFF2D5E2A)),
                                title: Text(item.title),
                                subtitle: Text(item.description ?? 'Sin descripción'),
                              ),
                            );
                          },
                        ),
                  // Recursos
                  _resources.isEmpty
                      ? const Center(child: Text('No hay recursos registrados.'))
                      : ListView.builder(
                          itemCount: _resources.length,
                          itemBuilder: (ctx, i) {
                            final item = _resources[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.inventory, color: Color(0xFF2D5E2A)),
                                title: Text(item.name),
                                subtitle: Text('Estado: ${item.status}'),
                              ),
                            );
                          },
                        ),
                  // Cursos
                  _courses.isEmpty
                      ? const Center(child: Text('No hay cursos registrados.'))
                      : ListView.builder(
                          itemCount: _courses.length,
                          itemBuilder: (ctx, i) {
                            final item = _courses[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.book, color: Color(0xFF2D5E2A)),
                                title: Text(item.title),
                                subtitle: Text(item.description ?? 'Sin descripción'),
                              ),
                            );
                          },
                        ),
                  // Videos
                  _videos.isEmpty
                      ? const Center(child: Text('No hay videos registrados.'))
                      : ListView.builder(
                          itemCount: _videos.length,
                          itemBuilder: (ctx, i) {
                            final item = _videos[i];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.play_circle_fill, color: Color(0xFF2D5E2A)),
                                title: Text(item.title),
                                subtitle: Text(item.url ?? 'Sin URL'),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}
