import 'package:flutter/material.dart';
import '../models/historial_model.dart';
import '../services/historial_service.dart';

class HistorialScreen extends StatefulWidget {
  final bool isAdminView;

  const HistorialScreen({super.key, this.isAdminView = false});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<HistorialModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = widget.isAdminView
          ? await HistorialService.getAllHistory()
          : await HistorialService.getMyHistory();
      setState(() => _history = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'Auditoría Global' : 'Mi Historial de Actividad'),
        backgroundColor: const Color(0xFF2D5E2A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadHistory, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No hay registros de actividad.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _history.length,
                  itemBuilder: (ctx, index) {
                    final item = _history[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history_rounded, color: Color(0xFF2D5E2A)),
                        title: Text(item.action, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description),
                            if (widget.isAdminView && item.user != null)
                              Text('Usuario: ${item.user!.fullName} (${item.user!.email})'),
                            Text('IP: ${item.ipAddress ?? "N/A"} | Fecha: ${item.createdAt}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
