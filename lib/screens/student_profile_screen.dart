import 'package:flutter/material.dart';

import '../services/student_auth_service.dart';
import '../widgets/student_portal_components.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key, required this.authService});

  final StudentAuthService authService;

  @override
  Widget build(BuildContext context) => StudentPortalScaffold(
        authService: authService,
        title: 'My Profile',
        child: Builder(
          builder: (context) {
            final profile = authService.currentProfile;
            if (profile == null) {
              return const StudentEmptyState(
                title: 'Profile unavailable',
                message: 'Please sign in again to view your profile.',
                icon: Icons.person_off_outlined,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 760;
                final padding = wideLayout ? 32.0 : 20.0;
                const gap = 16.0;
                final detailWidth = wideLayout
                    ? (constraints.maxWidth - padding * 2 - gap) / 2
                    : constraints.maxWidth - padding * 2;
                final status = profile.status.trim().toLowerCase();
                final isActive = status == 'active';
                final statusLabel = status.isEmpty
                    ? 'Unknown'
                    : '${status[0].toUpperCase()}${status.substring(1)}';

                return ListView(
                  padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileHeader(
                              fullName: profile.fullName,
                              initials: _initials(
                                profile.firstName,
                                profile.lastName,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const StudentSectionHeader(
                              title: 'Student Information',
                              subtitle: 'Your registered account details.',
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                _ProfileDetailCard(
                                  width: detailWidth,
                                  label: 'First Name',
                                  value: profile.firstName,
                                ),
                                _ProfileDetailCard(
                                  width: detailWidth,
                                  label: 'Last Name',
                                  value: profile.lastName,
                                ),
                                _ProfileDetailCard(
                                  width: detailWidth,
                                  label: 'Student ID',
                                  value: profile.studentId ?? 'Not provided',
                                ),
                                _ProfileDetailCard(
                                  width: detailWidth,
                                  label: 'Email Address',
                                  value: profile.email,
                                ),
                                _ProfileDetailCard(
                                  width: detailWidth,
                                  label: 'Course',
                                  value: profile.course ?? 'Not provided',
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const StudentSectionHeader(
                              title: 'Account Status',
                            ),
                            const SizedBox(height: 14),
                            _AccountStatusCard(
                              status: statusLabel,
                              isActive: isActive,
                              statusDescription: status.isEmpty
                                  ? 'Your account status is not available.'
                                  : 'Your account is currently $status.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

  String _initials(String firstName, String lastName) {
    final firstInitial = firstName.isEmpty ? '' : firstName[0].toUpperCase();
    final lastInitial = lastName.isEmpty ? '' : lastName[0].toUpperCase();
    return '$firstInitial$lastInitial';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.initials,
  });

  final String fullName;
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          color: studentNavy,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0E2958),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0x33FFFFFF),
              child: Text(
                initials.isEmpty ? 'S' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Student Account',
              style: TextStyle(
                color: Color(0xFFD4E4F8),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'UCU Smart+ Student Portal',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFD4E4F8), height: 1.4),
            ),
          ],
        ),
      );
}

class _ProfileDetailCard extends StatelessWidget {
  const _ProfileDetailCard({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: studentMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                color: studentInk,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({
    required this.status,
    required this.isActive,
    required this.statusDescription,
  });

  final String status;
  final bool isActive;
  final String statusDescription;

  @override
  Widget build(BuildContext context) {
    final accent = isActive ? const Color(0xFF16834A) : const Color(0xFFB54708);
    final badgeBackground =
        isActive ? const Color(0xFFEAF7EF) : const Color(0xFFFFF4E5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Account',
                  style: TextStyle(
                    color: studentInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusDescription,
                  style: const TextStyle(color: studentMuted, height: 1.4),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: accent,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  status,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
