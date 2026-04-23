import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import '../groq_service.dart';
import 'profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String adminDepartment;

  const AdminDashboard({super.key, required this.adminDepartment});

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
        return Colors.redAccent;
      case 'medical':
        return Colors.lightBlueAccent;
      default:
        return Colors.greenAccent;
    }
  }

  IconData get deptIcon {
    switch (widget.adminDepartment.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.shield;
    }
  }

  Future<void> showAlertNotification(String title, String body) async {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
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
        'action': 'Dispatch fire response team',
      };
    }

    if (t == 'medical') {
      return {
        'severity': 'High',
        'priority': 'Immediate',
        'action': 'Send medical unit now',
      };
    }

    return {
      'severity': 'Medium',
      'priority': 'Urgent',
      'action': 'Deploy security staff',
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
    final result =
        await GroqService.analyzeIncident(
      '$type $description',
    );

    result['source'] = 'Groq AI';

    aiCache[id] = result;
    return result;
  } catch (_) {
    final fallback = getAiInsight(type);

    fallback['source'] =
        'Offline Fallback';

    aiCache[id] = fallback;
    return fallback;
  }
}
  Widget sectionCard(BuildContext context, Widget child) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withOpacity(.2)),
      ),
      child: child,
    );
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

  int sortByTime(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
    final ad = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
    final bd = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

    if (ad == null && bd == null) {
      return 0;
    }
    if (ad == null) return 1;
    if (bd == null) return -1;

    return bd.compareTo(ad);
  }

  Widget statTile(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget tabButton(BuildContext context, String text, int index) {
    final selected = currentTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          currentTab = index;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
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

    String timeText = 'No time';

    final ts = data['createdAt'] as Timestamp?;

    if (ts != null) {
      final dt = ts.toDate();

      timeText =
          '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return FutureBuilder<Map<String, String>>(
      future: getSmartInsight(doc.id, (data['type'] ?? '').toString(), desc),
      builder: (context, snap) {
        final ai = snap.data ?? getAiInsight((data['type'] ?? '').toString());

        return Container(
          margin: const EdgeInsets.only(top: 12),
          child: sectionCard(
            context,
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: accent.withOpacity(.15),
                    child: Icon(deptIcon, color: accent),
                  ),
                  title: Text('${data['type']} Alert'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        '${data['building']} • Floor ${data['floor']} • ${data['room']}',
                      ),
                      if (desc.isNotEmpty) Text('Note: $desc'),
                      const SizedBox(height: 4),
                      Text('Status: ${data['status']}'),
                      Text(timeText),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Response Insight',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                             'Source: ${ai['source']}',
                               ),
                            Text('Severity: ${ai['severity']}'),
                            Text('Priority: ${ai['priority']}'),
                            Text('Action: ${ai['action']}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
                if (!history) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (status != 'accepted')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('alerts')
                                  .doc(doc.id)
                                  .update({'status': 'accepted'});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Accept'),
                          ),
                        ),
                      if (status != 'accepted') const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('alerts')
                                .doc(doc.id)
                                .update({'status': 'resolved'});
                          },
                          child: const Text('Resolve'),
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
          stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              final type = (data['type'] ?? '').toString().toLowerCase();

              final status = (data['status'] ?? '').toString().toLowerCase();

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

            final active = filteredDocs(docs, false)..sort(sortByTime);

            final history = filteredDocs(docs, true)..sort(sortByTime);

            final list = currentTab == 0 ? active : history;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: accent,
                            child: Icon(deptIcon, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.adminDepartment} Command Center',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Live response dashboard',
                                  style: TextStyle(color: cs.onSurfaceVariant),
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
                            icon: CircleAvatar(
                              backgroundColor: accent,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: sectionCard(
                              context,
                              statTile(
                                'Open',
                                active.length.toString(),
                                Icons.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: sectionCard(
                              context,
                              statTile(
                                'Resolved',
                                history.length.toString(),
                                Icons.done_all,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: tabButton(context, 'Active', 0)),
                          const SizedBox(width: 10),
                          Expanded(child: tabButton(context, 'History', 1)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (list.isEmpty)
                        sectionCard(context, const Text('No alerts found')),
                      ...list.map(
                        (doc) => alertCard(context, doc, currentTab == 1),
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
