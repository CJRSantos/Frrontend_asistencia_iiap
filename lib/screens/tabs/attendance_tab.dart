import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../../services/attendance_service.dart';
import '../../widgets/attendance_card.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<AttendanceModel> _myRecords = [];
  List<AttendanceModel> _allRecords = [];
  bool _isLoadingMy = true;
  bool _isLoadingAll = false;

  @override
  void initState() {
    super.initState();
    final user = StorageService.currentUserNotifier.value;
    if (user != null && user.canManageAttendanceQr) {
      _tabController = TabController(length: 2, vsync: this);
      _loadAllRecords();
    }
    _loadMyRecords();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMyRecords() async {
    setState(() => _isLoadingMy = true);
    try {
      final records = await AttendanceService.getMyRecords();
      if (mounted) {
        setState(() {
          _myRecords = records;
          _isLoadingMy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMy = false);
    }
  }

  Future<void> _loadAllRecords() async {
    setState(() => _isLoadingAll = true);
    try {
      final records = await AttendanceService.getAllRecords();
      if (mounted) {
        setState(() {
          _allRecords = records;
          _isLoadingAll = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserModel?>(
      valueListenable: StorageService.currentUserNotifier,
      builder: (context, user, _) {
        final canManage = user != null && user.canManageAttendanceQr;

        if (!canManage) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Historial de Asistencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadMyRecords,
                ),
              ],
            ),
            body: _buildList(_myRecords, _isLoadingMy, _loadMyRecords, showUserName: false),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Control de Asistencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  _loadMyRecords();
                  _loadAllRecords();
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
              indicatorColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2D5E2A),
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_outline_rounded, size: 20),
                  text: 'Mis Asistencias',
                ),
                Tab(
                  icon: Icon(Icons.corporate_fare_rounded, size: 20),
                  text: 'Registro Institucional',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(_myRecords, _isLoadingMy, _loadMyRecords, showUserName: false),
              _buildList(_allRecords, _isLoadingAll, _loadAllRecords, showUserName: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    List<AttendanceModel> records,
    bool isLoading,
    Future<void> Function() onRefresh, {
    required bool showUserName,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.assignment_late_outlined,
              size: 56,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron registros',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Arrastra hacia abajo para actualizar la lista desde la base de datos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return AttendanceCard(
            record: records[index],
            showUserName: showUserName,
          );
        },
      ),
    );
  }
}
