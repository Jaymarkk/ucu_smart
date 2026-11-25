import 'dart:async';

import 'package:flutter/material.dart';

import '../models/student_portal_models.dart';
import '../services/student_api_service.dart';
import '../services/student_auth_service.dart';
import '../widgets/student_portal_components.dart';
import 'student_room_availability_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  StudentDashboardScreen({
    super.key,
    required this.authService,
    StudentApiService? api,
  }) : api = api ?? StudentApiService.instance;

  final StudentAuthService authService;
  final StudentApiService api;

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  StudentDashboardData? _dashboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
  }

  Future<void> _loadDashboard() async {
    final token = widget.authService.verifiedStudentToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Your Student session is unavailable. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dashboard = await widget.api.fetchDashboard(token);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } on StudentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => StudentPortalScaffold(
        authService: widget.authService,
        title: 'Student Dashboard',
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        child: StudentLoadState(
          isLoading: _isLoading,
          error: _error,
          onRetry: _loadDashboard,
          child: _dashboard == null
              ? const StudentEmptyState(
                  title: 'No dashboard information',
                  message: 'Dashboard information is not available right now.',
                )
              : _DashboardContent(
                  profile: widget.authService.currentProfile!,
                  onRoomsTap: _openRoomAvailability,
                ),
        ),
      );

  void _openRoomAvailability() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/student/room-availability'),
        builder: (_) => StudentRoomAvailabilityScreen(
          authService: widget.authService,
          api: widget.api,
        ),
      ),
    );
  }

}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.profile,
    required this.onRoomsTap,
  });

  final StudentProfile profile;
  final VoidCallback onRoomsTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 760;
        final horizontalPadding = wideLayout ? 32.0 : 20.0;
        final roomAvailabilityCard = _MainServiceCard(
          icon: Icons.home_work_outlined,
          title: 'Room Availability',
          description:
              'Check which classrooms are currently available or occupied across the campus.',
          actionLabel: 'View Available Rooms',
          onTap: onRoomsTap,
          isActionCard: true,
        );
        const helpCards = [
          _DashboardHelpCard(
            step: '1',
            title: 'Find a Building',
            description:
                'Browse the available buildings and facilities around the campus.',
          ),
          _DashboardHelpCard(
            step: '2',
            title: 'Check a Room',
            description:
                'View whether a classroom is currently available or occupied.',
          ),
          _DashboardHelpCard(
            step: '3',
            title: 'Navigate with Mobile',
            description:
                'Use the UCU Smart+ mobile application to navigate around the campus.',
          ),
        ];

        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            wideLayout ? 30 : 22,
            horizontalPadding,
            32,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StudentWelcomeHeader(profile: profile),
                    const SizedBox(height: 28),
                    roomAvailabilityCard,
                    const SizedBox(height: 28),
                    Container(
                      padding: EdgeInsets.all(wideLayout ? 30 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E5E9)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080D2B50),
                            blurRadius: 18,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How UCU Smart+ Helps You',
                            style: TextStyle(
                              color: Color(0xFF0E2958),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Quickly find the information you need around campus.',
                            style: TextStyle(color: studentMuted, height: 1.45),
                          ),
                          const SizedBox(height: 22),
                          if (wideLayout)
                            Row(
                              children: [
                                for (var index = 0;
                                    index < helpCards.length;
                                    index++) ...[
                                  if (index > 0) const SizedBox(width: 18),
                                  Expanded(child: helpCards[index]),
                                ],
                              ],
                            )
                          else
                            Column(
                              children: [
                                for (var index = 0;
                                    index < helpCards.length;
                                    index++) ...[
                                  if (index > 0) const SizedBox(height: 12),
                                  helpCards[index],
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentWelcomeHeader extends StatelessWidget {
  const _StudentWelcomeHeader({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Color(0xFF0E2958),
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'Welcome back, '),
                TextSpan(
                  text: profile.fullName,
                  style: const TextStyle(color: Color(0xFF0E4C6B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find available classrooms and access campus navigation through UCU Smart+.',
            style: TextStyle(color: studentMuted, height: 1.5, fontSize: 15),
          ),
        ],
      );
}

class _MainServiceCard extends StatelessWidget {
  const _MainServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    required this.isActionCard,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isActionCard;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 224),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E5E9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080D2B50),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E4C6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: const Color(0xFF0E4C6B)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF0E2958),
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isActionCard)
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF0E4C6B),
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        description,
                        style: const TextStyle(
                          color: studentMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isActionCard)
                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                color: Color(0xFF0E4C6B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Color(0xFF0E4C6B),
                            ),
                          ],
                        )
                      else
                        FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: Text(actionLabel),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0E2958),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DashboardHelpCard extends StatelessWidget {
  const _DashboardHelpCard({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF0F1F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0E4C6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                step,
                style: const TextStyle(
                  color: Color(0xFF0E4C6B),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF303943),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(
                color: studentMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}
