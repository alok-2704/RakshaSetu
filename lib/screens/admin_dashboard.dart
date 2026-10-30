
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import '../groq_service.dart';
import 'profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String adminDepartment;

  const AdminDashboard({
    super.key,
    required this.adminDepartment,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentTab = 0;

  final Set<String> shownAlerts = {};
  final Map<String, Map<String, String>> aiCache = {};

  Color get accent {
    switch (widget.adminDepartment.toLowerCase()) {
      case 'fire':
        return const Color(0xFFD92D35);
      case 'medical':
        return const Color(0xFF35BDF2);
      case 'security':
        return const Color(0xFF173B70);
      case 'hazard / accident':
      case 'hazard':
        return const Color(0xFFE99A22);
      case 'violence / harassment':
      case 'violence':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF173B70);
    }
  }

  IconData get deptIcon {
    switch (widget.adminDepartment.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'security':
        return Icons.shield_rounded;
      case 'hazard / accident':
      case 'hazard':
        return Icons.warning_amber_rounded;
      case 'violence / harassment':
      case 'violence':
        return Icons.gpp_maybe_rounded;
      default:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String get departmentSubtitle {
    switch (widget.adminDepartment.toLowerCase()) {
      case 'medical':
        return 'Medical response dashboard';
      case 'fire':
        return 'Fire response dashboard';
      case 'security':
        return 'Campus security dashboard';
      case 'hazard / accident':
      case 'hazard':
        return 'Hazard response dashboard';
      case 'violence / harassment':
      case 'violence':
        return 'Incident response dashboard';
      default:
        return 'Campus emergency overview';
    }
  }

  Future<void> showAlertNotification(
    String title,
    String body,
  ) async {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sanketx_alerts',
          'SanketX Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Map<String, String> getAiInsight(String type) {
    final t = type.toLowerCase();

    if (t == 'fire') {
      return {
        'severity': 'High',
        'priority': 'Immediate',
        'action': 'Review the fire report and coordinate the campus fire response team.',
      };
    }

    if (t == 'medical') {
      return {
        'severity': 'High',
        'priority': 'Immediate',
        'action': 'Review the medical report and coordinate an available campus medical responder.',
      };
    }

    if (t == 'security') {
      return {
        'severity': 'High',
        'priority': 'Urgent',
        'action': 'Review the security report and coordinate an authorized campus security responder.',
      };
    }

    return {
      'severity': 'Medium',
      'priority': 'Urgent',
      'action': 'Review the reported incident and coordinate the appropriate campus response team.',
    };
  }

  Future<Map<String, String>> getSmartInsight(
    String id,
    String type,
    String description,
  ) async {
    if (aiCache.containsKey(id)) {
      return aiCache[id]!;
    }

    try {
      final result = await GroqService.analyzeIncident(
        '''
Department: ${widget.adminDepartment}
Category: $type
Description: $description
''',
      );

      result['source'] = 'Groq AI';

      aiCache[id] = result;
      return result;
    } catch (e) {
      debugPrint('Admin AI insight failed: $e');

      final fallback = getAiInsight(type);
      fallback['source'] = 'Offline Fallback';

      aiCache[id] = fallback;
      return fallback;
    }
  }

  List<QueryDocumentSnapshot> filteredDocs(
    List<QueryDocumentSnapshot> docs,
    bool resolved,
  ) {
    final dept = widget.adminDepartment.toLowerCase();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final type = (data['type'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (type != dept) return false;

      return resolved ? status == 'resolved' : status != 'resolved';
    }).toList();
  }

  int sortByTime(
    QueryDocumentSnapshot a,
    QueryDocumentSnapshot b,
  ) {
    final ad =
        (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
    final bd =
        (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;

    return bd.compareTo(ad);
  }

  Widget sectionCard(
    BuildContext context,
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.65),
        ),
      ),
      child: child,
    );
  }

  Widget statCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.65),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tabButton(
    BuildContext context,
    String text,
    int index,
    int count,
  ) {
    final selected = currentTab == index;
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            currentTab = index;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? accent : cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent
                  : cs.outlineVariant.withOpacity(.7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(.2)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusBadge(String status) {
    final normalized = status.toLowerCase();

    final Color color;
    final String label;

    if (normalized == 'accepted') {
      color = const Color(0xFF16805D);
      label = 'ACCEPTED';
    } else if (normalized == 'resolved') {
      color = const Color(0xFF16805D);
      label = 'RESOLVED';
    } else {
      color = const Color(0xFFE99A22);
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: .6,
        ),
      ),
    );
  }

  Widget emptyState(
    BuildContext context, {
    required bool history,
  }) {
    final cs = Theme.of(context).colorScheme;

    return sectionCard(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                history
                    ? Icons.history_rounded
                    : Icons.notifications_none_rounded,
                size: 30,
                color: accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              history ? 'No resolved alerts yet' : 'No active alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              history
                  ? 'Resolved department alerts will appear here.'
                  : 'New alerts assigned to this department will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget aiInsightCard(
    BuildContext context,
    Map<String, String> ai,
  ) {
    final cs = Theme.of(context).colorScheme;

    final source = ai['source'] ?? 'Unknown';
    final severity = ai['severity'] ?? 'Unknown';
    final priority = ai['priority'] ?? 'Review';
    final action = ai['action'] ?? 'Review the reported incident.';

    final bool isFallback = source == 'Offline Fallback';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withOpacity(.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department AI Insight',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isFallback ? 'Offline recommendation' : 'Groq AI analysis',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isFallback
                    ? Icons.cloud_off_outlined
                    : Icons.verified_rounded,
                color: isFallback
                    ? cs.onSurfaceVariant
                    : const Color(0xFF16805D),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _insightChip(
                'Severity',
                severity,
                severity.toLowerCase() == 'high'
                    ? const Color(0xFFD92D35)
                    : accent,
              ),
              _insightChip(
                'Priority',
                priority,
                priority.toLowerCase() == 'immediate'
                    ? const Color(0xFFD92D35)
                    : accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recommended internal action',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            action,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightChip(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget alertCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    bool history,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    final desc = (data['description'] ?? '').toString();
    final status = (data['status'] ?? '').toString().toLowerCase();

    final building = (data['building'] ?? 'Unknown location').toString();
    final floor = (data['floor'] ?? 'N/A').toString();
    final room = (data['room'] ?? 'N/A').toString();

    String timeText = 'Time unavailable';

    final ts = data['createdAt'] as Timestamp?;

    if (ts != null) {
      final dt = ts.toDate();

      timeText =
          '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }

    return FutureBuilder<Map<String, String>>(
      future: getSmartInsight(
        doc.id,
        (data['type'] ?? '').toString(),
        desc,
      ),
      builder: (context, snap) {
        final ai = snap.data ??
            {
              ...getAiInsight((data['type'] ?? '').toString()),
              'source': 'Analyzing',
            };

        final cs = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(.65),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        deptIcon,
                        color: accent,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['type'] ?? widget.adminDepartment} Alert',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$building • Floor $floor • $room',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    statusBadge(status),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      desc,
                      style: TextStyle(
                        color: cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeText,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                aiInsightCard(context, ai),
                if (!history) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      if (status != 'accepted')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('alerts')
                                  .doc(doc.id)
                                  .update({
                                'status': 'accepted',
                              });
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      if (status != 'accepted')
                        const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('alerts')
                                .doc(doc.id)
                                .update({
                              'status': 'resolved',
                            });
                          },
                          icon: const Icon(
                            Icons.done_all_rounded,
                            size: 18,
                          ),
                          label: const Text('Resolve'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            minimumSize: const Size(0, 48),
                            side: BorderSide(
                              color: accent.withOpacity(.55),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('alerts')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load alerts.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: accent,
                ),
              );
            }

            final docs = snapshot.data!.docs;

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              final type =
                  (data['type'] ?? '').toString().toLowerCase();

              final status =
                  (data['status'] ?? '').toString().toLowerCase();

              if (type == widget.adminDepartment.toLowerCase() &&
                  status == 'pending' &&
                  !shownAlerts.contains(doc.id)) {
                shownAlerts.add(doc.id);

                showAlertNotification(
                  'New ${widget.adminDepartment} Alert',
                  '${data['building']} • ${data['room']}',
                );
              }
            }

            final active = filteredDocs(docs, false)
              ..sort(sortByTime);

            final history = filteredDocs(docs, true)
              ..sort(sortByTime);

            final list = currentTab == 0 ? active : history;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department header
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Icon(
                              deptIcon,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.adminDepartment} Command Center',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  departmentSubtitle,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: accent.withOpacity(.10),
                              foregroundColor: accent,
                              fixedSize: const Size(48, 48),
                            ),
                            icon: const Icon(
                              Icons.person_rounded,
                              size: 25,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Summary stats
                      Row(
                        children: [
                          Expanded(
                            child: statCard(
                              context,
                              title: 'Open',
                              value: active.length.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: statCard(
                              context,
                              title: 'Resolved',
                              value: history.length.toString(),
                              icon: Icons.done_all_rounded,
                              color: const Color(0xFF16805D),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Active / History tabs
                      Row(
                        children: [
                          tabButton(
                            context,
                            'Active',
                            0,
                            active.length,
                          ),
                          const SizedBox(width: 12),
                          tabButton(
                            context,
                            'History',
                            1,
                            history.length,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Section heading
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentTab == 0
                                  ? 'Active department alerts'
                                  : 'Alert history',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '${list.length} ${list.length == 1 ? 'alert' : 'alerts'}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (list.isEmpty)
                        emptyState(
                          context,
                          history: currentTab == 1,
                        )
                      else
                        ...list.map(
                          (doc) => alertCard(
                            context,
                            doc,
                            currentTab == 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
