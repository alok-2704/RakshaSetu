import 'package:flutter/material.dart';

import '../groq_service.dart';

class AISafetyInsightsScreen extends StatefulWidget {
  final String incidentType;
  final String building;
  final String floor;
  final String room;
  final String description;
  final String? photoUrl;

  const AISafetyInsightsScreen({
    super.key,
    required this.incidentType,
    required this.building,
    required this.floor,
    required this.room,
    required this.description,
    this.photoUrl,
  });

  @override
  State<AISafetyInsightsScreen> createState() =>
      _AISafetyInsightsScreenState();
}

class _AISafetyInsightsScreenState
    extends State<AISafetyInsightsScreen> {
  static const Color navy = Color(0xFF173B70);
  static const Color red = Color(0xFFD92D35);
  static const Color green = Color(0xFF16805D);
  static const Color background = Color(0xFFF7F8FA);

  late Future<String> _guidanceFuture;

  @override
  void initState() {
    super.initState();
    _guidanceFuture = _loadGuidance();
  }

  Future<String> _loadGuidance() async {
    try {
      final prompt = '''
Incident category: ${widget.incidentType}
Building: ${widget.building}
Floor: ${widget.floor}
Room or area: ${widget.room}
Description: ${widget.description.isEmpty
          ? 'No description supplied'
          : widget.description}

Provide 3 to 5 concise, practical immediate safety precautions.
Use simple English and short paragraphs.
Prioritize moving away from danger and contacting authorized
emergency responders when necessary.
Do not diagnose injuries, suggest risky actions, claim that a
response team has been dispatched, or invent incident details.
Mention that official responder instructions take priority.
''';

      final result =
          await GroqService.generateStudentGuide(prompt);

      if (result.trim().isNotEmpty) {
        return result.trim();
      }
    } catch (_) {
      // The screen must remain useful if AI is unavailable.
    }

    return _fallbackGuidance();
  }

  String _fallbackGuidance() {
    switch (widget.incidentType.toLowerCase()) {
      case 'fire':
        return '''
• Move away from fire and smoke toward a safe exit.
• Use stairs instead of elevators during a fire evacuation.
• Do not re-enter the affected area or collect belongings.
• Alert people nearby only when it is safe to do so.
• Contact emergency services if immediate assistance is needed.
''';

      case 'medical':
        return '''
• Check that the surrounding area is safe before approaching.
• Contact the campus medical team or emergency services.
• Follow instructions given by qualified responders.
• Do not attempt medical procedures beyond your training.
• Do not move an injured person unless staying there presents
  an immediate danger.
''';

      case 'security':
        return '''
• Move to a safer location if you can do so without increasing
  the danger.
• Do not confront or follow a suspected threat.
• Inform authorized campus security when it is safe.
• Keep your phone available for important updates.
• Contact emergency services if there is immediate danger.
''';

      case 'hazard / accident':
        return '''
• Keep a safe distance from the hazard or accident area.
• Do not touch damaged equipment, unknown substances, or
  potentially dangerous objects.
• Warn nearby people without putting yourself at risk.
• Report the exact location and visible details to responders.
• Follow instructions from authorized personnel.
''';

      case 'violence / harassment':
        return '''
• Prioritize reaching a safe place.
• Avoid confrontation if it could increase the danger.
• Contact campus security or a trusted authorized staff member.
• Share relevant information only when it is safe.
• Contact emergency services if anyone faces immediate danger.
''';

      default:
        return '''
• Move away from immediate danger when it is safe to do so.
• Tell authorized responders the exact location and what
  happened.
• Avoid investigating or collecting evidence if it puts you
  at risk.
• Keep your phone available for updates.
• Follow official responder instructions.
''';
    }
  }

  List<String> _immediateSteps() {
    final type = widget.incidentType.toLowerCase();

    if (type == 'fire') {
      return [
        'Move away from fire and smoke.',
        'Use a safe evacuation route.',
        'Do not use elevators or re-enter the area.',
      ];
    }

    if (type == 'medical') {
      return [
        'Check that the scene is safe.',
        'Contact qualified medical responders.',
        'Follow professional instructions.',
      ];
    }

    if (type == 'security') {
      return [
        'Move to a safer location if possible.',
        'Avoid confronting a suspected threat.',
        'Contact authorized security personnel.',
      ];
    }

    if (type == 'hazard / accident') {
      return [
        'Keep a safe distance from the hazard.',
        'Do not touch dangerous equipment or substances.',
        'Warn others only when safe.',
      ];
    }

    if (type == 'violence / harassment') {
      return [
        'Prioritize reaching a safe place.',
        'Avoid confrontation if it increases danger.',
        'Contact authorized help when safe.',
      ];
    }

    return [
      'Move away from immediate danger.',
      'Share the incident location with responders.',
      'Follow official safety instructions.',
    ];
  }

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.16),
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: navy, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: navy),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildGuidance() {
    final colors = Theme.of(context).colorScheme;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: navy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Safety Guidance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Precautions for your incident',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: _guidanceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Row(
                  children: [
                    SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: navy,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Preparing safety guidance...',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                );
              }

              final guidance =
                  snapshot.data?.trim().isNotEmpty == true
                      ? snapshot.data!.trim()
                      : _fallbackGuidance();

              return SelectableText(
                guidance,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.65,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'AI guidance can be incomplete. Use your judgment '
            'and follow official emergency instructions.',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmediateSteps() {
    final steps = _immediateSteps();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Immediate Safety Steps',
            Icons.health_and_safety_outlined,
          ),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
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

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: red.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: red,
            size: 23,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Do not delay emergency help',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9F2028),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'RakshaSetu records your campus alert. This screen '
                  'does not itself contact government emergency '
                  'services or confirm that a responder has been '
                  'dispatched. In India, call 112 if immediate '
                  'emergency assistance is required.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: Color(0xFF7F3035),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    final locationParts = <String>[
      widget.building,
      if (widget.floor.isNotEmpty && widget.floor != 'N/A')
        'Floor ${widget.floor}',
      if (widget.room.isNotEmpty) widget.room,
    ];

    final location = locationParts.join(' • ');

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RakshaSetu',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: navy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'EMERGENCY RESPONSE',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Return home',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 27),

                Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F4E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: green,
                      size: 42,
                    ),
                  ),
                ),

                const SizedBox(height: 17),

                const Text(
                  'AI Safety Insights',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Your ${widget.incidentType} alert has been '
                  'recorded successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 23),

                _panel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFFB7791F),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending team review',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'The alert is saved and awaiting review '
                              'by the response team.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0CF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            color: Color(0xFF875A00),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'Incident Details',
                        Icons.assignment_outlined,
                      ),
                      _detailRow(
                        Icons.warning_amber_rounded,
                        'Emergency category',
                        widget.incidentType,
                      ),
                      _detailRow(
                        Icons.location_on_outlined,
                        'Location',
                        location,
                      ),
                      _detailRow(
                        Icons.notes_rounded,
                        'Description',
                        widget.description.trim().isEmpty
                            ? 'No additional description provided'
                            : widget.description.trim(),
                      ),
                    ],
                  ),
                ),

                if (widget.photoUrl != null &&
                    widget.photoUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Attached Evidence',
                          Icons.image_outlined,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.photoUrl!,
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'The attached image could not be displayed.',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                _buildImmediateSteps(),

                const SizedBox(height: 16),

                _buildGuidance(),

                const SizedBox(height: 16),

                _buildWarning(),

                const SizedBox(height: 24),

                SizedBox(
                  height: 53,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'Return to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Stay safe. Follow official instructions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
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
