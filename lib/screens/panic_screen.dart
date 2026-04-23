import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'profile_screen.dart';
import '../main.dart';
import '../groq_service.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart'
    as stt;

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  int currentIndex = 0;
  final Map<String, String> seenStatuses = {};
  Future<void> showStatusNotification(
  String title,
  String body,
) async {
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
StreamSubscription? alertSub;
  String userName = 'User';
  String building = 'None';
 late stt.SpeechToText speech;

bool isListening = false;

  final floorController = TextEditingController();
  final roomController = TextEditingController();
  final descController = TextEditingController();
  String selectedGuide = '';
  bool sending = false;

final List<String> buildings = [
  'None',
  'IT Building',
  'Main Building',
  'NR Building',
  'Canteen',
  'Gymkhana',
  'Library',
  'Generator Room',
];
void setGuide(String type) {}



  @override
void initState() {
  super.initState();

  final email =
      FirebaseAuth.instance.currentUser?.email;

  if (email != null && email.isNotEmpty) {
    userName = email.split('@').first;
  }
  speech = stt.SpeechToText();

  alertSub = myAlerts().listen((snapshot) {
    for (final doc in snapshot.docs) {
      final data =
          doc.data() as Map<String, dynamic>;

      final status =
          (data['status'] ?? '')
              .toString()
              .toLowerCase();

      if (!seenStatuses.containsKey(doc.id)) {
        seenStatuses[doc.id] = status;
      } else {
        final old = seenStatuses[doc.id];

        if (old != status) {
          seenStatuses[doc.id] = status;

          if (status == 'accepted') {
            showStatusNotification(
              'Alert Accepted',
              '${data['type']} team is responding',
            );
          }

          if (status == 'resolved') {
            showStatusNotification(
              'Alert Resolved',
              '${data['type']} case closed',
            );
          }
        }
      }
    }
  });
}

  bool needsFloor(String b) {
    return b == 'IT Building' ||
        b == 'Main Building' ||
        b == 'NR Building';
  }

  void msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> sendAlert(String type) async {
    if (building == 'None') {
      msg('Choose building');
      return;
    }

    if (needsFloor(building) &&
        floorController.text.trim().isEmpty) {
      msg('Enter floor');
      return;
    }

    if (roomController.text.trim().isEmpty) {
      msg('Enter room / area');
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => sending = true);

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('alerts')
        .add({
      'uid': user.uid,
      'userEmail': user.email,
      'type': type,
      'building': building,
      'floor': needsFloor(building)
          ? floorController.text.trim()
          : 'N/A',
      'room': roomController.text.trim(),
      'status': 'pending',
      'description': descController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

setState(() {
  building = 'None';
  floorController.clear();
  roomController.clear();
  descController.clear();
  sending = false;
  currentIndex = 0;
});

msg('$type alert sent');
  }

  Stream<QuerySnapshot> myAlerts() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('alerts')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  Color typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.redAccent;
      case 'medical':
        return Colors.lightBlueAccent;
      default:
        return Colors.greenAccent;
    }
  }

  IconData typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.shield;
    }
  }

  InputDecoration box(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget sectionCard(
    BuildContext context,
    Widget child,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outline.withOpacity(.2),
        ),
      ),
      child: child,
    );
  }

  Widget header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: cs.primary,
          child: const Icon(Icons.shield,
              color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Campus Emergency',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              Text(
                'Welcome, $userName',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
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
                builder: (_) =>
                    const ProfileScreen(),
              ),
            );
          },
          icon: CircleAvatar(
            backgroundColor: cs.primary,
            child: Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget actionButton(
    String title,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: InkWell(
        onTap: sending
    ? null
    : () {
        setGuide(title);
        sendAlert(title);
      },
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(.35),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> startListening() async {
  final available = await speech.initialize(
    onStatus: (status) {},
    onError: (error) {
      msg(error.errorMsg);
    },
  );

  if (!available) {
    msg('Mic not available. Check permission.');
    return;
  }

  setState(() {
    isListening = true;
  });

  speech.listen(
    onResult: (result) {
      setState(() {
        descController.text =
            result.recognizedWords;
      });
    },
  );
}
Future<void> stopListening() async {
  await speech.stop();

  setState(() {
    isListening = false;
  });
}

Widget homePage(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(context),
      const SizedBox(height: 20),

      sectionCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus Status',
              style: TextStyle(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All Systems Normal',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Emergency teams are online and monitoring alerts.',
              style: TextStyle(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      Text(
        'Current Alert',
        style: Theme.of(context)
            .textTheme
            .titleMedium,
      ),

      const SizedBox(height: 12),

      StreamBuilder<QuerySnapshot>(
        stream: myAlerts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            final status =
                (data['status'] ?? '')
                    .toString()
                    .toLowerCase();

            return status != 'resolved';
          }).toList();

          if (docs.isEmpty) {
            return sectionCard(
              context,
              const Text('No active alerts'),
            );
          }

          final data =
              docs.first.data()
                  as Map<String, dynamic>;

          final type =
              (data['type'] ?? '')
                  .toString();

          final description =
              (data['description'] ?? '')
                  .toString();

          return FutureBuilder<String>(
            future:
                GroqService.generateStudentGuide(
              '$type $description',
            ),
            builder: (context, snap) {
              final guide = snap.data ??
                  fallbackGuide(type);

              return sectionCard(
                context,
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$type Alert',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${data['building']} • ${data['room']}',
                    ),

                    Text(
                      'Status: ${data['status']}',
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Note: $description',
                      ),
                    ],

                    const SizedBox(height: 12),

                    const Text(
                      'AI Safety Guidance',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (snap.connectionState ==
                        ConnectionState.waiting)
                      const Text(
                        'Generating guidance...',
                      ),

                    if (snap.connectionState !=
                        ConnectionState.waiting)
                      Text(guide),
                  ],
                ),
              );
            },
          );
        },
      ),
    ],
  );
}        

  Widget sosPage(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(context),
      const SizedBox(height: 20),

      sectionCard(
        context,
        Column(
          children: [
            DropdownButtonFormField<String>(
              value: building,
              decoration: box(
                context,
                'Choose Building',
                Icons.location_city,
              ),
              items: buildings
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  building = v!;
                });
              },
            ),

            const SizedBox(height: 14),

            if (needsFloor(building)) ...[
              TextField(
                controller: floorController,
                decoration: box(
                  context,
                  'Floor',
                  Icons.layers,
                ),
              ),
              const SizedBox(height: 14),
            ],

            TextField(
              controller: roomController,
              decoration: box(
                context,
                'Room / Area',
                Icons.meeting_room,
              ),
            ),

 SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed:
        isListening
            ? stopListening
            : startListening,
    icon: Icon(
      isListening
          ? Icons.stop
          : Icons.mic,
    ),
    label: Text(
      isListening
          ? 'Stop Listening'
          : 'Start Voice SOS',
    ),
  ),
),

