import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import '../services/video_service.dart';

class UserVideosScreen extends StatefulWidget {
  const UserVideosScreen({super.key});

  @override
  State<UserVideosScreen> createState() => _UserVideosScreenState();
}

class _UserVideosScreenState extends State<UserVideosScreen> {
  List<VideoModel> _videos = [];
  List<VideoModel> _filteredVideos = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAndVideos();
  }

  Future<void> _loadUserAndVideos() async {
    final user = await StorageService.getUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
    await _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final data = await VideoService.getVideos();
      if (mounted) {
        setState(() {
          _videos = data;
          _filteredVideos = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar videos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredVideos = _videos);
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filteredVideos = _videos.where((v) {
          final titleMatch = v.title.toLowerCase().contains(q);
          final descMatch = (v.description ?? '').toLowerCase().contains(q);
          return titleMatch || descMatch;
        }).toList();
      });
    }
  }

  void _showAddEditVideoDialog([VideoModel? video]) {
    final isEditing = video != null;
    final nameCtrl = TextEditingController(text: video?.title ?? '');
    final urlCtrl = TextEditingController(text: video?.url ?? '');
    final thumbCtrl = TextEditingController(text: video?.thumbnail ?? '');
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
                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.video_call_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing ? 'Editar Video' : 'Nuevo Video',
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
                      labelText: 'Título del Video *',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese el título del video' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: urlCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Enlace / URL de Video *',
                      hintText: 'https://youtube.com/watch?v=...',
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
                      if (val == null || val.trim().isEmpty) return 'Ingrese la URL del video';
                      if (!val.startsWith('http://') && !val.startsWith('https://')) {
                        return 'Debe ser una URL válida (http:// o https://)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: thumbCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Miniatura URL (Opcional)',
                      hintText: 'Autogenerada si es de YouTube',
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
                          'link': urlCtrl.text.trim(),
                          if (thumbCtrl.text.trim().isNotEmpty) 'thumbnail': thumbCtrl.text.trim(),
                        };

                        if (isEditing) {
                          await VideoService.updateVideo(video.id, payload);
                        } else {
                          await VideoService.createVideo(payload);
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(isEditing ? 'Video actualizado con éxito' : 'Video registrado con éxito'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF2D5E2A),
                            ),
                          );
                          _loadVideos();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al guardar video: $e'), backgroundColor: Colors.red),
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

  void _confirmDeleteVideo(VideoModel video) {
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
              Expanded(child: Text('Eliminar Video')),
            ],
          ),
          content: Text(
            '¿Está seguro de eliminar el video "${video.title}"? Esta acción no se puede deshacer.',
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
                        await VideoService.deleteVideo(video.id);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video eliminado exitosamente'),
                              backgroundColor: Color(0xFF2D5E2A),
                            ),
                          );
                          _loadVideos();
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al eliminar video: $e'), backgroundColor: Colors.red),
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

  void _showVideoDetails(VideoModel video) {
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
                    color: isDark ? const Color(0xFF78350F) : const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.play_circle_fill, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFE65100), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    video.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E4720),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Enlace del Video:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
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
                      video.url ?? 'Sin URL',
                      style: const TextStyle(fontSize: 13, color: Colors.blueAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: isDark ? Colors.white70 : null),
                    tooltip: 'Copiar enlace',
                    onPressed: () {
                      if (video.url != null) {
                        Clipboard.setData(ClipboardData(text: video.url!));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enlace copiado al portapapeles')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (video.url != null && video.url!.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: video.url!));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Enlace listo: ${video.url}'),
                      backgroundColor: const Color(0xFF2D5E2A),
                    ),
                  );
                } else {
                  Navigator.pop(ctx);
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Ver Video', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Videos Institucionales'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditVideoDialog(),
              backgroundColor: isDark ? const Color(0xFF166534) : const Color(0xFF2D5E2A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Video', style: TextStyle(fontWeight: FontWeight.bold)),
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
                hintText: 'Buscar videos por título...',
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
                : _filteredVideos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron videos disponibles.',
                              style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVideos,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredVideos.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final v = _filteredVideos[index];
                            return Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E6E3)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _showVideoDetails(v),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFFE0B2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFE65100),
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              v.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isDark ? Colors.white : const Color(0xFF1E4720),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              v.url ?? 'Sin URL asignada',
                                              maxLines: 1,
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
                                              _showAddEditVideoDialog(v);
                                            } else if (val == 'delete') {
                                              _confirmDeleteVideo(v);
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
                                      ] else ...[
                                        Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.grey),
                                      ],
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
