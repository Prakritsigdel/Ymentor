import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'discovery_screen.dart';
import 'bookings/active_call_screen.dart';
import 'workspace/workspace_screen.dart';
import 'dashboard/mentor_dashboard_screen.dart';
import 'auth/login_screen.dart';

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
    final isMentor = auth.user?.isMentor ?? false;

    final tabs = <Widget>[
      const DiscoveryScreen(),
      _guarded(auth, const ActiveCallScreen(), title: 'Sessions'),
      _guarded(auth, const WorkspaceScreen(), title: 'Workspaces'),
      if (isMentor) _guarded(auth, const MentorDashboardScreen(), title: 'Dashboard'),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
      const BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), activeIcon: Icon(Icons.videocam), label: 'Sessions'),
      const BottomNavigationBarItem(icon: Icon(Icons.folder_open_outlined), activeIcon: Icon(Icons.folder), label: 'Workspace'),
      if (isMentor)
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    ];

    final safeIndex = _index >= tabs.length ? 0 : _index;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        items: navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget _guarded(AuthProvider auth, Widget child, {required String title}) {
    if (auth.isLoggedIn) return child;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log in to continue', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}