const SizedBox(height: 10),

TextField(
  controller: descController,
  maxLines: 3,
  decoration: box(
    context,
    'Voice Note / Description',
    Icons.edit_note,
  ),
),

          ],
        ),
    ),

      Row(
        children: [
          actionButton(
            'Fire',
            Icons.local_fire_department,
            Colors.redAccent,
          ),
          const SizedBox(width: 10),
          actionButton(
            'Medical',
            Icons.medical_services,
            Colors.lightBlueAccent,
          ),
          const SizedBox(width: 10),
          actionButton(
            'Security',
            Icons.shield,
            Colors.greenAccent,
          ),
        ],
      ),
    ],
  );
}

  Widget historyPage(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(context),
      const SizedBox(height: 20),

      Text(
        'My Alert History',
        style: Theme.of(context).textTheme.titleMedium,
      ),

      const SizedBox(height: 12),

      StreamBuilder<QuerySnapshot>(
        stream: myAlerts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          final sortedDocs = [...docs];

          sortedDocs.sort((a, b) {
            final ad =
                a['createdAt'] as Timestamp?;
            final bd =
                b['createdAt'] as Timestamp?;

            if (ad == null && bd == null) {
              return 0;
            }
            if (ad == null) return 1;
            if (bd == null) return -1;

            return bd.compareTo(ad);
          });

          if (sortedDocs.isEmpty) {
            return sectionCard(
              context,
              const Text('No alerts yet'),
            );
          }

          return Column(
            children: sortedDocs.map((doc) {
              final data =
                  doc.data() as Map<String, dynamic>;

              final c = typeColor(data['type']);

              String timeText = 'No time';

              final ts =
                  data['createdAt'] as Timestamp?;

              if (ts != null) {
                final dt = ts.toDate();

                timeText =
                    '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Container(
                margin:
                    const EdgeInsets.only(bottom: 12),
                child: sectionCard(
                  context,
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          c.withOpacity(.15),
                      child: Icon(
                        typeIcon(data['type']),
                        color: c,
                      ),
                    ),
                    title: Text(
                      '${data['type']} Alert',
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${data['building']} • ${data['status']}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

  Widget body(BuildContext context) {
    if (currentIndex == 0) {
      return homePage(context);
    }
    if (currentIndex == 1) {
      return sosPage(context);
    }
    return historyPage(context);
  }

  @override
void dispose() {
  alertSub?.cancel();
  floorController.dispose();
  roomController.dispose();
  descController.dispose();
  super.dispose();
}
String fallbackGuide(String type) {
  if (type == 'Fire') {
    return
        '• Evacuate immediately\n'
        '• Stay low under smoke\n'
        '• Use nearest safe exit';
  }

  if (type == 'Medical') {
    return
        '• Stay calm\n'
        '• Call nearby help\n'
        '• Keep patient comfortable';
  }

  return
      '• Move to safe area\n'
      '• Avoid confrontation\n'
      '• Wait for responders';
}
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                      18),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 950,
                  ),
                  child: body(context),
                ),
              ),
            ),
            if (sending)
              Container(
                color: Colors.black38,
                child: const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor:
            cs.primary,
        onTap: (i) {
          setState(() {
            currentIndex = i;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sos),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}