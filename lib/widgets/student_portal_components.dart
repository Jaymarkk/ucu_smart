import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/student_api_service.dart';
import '../services/student_auth_service.dart';

const Color studentNavy = Color(0xFF073B78);
const Color studentBlue = Color(0xFF0755A0);
const Color studentInk = Color(0xFF183153);
const Color studentMuted = Color(0xFF64748B);
const Color studentCanvas = Color(0xFFF4F7FB);

enum StudentPortalMapOrigin { studentPortal }

class StudentPortalScaffold extends StatefulWidget {
  const StudentPortalScaffold({
    required this.authService,
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final StudentAuthService authService;
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  State<StudentPortalScaffold> createState() => _StudentPortalScaffoldState();
}

class _StudentPortalScaffoldState extends State<StudentPortalScaffold> {
  bool _signingOut = false;

  static const _destinations = [
    _StudentPortalDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      routeName: '/student-dashboard',
    ),
    _StudentPortalDestination(
      label: 'Room Availability',
      icon: Icons.meeting_room_outlined,
      routeName: '/student/room-availability',
    ),
    _StudentPortalDestination(
      label: 'Campus Navigation',
      icon: Icons.map_outlined,
      routeName: '/campus-map',
    ),
    _StudentPortalDestination(
      label: 'My Profile',
      icon: Icons.account_circle_outlined,
      routeName: '/student/profile',
    ),
  ];

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.authService.logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on StudentApiException catch (error) {
      _showLogoutError(error.message);
    } on PlatformException {
      _showLogoutError('Secure sign-out could not be completed.');
    } on Exception {
      _showLogoutError('Sign-out could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showLogoutError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _selectedDestination(String? routeName) {
    if (routeName == '/student/profile') return 3;
    if (routeName == '/campus-map' ||
        routeName == '/student/campus-navigation') {
      return 2;
    }
    if (routeName == '/student/room-availability' ||
        routeName?.startsWith('/student/buildings/') == true ||
        routeName?.startsWith('/student/rooms/') == true) {
      return 1;
    }
    return 0;
  }

  void _openDestination(int index) {
    final targetName = _destinations[index].routeName;
    final navigator = Navigator.of(context);
    if (ModalRoute.of(context)?.settings.name == targetName) return;

    if (targetName == '/campus-map') {
      navigator.pushNamed(
        targetName,
        arguments: StudentPortalMapOrigin.studentPortal,
      );
      return;
    }

    var targetAlreadyOpen = false;
    navigator.popUntil((route) {
      if (route.settings.name == targetName) {
        targetAlreadyOpen = true;
        return true;
      }
      return route.isFirst;
    });
    if (!targetAlreadyOpen) navigator.pushNamed(targetName);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authService.isStudentAuthenticated) {
      return Scaffold(
        backgroundColor: studentCanvas,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: studentNavy,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: studentBlue, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'A verified Student session is required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: studentInk),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    '/login',
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopLayout = constraints.maxWidth >= 1000;
        final selectedDestination =
            _selectedDestination(ModalRoute.of(context)?.settings.name);
        final navigationPanel = _StudentNavigationPanel(
          destinations: _destinations,
          selectedIndex: selectedDestination,
          profile: widget.authService.currentProfile,
          onDestinationSelected: _openDestination,
        );
        final scaffold = Scaffold(
          backgroundColor: studentCanvas,
          drawer: desktopLayout
              ? null
              : Drawer(
                  width: constraints.maxWidth < 360
                      ? constraints.maxWidth * 0.88
                      : 304,
                  child: navigationPanel,
                ),
          appBar: AppBar(
            backgroundColor: studentNavy,
            foregroundColor: Colors.white,
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              ...widget.actions,
              IconButton(
                tooltip: 'Sign out',
                onPressed: _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: widget.child,
        );

        if (!desktopLayout) return scaffold;
        return Row(
          children: [
            SizedBox(width: 272, child: navigationPanel),
            Expanded(child: scaffold),
          ],
        );
      },
    );
  }
}

class _StudentPortalDestination {
  const _StudentPortalDestination({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final String routeName;
}

class _StudentNavigationPanel extends StatelessWidget {
  const _StudentNavigationPanel({
    required this.destinations,
    required this.selectedIndex,
    required this.profile,
    required this.onDestinationSelected,
  });

  final List<_StudentPortalDestination> destinations;
  final int selectedIndex;
  final StudentProfile? profile;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF0E2958),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UCU SMART+',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Student Portal',
                            style: TextStyle(
                              color: Color(0xFFB7CCE8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x33FFFFFF)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          selected: selectedIndex == index,
                          selectedTileColor: const Color(0xFF0E4C6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(
                            destinations[index].icon,
                            color: Colors.white,
                            size: 22,
                          ),
                          title: Text(
                            destinations[index].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            if (Scaffold.maybeOf(context)?.isDrawerOpen ??
                                false) {
                              Navigator.of(context).pop();
                            }
                            onDestinationSelected(index);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (profile != null) ...[
                const Divider(height: 1, color: Color(0x33FFFFFF)),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0E4C6B),
                        child: Text(
                          profile!.firstName.isNotEmpty
                              ? profile!.firstName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile!.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Student',
                              style: TextStyle(
                                color: Color(0xFFB7CCE8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class StudentSectionHeader extends StatelessWidget {
  const StudentSectionHeader({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: studentInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: studentMuted, height: 1.4),
            ),
          ],
        ],
      );
}

class StudentMetricCard extends StatelessWidget {
  const StudentMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accent = studentBlue,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAF3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x090D2B50),
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: studentInk,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(title, style: const TextStyle(color: studentMuted)),
          ],
        ),
      );
}

class StudentLoadState extends StatelessWidget {
  const StudentLoadState({
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.child,
    this.loadingLabel = 'Loading student information…',
    super.key,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: studentBlue),
            const SizedBox(height: 14),
            Text(loadingLabel, style: const TextStyle(color: studentMuted)),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: studentMuted,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: studentInk, height: 1.4),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}

class StudentEmptyState extends StatelessWidget {
  const StudentEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF9AAAC0)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: studentInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: studentMuted, height: 1.45),
              ),
            ],
          ),
        ),
      );
}

class StudentInfoRow extends StatelessWidget {
  const StudentInfoRow({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: studentBlue),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(color: studentMuted),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: studentInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
