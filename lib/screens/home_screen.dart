import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../groq_service.dart';
import '../widgets/raksha_mitra_logo.dart';
import '../main.dart';
import 'alert_screen.dart';
import 'alert_tracking_screen.dart';
import 'ai_safety_assistant_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const Color navy = Color(0xFF173B70);
  static const Color red = Color(0xFFD92D35);
  static const Color pageBackground = Color(0xFFF7F8FA);
  static const Color green = Color(0xFF16805D);

  int _selectedIndex = 0;
  String _userName = 'there';
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _alertSubscription;

  final Map<String, String> _seenStatuses = {};

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _loadUserName(user.uid);
      _listenForStatusChanges(user.uid);
    }
  }

  Future<void> _loadUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      final name = doc.data()?['name']?.toString().trim();
      final emailName =
          FirebaseAuth.instance.currentUser?.email?.split('@').first;

      setState(() {
        _userName = name != null && name.isNotEmpty
            ? name
            : (emailName != null && emailName.isNotEmpty
                ? emailName
                : 'there');
      });
    } catch (_) {
      // Keep the dashboard usable if the profile cannot be loaded.
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _myAlerts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('alerts')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  void _listenForStatusChanges(String uid) {
    _alertSubscription = FirebaseFirestore.instance
        .collection('alerts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status =
            (data['status'] ?? '').toString().toLowerCase();

        if (!_seenStatuses.containsKey(doc.id)) {
          _seenStatuses[doc.id] = status;
          continue;
        }

        final previousStatus = _seenStatuses[doc.id];

        if (previousStatus == status) continue;

        _seenStatuses[doc.id] = status;

        if (status == 'accepted') {
          _showStatusNotification(
            'Alert Accepted',
            '${data['type'] ?? 'Emergency'} team is responding.',
          );
        } else if (status == 'resolved') {
          _showStatusNotification(
            'Alert Resolved',
            'Your ${data['type'] ?? 'emergency'} alert has been closed.',
          );
        }
      }
    });
  }

  Future<void> _showStatusNotification(
    String title,
    String body,
  ) async {
    try {
      await localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rakshasetu_alerts',
            'RakshaSetu Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {
      // Notifications should not prevent the dashboard from working.
    }
  }

  void _openAlertScreen() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AlertScreen(),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openAlertTracking(String alertId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AlertTrackingScreen(alertId: alertId),
      ),
    );
  }

  void _openAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AISafetyAssistantScreen(),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF2563A6);
      case 'resolved':
        return green;
      case 'pending':
        return const Color(0xFFB7791F);
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'security':
        return Icons.shield_outlined;
      case 'hazard / accident':
      case 'hazard':
      case 'accident':
        return Icons.warning_amber_rounded;
      case 'violence / harassment':
      case 'violence':
      case 'harassment':
        return Icons.report_gmailerrorred_outlined;
      default:
        return Icons.emergency_outlined;
    }
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 12,
              color: navy,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(alpha: dark ? 0.24 : 0.13),
        ),
        boxShadow: dark ? const [] : [
          BoxShadow(
            color: const Color(0xFF183B70).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAiGuidance(String type, String description) {
    return FutureBuilder<String>(
      future: GroqService.generateStudentGuide(
        '$type $description',
      ),
      builder: (context, snapshot) {
        final guide = snapshot.data ??
            'Move to a safe place if possible. Avoid further danger '
                'and follow instructions from authorized responders. '
                'If the situation is immediately life-threatening, '
                'contact local emergency services.';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: navy,
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'AI Safety Guidance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Preparing safety guidance...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            Text(
              guide,
              style: const TextStyle(
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _homeContent() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const RakshaMitraLogo(
                size: 46,
                backgroundColor: Color(0xFFE8EEFA),
                shieldColor: Color(0xFF173B70),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RakshaSetu',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Emergency Response',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: _openProfile,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                side: BorderSide(
                  color: colors.outline.withValues(alpha: 0.18),
                ),
              ),
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ],
        ),

        const SizedBox(height: 26),

        Text(
          'Welcome back,',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your safety matters. Help is one tap away.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 22),

        // Raise Alert action.
        Material(
          color: red,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: _openAlertScreen,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 23,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raise Alert',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Notify your emergency response team',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Daily safety tip.
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFB7791F),
                    size: 22,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Safety Tip of the Day',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.verified_user_outlined,
                    color: navy,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              const Text(
                'Know your nearest emergency exit.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Identify the nearest safe exit in your building and keep '
                'access routes clear. During an emergency, follow your '
                'organization’s evacuation instructions.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        _sectionTitle('My active alert'),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _myAlerts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _panel(
                child: const Text(
                  'Unable to load your alerts. Please check your connection.',
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _panel(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs.toList() ?? [];

            docs.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];

              final aMillis = aTime is Timestamp
                  ? aTime.millisecondsSinceEpoch
                  : 0;
              final bMillis = bTime is Timestamp
                  ? bTime.millisecondsSinceEpoch
                  : 0;

              return bMillis.compareTo(aMillis);
            });

            final active = docs.where((doc) {
              final status = (doc.data()['status'] ?? '')
                  .toString()
                  .toLowerCase();

              return status != 'resolved';
            }).toList();

            if (active.isEmpty) {
              return _panel(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F4EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No active alerts',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your reported incidents will appear here.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final alertDoc = active.first;
            final data = alertDoc.data();

            final type = (data['type'] ?? 'Emergency').toString();
            final status = (data['status'] ?? 'pending').toString();
            final description =
                (data['description'] ?? '').toString();

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openAlertTracking(alertDoc.id),
                child: _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: red.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _typeIcon(type),
                              color: red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${data['building'] ?? 'Location unavailable'}'
                        ' • ${data['room'] ?? 'Area unavailable'}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],

                      // AI precautions remain visible on the Home card.
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildAiGuidance(type, description),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: navy,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap to view alert details and department response.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: navy,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 26),

        _sectionTitle('Recent activity'),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _myAlerts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final docs = snapshot.data!.docs.toList();

            docs.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];

              final aMillis = aTime is Timestamp
                  ? aTime.millisecondsSinceEpoch
                  : 0;
              final bMillis = bTime is Timestamp
                  ? bTime.millisecondsSinceEpoch
                  : 0;

              return bMillis.compareTo(aMillis);
            });

            if (docs.isEmpty) {
              return _panel(
                child: const Text(
                  'Your recent alerts will appear here.',
                ),
              );
            }

            return Column(
              children: docs.take(3).map((doc) {
                final data = doc.data();
                final type = (data['type'] ?? 'Emergency').toString();
                final status =
                    (data['status'] ?? 'pending').toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _panel(
                    child: Row(
                      children: [
                        Icon(
                          _typeIcon(type),
                          color: navy,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['building'] ?? 'Unknown location'}'
                                ' • ${data['room'] ?? 'Unknown area'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.isEmpty
                              ? 'Unknown'
                              : '${status[0].toUpperCase()}'
                                  '${status.substring(1)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 90),
      ],
    );
  }

Widget _historyContent() {
  final colors = Theme.of(context).colorScheme;

  const departments = [
    'All',
    'Fire',
    'Medical',
    'Security',
    'Hazard / Accident',
    'Violence / Harassment',
  ];

  const departmentColors = {
    'All': Color(0xFF173B70),
    'Fire': Color(0xFFD92D35),
    'Medical': Color(0xFF16805D),
    'Security': Color(0xFF173B70),
    'Hazard / Accident': Color(0xFFE58A18),
    'Violence / Harassment': Color(0xFF8B45A8),
  };

  const departmentIcons = {
    'All': Icons.grid_view_rounded,
    'Fire': Icons.local_fire_department_rounded,
    'Medical': Icons.medical_services_rounded,
    'Security': Icons.shield_rounded,
    'Hazard / Accident': Icons.warning_amber_rounded,
    'Violence / Harassment':
        Icons.report_gmailerrorred_rounded,
  };

  String selectedDepartment = 'All';

  String departmentName(String type) {
    final normalized = type.trim().toLowerCase();

    if (normalized.contains('fire')) return 'Fire';
    if (normalized.contains('medical')) return 'Medical';
    if (normalized.contains('security')) return 'Security';

    if (normalized.contains('hazard') ||
        normalized.contains('accident')) {
      return 'Hazard / Accident';
    }

    if (normalized.contains('violence') ||
        normalized.contains('harassment')) {
      return 'Violence / Harassment';
    }

    return 'Other Alerts';
  }

  String formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Time unavailable';
  }

  return StatefulBuilder(
    builder: (context, setFilterState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alert History',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'View and track your reported alerts.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          // Department filter heading.
          const Text(
            'Filter by department',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          // Department filter chips.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: departments.map((department) {
                final isSelected =
                    selectedDepartment == department;

                final departmentColor =
                    departmentColors[department] ?? navy;

                return Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: ChoiceChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      departmentIcons[department] ??
                          Icons.notifications_rounded,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : departmentColor,
                    ),
                    label: Text(department),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : departmentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: departmentColor,
                    backgroundColor:
                        departmentColor.withOpacity(0.08),
                    side: BorderSide(
                      color: isSelected
                          ? departmentColor
                          : departmentColor.withOpacity(0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onSelected: (_) {
                      setFilterState(() {
                        selectedDepartment = department;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Filtered alert history.
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _myAlerts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {return _panel(
                  child: const Text(
                    'Unable to load alert history.',
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allDocs = snapshot.data!.docs.toList();

              // Sort alerts newest first.
              allDocs.sort((a, b) {
                final aTime = a.data()['createdAt'];
                final bTime = b.data()['createdAt'];

                final aMillis = aTime is Timestamp
                    ? aTime.millisecondsSinceEpoch
                    : 0;

                final bMillis = bTime is Timestamp
                    ? bTime.millisecondsSinceEpoch
                    : 0;

                return bMillis.compareTo(aMillis);
              });

              // Apply selected department filter.
              final filteredDocs = selectedDepartment == 'All'
                  ? allDocs
                  : allDocs.where((doc) {
                      final type =
                          (doc.data()['type'] ?? '').toString();

                      return departmentName(type) ==
                          selectedDepartment;
                    }).toList();

              if (filteredDocs.isEmpty) {
                return _panel(
                  child: Column(
                    children: [
                      Icon(
                        selectedDepartment == 'All'
                            ? Icons.history_rounded
                            : departmentIcons[selectedDepartment],
                        size: 42,
                        color: colors.onSurfaceVariant,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        selectedDepartment == 'All'
                            ? 'No alerts reported yet.'
                            : 'No $selectedDepartment alerts.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Alerts for this selection will appear here.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Results count.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDepartment == 'All'
                              ? 'All reported alerts'
                              : '$selectedDepartment alerts',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: navy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredDocs.length}',
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // Alert cards.
                  ...filteredDocs.map((doc) {
                    final data = doc.data();

                    final type =
                        (data['type'] ?? 'Emergency').toString();

                    final department = departmentName(type);

                    final departmentColor =
                        departmentColors[department] ?? navy;

                    final departmentIcon =
                        departmentIcons[department] ??
                            Icons.notifications_active_rounded;

                    final status =
                        (data['status'] ?? 'pending')
                            .toString()
                            .toLowerCase();

                    final building =
                        (data['building'] ?? 'Unknown location')
                            .toString();

                    final floor =
                        (data['floor'] ?? '').toString();

                    final room =
                        (data['room'] ?? 'Unknown area')
                            .toString();

                    final description =
                        (data['description'] ?? '')
                            .toString()
                            .trim();

                    final location = [
                      building,
                      if (floor.isNotEmpty) 'Floor $floor',
                      room,
                    ].join(' • ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),

                          // Open alert tracking screen.
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlertTrackingScreen(
                                  alertId: doc.id,
                                ),
                              ),
                            );
                          },

                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.outlineVariant
                                    .withOpacity(0.45),
                              ),
                            ),

                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: departmentColor
                                        .withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    departmentIcon,
                                    color: departmentColor,
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$type Alert',
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),

                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: _statusColor(
                                                status,
                                              ).withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(20),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: _statusColor(
                                                  status,
                                                ),
                                                fontSize: 9,
                                                fontWeight:
                                                    FontWeight
                                                        .w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 7),

                                      Text(
                                        location,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors
                                              .onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        formatDate(
                                          data['createdAt'],
                                        ),
                                        style: TextStyle(
                                          color: colors
                                              .onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),

                                      if (description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          Text(
                                            'View alert details',
                                            style: TextStyle(
                                              color: navy,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons
                                                .arrow_forward_rounded,
                                            size: 14,
                                            color: navy,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ],
      );
    },
  );
}

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : pageBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.025, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _selectedIndex == 0
                          ? _homeContent()
                          : _historyContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
  heroTag: 'rakshaMitraButton',
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  backgroundColor: const Color(0xFF173B70),
  elevation: 5,

  // Open Raksha Mitra AI Assistant
  onPressed: _openAssistant,

  child: const RakshaMitraLogo(
    size: 48,
    backgroundColor: Colors.white,
    shieldColor: Color(0xFF173B70),
  ),
),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: colors.surface,
        elevation: 0,
        indicatorColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF29466D)
            : const Color(0xFFE7EEF8),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}