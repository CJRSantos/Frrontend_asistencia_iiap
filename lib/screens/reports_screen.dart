import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<ReportNotificationModel> _notifications = [];
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  dynamic _monthlySummary;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await ReportService.getNotifications();
      final summary = await ReportService.getMonthlySummary(_selectedYear, _selectedMonth);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _monthlySummary = summary;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createReportNotification() async {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Solicitud / Notificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 10),
            TextField(controller: messageCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Mensaje')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                try {
                  await ReportService.createNotification({
                    'title': titleCtrl.text.trim(),
                    'message': messageCtrl.text.trim(),
                  });
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
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (created == true) _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes y Notificaciones'),
          backgroundColor: const Color(0xFF2D5E2A),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Resumen Mensual'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF2D5E2A),
          onPressed: _createReportNotification,
          child: const Icon(Icons.send, color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Notifications
                  _notifications.isEmpty
                      ? const Center(child: Text('No hay notificaciones o solicitudes.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _notifications.length,
                          itemBuilder: (ctx, index) {
                            final item = _notifications[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.mark_email_unread, color: Color(0xFF2D5E2A)),
                                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${item.message}\nFecha: ${item.createdAt ?? "Reciente"}'),
                              ),
                            );
                          },
                        ),
                  // Tab 2: Monthly summary
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Año: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: _selectedYear,
                              items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedYear = v);
                                  _loadReports();
                                }
                              },
                            ),
                            const SizedBox(width: 20),
                            const Text('Mes: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: _selectedMonth,
                              items: List.generate(12, (i) => i + 1)
                                  .map((m) => DropdownMenuItem(value: m, child: Text('Mes $m')))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedMonth = v);
                                  _loadReports();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resumen del Mes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text(_monthlySummary != null
                                    ? _monthlySummary.toString()
                                    : 'No se encontraron datos para el periodo seleccionado.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
