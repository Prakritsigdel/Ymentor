import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'discovery_screen.dart';
import 'bookings/active_call_screen.dart';
import 'workspace/workspace_screen.dart';
import 'dashboard/mentor_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/auth_required_sheet.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMentor = auth.isMentor;
    final isAdmin = auth.isAdmin;

    final tabs = <Widget>[
      const DiscoveryScreen(),
      _guarded(auth, const ActiveCallScreen(), title: 'Mentorship Sessions'),
      _guarded(auth, const WorkspaceScreen(), title: 'Classroom Workspace'),
      if (isMentor)
        _guarded(auth, const MentorDashboardScreen(),
            title: 'Mentor Dashboard'),
      if (isAdmin)
        _guarded(auth, const AdminDashboardScreen(),
            title: 'Admin Control Panel'),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Discover',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.videocam_outlined),
        activeIcon: Icon(Icons.videocam),
        label: 'Sessions',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_open_outlined),
        activeIcon: Icon(Icons.folder),
        label: 'Workspace',
      ),
      if (isMentor)
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.security_outlined),
          activeIcon: Icon(Icons.security),
          label: 'Admin',
        ),
    ];

    final safeIndex = _index >= tabs.length ? 0 : _index;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        items: navItems,
        onTap: (i) {
          if (!auth.isLoggedIn && i != 0) {
            showAuthRequiredSheet(
              context,
              action: i == 2
                  ? 'open your workspace and upload documents'
                  : 'view your sessions',
            );
            return;
          }
          setState(() => _index = i);
        },
      ),
    );
  }

  Widget _guarded(AuthProvider auth, Widget child, {required String title}) {
    if (auth.isLoggedIn) return child;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 14),
              Text(
                'Log in to access $title',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Log In to Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
