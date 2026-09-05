import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/supervisors_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserModel?>(
      valueListenable: StorageService.currentUserNotifier,
      builder: (context, user, _) {
        final isAdmin = user?.isAdmin == true;

        final List<Widget> pages = [
          DashboardTab(onNavigateToHistory: () => setState(() => _currentIndex = 1)),
          const AttendanceTab(),
          if (isAdmin) const SupervisorsTab(),
          const ProfileTab(),
        ];

        final List<NavigationDestination> destinations = [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.access_time_rounded),
            selectedIcon: Icon(Icons.access_time_filled_rounded),
            label: 'Asistencias',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Supervisores',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ];

        // Asegurar que el indice no sobrepase si cambia el rol
        final safeIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            indicatorColor: isDark
                ? const Color(0xFF14532D)
                : const Color(0xFFDCFCE7),
            elevation: 2,
            destinations: destinations,
          ),
        );
      },
    );
  }
}
