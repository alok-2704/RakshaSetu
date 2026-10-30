
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../groq_service.dart';

class AlertTrackingScreen extends StatelessWidget {
  final String alertId;

  const AlertTrackingScreen({
    super.key,
    required this.alertId,
  });

  static const Color navy = Color(0xFF173B70);
  static const Color red = Color(0xFFD92D35);
  static const Color green = Color(0xFF16805D);
  static const Color background = Color(0xFFF7F8FA);

  String _departmentFor(String type) {
    switch (type.toLowerCase().trim()) {
      case 'fire':
        return 'Fire Department';
      case 'medical':
        return 'Medical Department';
      case 'security':
        return 'Security Department';
      case 'hazard':
      case 'accident':
      case 'hazard / accident':
        return 'Hazard / Accident Department';
      case 'violence':
      case 'harassment':
      case 'violence / harassment':
        return 'Violence / Harassment Department';
      default:
        return 'Emergency Response Department';
    }
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

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';

    return status
        .split('_')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Time unavailable';
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: child,
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: navy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    final color = _statusColor(status);

    IconData icon;
    String message;

    switch (status.toLowerCase()) {
      case 'accepted':
        icon = Icons.support_agent_rounded;
        message = 'The department has accepted your alert.';
        break;
      case 'resolved':
        icon = Icons.check_circle_outline_rounded;
        message = 'The department has marked your alert as resolved.';
        break;
      case 'pending':
        icon = Icons.hourglass_top_rounded;
        message = 'Your alert is waiting for department action.';
        break;
      default:
        icon = Icons.info_outline_rounded;
        message = 'Current status: ${_statusLabel(status)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required String title,
    required String subtitle,
    required bool completed,
    required bool isLast,
    required Color color,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: completed ? color : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: completed ? 14 : 7,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed
                          ? color.withValues(alpha: 0.45)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: completed
                          ? const Color(0xFF172B4D)
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(String status) {
    final normalized = status.toLowerCase();

    final isAccepted =
        normalized == 'accepted' || normalized == 'resolved';
    final isResolved = normalized == 'resolved';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 20),
          _timelineItem(
            title: 'Alert Submitted',
            subtitle: 'Your alert has been recorded.',
            completed: true,
            isLast: false,
            color: navy,
          ),
          _timelineItem(
            title: 'Department Accepted',
            subtitle: isAccepted
                ? 'The department has accepted the alert.'
                : 'Waiting for the department to accept the alert.',
            completed: isAccepted,
            isLast: false,
            color: const Color(0xFF2563A6),
          ),
          _timelineItem(
            title: 'Alert Resolved',
            subtitle: isResolved
                ? 'The department has marked the alert as resolved.'
                : 'This step updates when the department resolves the alert.',
            completed: isResolved,
            isLast: true,
            color: green,
          ),
        ],
      ),
    );
  }

  Widget _aiGuidance(String type, String description) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: navy),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'AI Safety Guidance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: GroqService.generateStudentGuide(
              '$type $description',
            ),
            builder: (context, snapshot) {
              final guide = snapshot.data ??
                  'Move to a safe place if possible, avoid further danger, '
                      'and follow instructions from authorized responders. '
                      'If the situation is immediately life-threatening, '
                      'contact local emergency services.';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        title: const Text(
          'Alert Tracking',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('alerts')
              .doc(alertId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to load alert details. Check your connection.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: navy),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('This alert could not be found.'),
              );
            }

            final data = snapshot.data!.data()!;

            final type = (data['type'] ?? 'Emergency').toString();
            final status = (data['status'] ?? 'pending').toString();
            final building = (data['building'] ?? '').toString();
            final floor = (data['floor'] ?? '').toString();
            final room = (data['room'] ?? '').toString();
            final description =
                (data['description'] ?? '').toString();
            final photoUrl = (data['photoUrl'] ?? '').toString();

            final location = [
              building,
              if (floor.isNotEmpty && floor.toLowerCase() != 'none')
                'Floor $floor',
              if (room.isNotEmpty) 'Room $room',
            ].where((part) => part.trim().isNotEmpty).join(' • ');

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusBanner(status),
                      const SizedBox(height: 20),

                      // Alert details.
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: red.withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.emergency_rounded,
                                    color: red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$type Alert',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: navy,
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
                                    _statusLabel(status).toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 14),
                            _detailRow(
                              Icons.location_on_outlined,
                              'Incident Location',
                              location,
                            ),
                            _detailRow(
                              Icons.business_outlined,
                              'Responsible Department',
                              _departmentFor(type),
                            ),
                            _detailRow(
                              Icons.schedule_rounded,
                              'Submitted At',
                              _formatTime(data['createdAt']),
                            ),
                            _detailRow(
                              Icons.description_outlined,
                              'Incident Description',
                              description,
                            ),
                            if (photoUrl.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photoUrl,
                                  width: double.infinity,
                                  height: 190,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Text(
                                    'Unable to load attached photo.',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Current departmental response.
                      _timeline(status),

                      const SizedBox(height: 20),

                      // AI precautions and safety steps.
                      _aiGuidance(type, description),
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
