import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'ai_safety_insights_screen.dart';
import '../groq_service.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  static const Color navy = Color(0xFF173B70);
  static const Color red = Color(0xFFD92D35);
  static const Color green = Color(0xFF16805D);
  static const Color page = Color(0xFFF7F8FA);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => _isDark ? const Color(0xFF171F2C) : Colors.white;
  Color get _surfaceRaised => _isDark ? const Color(0xFF202B3B) : const Color(0xFFFFFFFF);
  Color get _textColor => _isDark ? const Color(0xFFF1F5FB) : const Color(0xFF173B70);
  Color get _mutedText => _isDark ? const Color(0xFFB4C0D0) : const Color(0xFF718096);
  Color get _borderColor => _isDark ? const Color(0xFF354357) : const Color(0xFFDCE2EB);
  Color get _accentColor => _isDark ? const Color(0xFF8CB9FF) : navy;
  Color get _dangerColor => _isDark ? const Color(0xFFFF737B) : red;
  Color get _pageColor => _isDark ? const Color(0xFF0D131D) : page;

  final _floor = TextEditingController();
  final _room = TextEditingController();
  final _description = TextEditingController();

  final _speech = stt.SpeechToText();
  final _picker = ImagePicker();

  XFile? _selectedImage;

  String? _selectedType;
  String _building = 'None';
  String? _error;

  bool _listening = false;
  bool _sending = false;
  bool _confirmation = false;
  bool _submitted = false;

  String _submittedType = '';
  String _submittedDescription = '';
  String? _photoUrl;

  final List<String> _buildings = const [
    'None',
    'IT Building',
    'Main Building',
    'NR Building',
    'Canteen',
    'Gymkhana',
    'Library',
    'Generator Room',
  ];

  final List<_Category> _categories = const [
    _Category(
      'Fire',
      Icons.local_fire_department_rounded,
      Color(0xFFD92D35),
      'Fire, smoke or burning smell',
    ),
    _Category(
      'Medical',
      Icons.medical_services_rounded,
      Color(0xFF0875DF),
      'Injury or medical emergency',
    ),
    _Category(
      'Security',
      Icons.shield_rounded,
      Color(0xFF16805D),
      'Security threat or suspicious activity',
    ),
    _Category(
      'Hazard / Accident',
      Icons.warning_amber_rounded,
      Color(0xFFB7791F),
      'Accident or unsafe equipment',
    ),
    _Category(
      'Violence / Harassment',
      Icons.report_gmailerrorred_rounded,
      Color(0xFF8B4CA8),
      'Violence, threats or harassment',
    ),
  ];

  bool get _needsFloor =>
      _building == 'IT Building' ||
      _building == 'Main Building' ||
      _building == 'NR Building';

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  InputDecoration _decoration(
    String hint, {
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          icon == null ? null : Icon(icon, size: 19, color: _accentColor),
      filled: true,
      fillColor: _surfaceRaised,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: _borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: _textColor,
          width: 1.3,
        ),
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _categoryTile(_Category category) {
    final selected = _selectedType == category.name;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _sending
          ? null
          : () {
              setState(() {
                _selectedType = category.name;
                _error = null;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 86,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.09)
              : category.color.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? category.color
                : category.color.withValues(alpha: 0.18),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: category.color,
                    size: 23,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  color: category.color,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(
                child: _categoryTile(_categories[i]),
              ),
              if (i != 2) const SizedBox(width: 9),
            ],
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _categoryTile(_categories[3]),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _categoryTile(_categories[4]),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    if (_sending) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (!mounted || image == null) return;

      final file = File(image.path);
      final size = await file.length();

      if (size > 10 * 1024 * 1024) {
        _message(
          'Please select an image smaller than 10 MB.',
        );
        return;
      }

      setState(() {
        _selectedImage = image;
        _error = null;
      });
    } catch (_) {
      _message(
        'Could not open the photo picker. Please try again.',
      );
    }
  }

  Future<void> _startVoiceTyping() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (!mounted) return;

          setState(() => _listening = false);
          _message(
            'Voice input failed. Please try typing.',
          );
        },
      );

      if (!mounted) return;

      if (!available) {
        _message(
          'Speech recognition is unavailable. '
          'Check microphone permission.',
        );
        return;
      }

      setState(() => _listening = true);

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _description.text = result.recognizedWords;
            _description.selection = TextSelection.collapsed(
              offset: _description.text.length,
            );
          });
        },
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _listening = false);
      _message('Unable to start voice input.');
    }
  }

  Future<void> _stopVoiceTyping() async {
    await _speech.stop();

    if (mounted) {
      setState(() => _listening = false);
    }
  }

  void _next() {
    if (_selectedType == null) {
      _message('Please select an emergency type.');
      return;
    }

    if (_building == 'None') {
      _message('Please select a building or location.');
      return;
    }

    if (_needsFloor && _floor.text.trim().isEmpty) {
      _message('Please enter the floor.');
      return;
    }

    if (_room.text.trim().isEmpty) {
      _message('Please enter the room or area.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _confirmation = true;
      _error = null;
    });
  }

  Future<String?> _uploadImage(
    String uid,
    String alertId,
  ) async {
    if (_selectedImage == null) return null;

    final file = File(_selectedImage!.path);

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('alert_images')
        .child(uid)
        .child('$alertId.jpg');

    final uploadTask = await storageRef.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    return uploadTask.ref.getDownloadURL();
  }

  Future<void> _confirmAndSubmit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message(
        'Please sign in again before reporting an alert.',
      );
      return;
    }

    if (_sending) return;

    if (_listening) {
      await _stopVoiceTyping();
    }

    if (!mounted) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _sending = true;
      _error = null;
    });

    final type = _selectedType!;
    final description = _description.text.trim();

    String? uploadedPhotoUrl;
    String? alertId;

    try {
      // Upload the photo first. If upload fails, no alert is created.
      if (_selectedImage != null) {
        final id =
            FirebaseFirestore.instance.collection('alerts').doc().id;

        uploadedPhotoUrl = await _uploadImage(
          user.uid,
          id,
        );

        alertId = id;
      }

      final alertData = <String, dynamic>{
        'uid': user.uid,
        'userEmail': user.email,
        'type': type,
        'building': _building,
        'floor': _needsFloor
            ? _floor.text.trim()
            : 'N/A',
        'room': _room.text.trim(),
        'status': 'pending',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (uploadedPhotoUrl != null) {
        alertData['photoUrl'] = uploadedPhotoUrl;
      }

      if (alertId != null) {
        await FirebaseFirestore.instance
            .collection('alerts')
            .doc(alertId)
            .set(alertData);
      } else {
        await FirebaseFirestore.instance
            .collection('alerts')
            .add(alertData);
      }

      if (!mounted) return;

      setState(() {
        _submitted = true;
        _submittedType = type;
        _submittedDescription = description;
        _photoUrl = uploadedPhotoUrl;
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _error =
            'Alert submission failed. Check Firebase Storage setup, '
            'network access and security rules, then try again.';
      });
    }
  }

  Widget _topBar(
    String title,
    VoidCallback onBack,
  ) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: _textColor,
          ),
          tooltip: 'Back',
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _textColor,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(
          'Raise Alert',
          () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),

        _heading('1. Select Emergency Type'),
        _categoryGrid(),

        const SizedBox(height: 22),
        _heading('2. Location'),

        DropdownButtonFormField<String>(
          initialValue: _building,
          isExpanded: true,
          decoration: _decoration(
            'Select building or location',
            icon: Icons.location_on_rounded,
          ),
          items: _buildings.map((building) {
            return DropdownMenuItem<String>(
              value: building,
              child: Text(building),
            );
          }).toList(),
          onChanged: _sending
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _building = value;
                    _floor.clear();
                  });
                },
        ),

        if (_needsFloor) ...[
          const SizedBox(height: 9),
          TextField(
            controller: _floor,
            enabled: !_sending,
            decoration: _decoration(
              'Floor (e.g. 2nd Floor)',
              icon: Icons.layers_outlined,
            ),
          ),
        ],

        const SizedBox(height: 9),

        TextField(
          controller: _room,
          enabled: !_sending,
          decoration: _decoration(
            'Room / Area (e.g. Lab 204)',
            icon: Icons.meeting_room_outlined,
          ),
        ),

        const SizedBox(height: 22),
        _heading('3. Describe the Incident'),

        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFDCE2EB),
            ),
          ),
          child: TextField(
            controller: _description,
            enabled: !_sending,
            minLines: 3,
            maxLines: 5,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type your message or use voice...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(
                12,
                13,
                12,
                0,
              ),
              counterStyle: const TextStyle(
                fontSize: 10,
              ),
              suffixIcon: IconButton(
                onPressed: _sending
                    ? null
                    : (_listening
                        ? _stopVoiceTyping
                        : _startVoiceTyping),
                tooltip: _listening
                    ? 'Stop voice input'
                    : 'Use voice input',
                icon: Icon(
                  _listening
                      ? Icons.stop_circle
                      : Icons.mic_rounded,
                  color: _dangerColor,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Image.file(
                  File(_selectedImage!.path),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: IconButton.filled(
                    onPressed: _sending
                        ? null
                        : () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: red,
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                    ),
                    tooltip: 'Remove photo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        OutlinedButton.icon(
          onPressed: _sending ? null : _pickImage,
          icon: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 19,
          ),
          label: Text(
            _selectedImage == null
                ? 'Add Photo (Optional)'
                : 'Choose Another Photo',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accentColor,
            minimumSize: const Size(double.infinity, 43),
            alignment: Alignment.centerLeft,
            side: BorderSide(
              color: _borderColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        if (_listening)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Listening… Speak clearly.',
              style: TextStyle(
                color: _dangerColor,
                fontSize: 12,
              ),
            ),
          ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
              color: _dangerColor,
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 47,
          child: ElevatedButton(
            onPressed: _sending ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationSummary() {
    final parts = <String>[_building];

    if (_needsFloor && _floor.text.trim().isNotEmpty) {
      parts.add(_floor.text.trim());
    }

    if (_room.text.trim().isNotEmpty) {
      parts.add(_room.text.trim());
    }

    return Text(
      parts.join(', '),
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    Widget content,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _textColor,
          size: 19,
        ),
        const SizedBox(width: 11),
        Expanded(child: content),
      ],
    );
  }

  Widget _confirmationView() {
    final category = _categories.firstWhere(
      (item) => item.name == _selectedType,
      orElse: () => _categories[0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(
          'Confirm Alert',
          () {
            setState(() {
              _confirmation = false;
              _error = null;
            });
          },
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 18,
          ),
          decoration: BoxDecoration(
            color: red.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: category.color,
                child: Icon(
                  category.icon,
                  color: _surface,
                  size: 29,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_selectedType Alert',
                style: TextStyle(
                  color: _dangerColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 17),

        _detailRow(
          Icons.location_on_rounded,
          _locationSummary(),
        ),

        const Divider(height: 23),

        _detailRow(
          Icons.calendar_today_outlined,
          const Text(
            'Date and time will be recorded when submitted.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),

        const Divider(height: 23),

        _detailRow(
          Icons.description_outlined,
          Text(
            _description.text.trim().isEmpty
                ? 'No additional description provided.'
                : _description.text.trim(),
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),

        if (_selectedImage != null) ...[
          const SizedBox(height: 15),
          Text(
            'Attached photo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_selectedImage!.path),
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ],

        const SizedBox(height: 17),

        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF382D1B) : const Color(0xFFFFF4DB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF8A5A00),
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Confirm the details before sending. '
                  'Do not put yourself in danger to collect evidence.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color: _dangerColor,
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 47,
          child: ElevatedButton(
            onPressed: _sending ? null : _confirmAndSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: _sending
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _surface,
                    ),
                  )
                : const Text(
                    'Confirm & Send',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 9),

        SizedBox(
          width: double.infinity,
          height: 43,
          child: OutlinedButton(
            onPressed: _sending
                ? null
                : () {
                    setState(() {
                      _confirmation = false;
                    });
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: _accentColor,
              side: BorderSide(
                color: _borderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  // Kept in the file for compatibility with the previous version.
  // Successful submissions now open AISafetyInsightsScreen instead.
  Widget _insightRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE1E6EF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _textColor, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Legacy success view. The current build method uses Screen 7.
  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(
          'AI Safety Insights',
          () => Navigator.pop(context),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1C2D46) : const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: _textColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your alert has been recorded. '
                  'Review the safety guidance below.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _insightRow(
          Icons.report_outlined,
          'Incident Type',
          _submittedType,
        ),

        _insightRow(
          Icons.priority_high_rounded,
          'Status',
          'Pending response team review',
        ),

        _insightRow(
          Icons.description_outlined,
          'Situation Summary',
          _submittedDescription.isEmpty
              ? 'No additional description provided.'
              : _submittedDescription,
        ),

        if (_photoUrl != null) ...[
          Text(
            'Uploaded evidence photo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _photoUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Text(
                  'Photo uploaded. Preview unavailable.',
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE1E6EF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    color: _textColor,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Recommended Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: GroqService.generateStudentGuide(
                  'Incident category: $_submittedType. '
                  'Description: $_submittedDescription. '
                  'Give brief, practical safety actions. '
                  'Do not invent incident details.',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Preparing safety guidance...',
                          ),
                        ),
                      ],
                    );
                  }

                  return Text(
                    snapshot.data ??
                        'Move to a safe location if possible. '
                        'Avoid further danger, and follow '
                        'instructions from authorized responders. '
                        'Contact local emergency services if there '
                        'is immediate danger.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 47,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Return to Home'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _floor.dispose();
    _room.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show Screen 7 only after Firestore confirms submission.
    if (_submitted) {
      return AISafetyInsightsScreen(
        incidentType: _submittedType,
        building: _building,
        floor: _needsFloor ? _floor.text.trim() : 'N/A',
        room: _room.text.trim(),
        description: _submittedDescription,
        photoUrl: _photoUrl,
      );
    }

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24,
              ),
              child: _confirmation
                  ? _confirmationView()
                  : _form(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const _Category(
    this.name,
    this.icon,
    this.color,
    this.description,
  );
}