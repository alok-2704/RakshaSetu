import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Color _roleColor(String role, String department) {
    final normalizedRole = role.trim().toLowerCase();
    final normalizedDepartment = department.trim().toLowerCase();

    if (normalizedRole == 'student') return const Color(0xFF173B70);
    if (normalizedRole == 'organization_admin') return const Color(0xFF5B5BD6);

    switch (normalizedDepartment) {
      case 'fire':
        return const Color(0xFFD92D35);
      case 'medical':
        return const Color(0xFF168B86);
      case 'security':
        return const Color(0xFF2563A6);
      case 'hazard':
      case 'accident':
      case 'hazard / accident':
        return const Color(0xFFE58A18);
      case 'violence':
      case 'harassment':
      case 'violence / harassment':
        return const Color(0xFF8B45A8);
      default:
        return const Color(0xFF173B70);
    }
  }

  IconData _roleIcon(String role, String department) {
    final normalizedRole = role.trim().toLowerCase();
    final normalizedDepartment = department.trim().toLowerCase();

    if (normalizedRole == 'student') return Icons.school_rounded;
    if (normalizedRole == 'organization_admin') {
      return Icons.admin_panel_settings_rounded;
    }

    switch (normalizedDepartment) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'security':
        return Icons.shield_rounded;
      case 'hazard':
      case 'accident':
      case 'hazard / accident':
        return Icons.warning_amber_rounded;
      case 'violence':
      case 'harassment':
      case 'violence / harassment':
        return Icons.gpp_maybe_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user found')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load profile. Please try again.',
                  style: TextStyle(color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = (data['name'] ?? 'User').toString();
          final email = (data['email'] ?? user.email ?? 'No Email').toString();
          final role = (data['role'] ?? 'Unknown').toString();
          final department = (data['department'] ?? 'General').toString();
          final organization = (data['organizationId'] ?? 'org_demo').toString();
          final status = data['isActive'] == false ? 'Inactive' : 'Active';
          final accent = _roleColor(role, department);
          final roleIcon = _roleIcon(role, department);
          final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile identity card: accent is specific to the user's role/department.
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withOpacity(isDark ? 0.22 : 0.10),
                            cs.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: accent.withOpacity(isDark ? 0.42 : 0.20)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accent.withOpacity(0.55), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(isDark ? 0.12 : 0.10),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 43,
                              backgroundColor: accent,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _chip(context, role, roleIcon, accent),
                              _chip(context, department, Icons.apartment_rounded, accent),
                              _chip(
                                context,
                                status,
                                status == 'Active' ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                                status == 'Active' ? const Color(0xFF16805D) : cs.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _sectionCard(
                      context,
                      title: 'Account details',
                      subtitle: 'Your RakshaSetu account information',
                      icon: Icons.badge_outlined,
                      accent: accent,
                      child: Column(
                        children: [
                          _detailRow(context, 'User ID', user.uid, Icons.fingerprint_rounded),
                          _detailRow(context, 'Role', role, Icons.manage_accounts_outlined),
                          _detailRow(context, 'Department', department, Icons.apartment_rounded),
                          _detailRow(context, 'Organization', organization, Icons.domain_rounded),
                          _detailRow(
                            context,
                            'Account status',
                            status,
                            status == 'Active' ? Icons.verified_user_rounded : Icons.block_rounded,
                            valueColor: status == 'Active' ? const Color(0xFF16805D) : cs.error,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _sectionCard(
                      context,
                      title: 'Appearance',
                      subtitle: 'Choose the theme that feels comfortable',
                      icon: Icons.palette_outlined,
                      accent: accent,
                      child: ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (context, mode, _) {
                          final darkSelected = mode == ThemeMode.dark;
                          return Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF0F3F8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _themeChoice(
                                    context,
                                    label: 'Light',
                                    icon: Icons.light_mode_rounded,
                                    selected: !darkSelected,
                                    accent: accent,
                                    onTap: () => saveUserTheme(false),
                                  ),
                                ),
                                Expanded(
                                  child: _themeChoice(
                                    context,
                                    label: 'Dark',
                                    icon: Icons.dark_mode_rounded,
                                    selected: darkSelected,
                                    accent: accent,
                                    onTap: () => saveUserTheme(true),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          themeNotifier.value = ThemeMode.light;
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Log out',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'RakshaSetu • Your campus safety companion',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withOpacity(isDark ? 0.32 : 0.16)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isLast = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String text, IconData icon, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.20 : 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withOpacity(isDark ? 0.42 : 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isDark ? cs.onSurface : accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeChoice(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: Material(
        color: selected ? cs.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? accent : cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
