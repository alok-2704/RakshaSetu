
import 'package:flutter/material.dart';
import '../widgets/raksha_mitra_logo.dart';
import '../groq_service.dart';

class AISafetyAssistantScreen extends StatefulWidget {
  const AISafetyAssistantScreen({super.key});

  @override
  State<AISafetyAssistantScreen> createState() =>
      _AISafetyAssistantScreenState();
}

class _AISafetyAssistantScreenState
    extends State<AISafetyAssistantScreen> {
  static const Color navy = Color(0xFF173B70);
  static const Color purple = Color(0xFF6554C0);
  static const Color page = Color(0xFFF7F8FA);
  static const Color borderColor = Color(0xFFE3E8EF);
  static const Color textColor = Color(0xFF243247);
  static const Color mutedColor = Color(0xFF64748B);

  final TextEditingController _inputController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: 'assistant',
      text:
          'Hi! I’m Raksha Mitra, your campus safety companion. '
          'Ask me about emergency precautions, basic first-aid steps, '
          'evacuation, campus safety, or what to do in a difficult situation.',
    ),
  ];

  bool _sending = false;

  String? _lastFailedQuestion;

  static const List<_QuickPrompt> _quickPrompts = [
    _QuickPrompt(
      title: 'Fire emergency',
      subtitle: 'What to do if a fire breaks out',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFD92D35),
      question:
          'What should I do if there is a fire in a campus lab?',
    ),
    _QuickPrompt(
      title: 'Medical emergency',
      subtitle: 'Immediate steps for an injury',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF16805D),
      question:
          'What should I do if someone has a serious injury on campus?',
    ),
    _QuickPrompt(
      title: 'Personal safety',
      subtitle: 'Handle an unsafe situation',
      icon: Icons.shield_rounded,
      color: Color(0xFF6554C0),
      question:
          'How should I react if I feel unsafe around someone on campus?',
    ),
    _QuickPrompt(
      title: 'Evacuation',
      subtitle: 'Leave a building safely',
      icon: Icons.exit_to_app_rounded,
      color: Color(0xFF1769AA),
      question:
          'What are the important steps to evacuate a campus building safely?',
    ),
  ];

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? suggestedQuestion]) async {
    if (_sending) return;

    final question =
        (suggestedQuestion ?? _inputController.text).trim();

    if (question.isEmpty) return;

    // Keep only real conversation messages as AI context.
    // Error messages are not sent to the AI.
    final history = _messages
        .where(
          (message) =>
              !message.isError &&
              (message.role == 'user' ||
                  message.role == 'assistant'),
        )
        .map(
          (message) => {
            "role": message.role,
            "content": message.text,
          },
        )
        .toList();

    // The initial welcome message is not conversation context.
    if (history.isNotEmpty &&
        history.first['role'] == 'assistant') {
      history.removeAt(0);
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          role: 'user',
          text: question,
        ),
      );

      _sending = true;
      _lastFailedQuestion = null;
      _inputController.clear();
    });

    _scrollToLatest();

    try {
      final answer = await GroqService.askSafetyQuestion(
        question,
        history: history,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text: answer,
          ),
        );

        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _lastFailedQuestion = question;

        _messages.add(
          const _ChatMessage(
            role: 'assistant',
            isError: true,
            text:
                'I couldn’t connect to the AI service. '
                'Your question was not answered by AI. '
                'Please check your internet connection and try again.',
          ),
        );

        _sending = false;
      });
    }

    _scrollToLatest();
  }

  Future<void> _retryLastMessage() async {
    final question = _lastFailedQuestion;

    if (question == null || _sending) return;

    // Remove the error bubble before retrying.
    setState(() {
      if (_messages.isNotEmpty &&
          _messages.last.isError) {
        _messages.removeLast();
      }

      _lastFailedQuestion = null;
    });

    await _sendMessage(question);
  }

  Widget _messageBubble(_ChatMessage message) {
    final isUser = message.role == 'user';
    final isError = message.isError;

    final bubbleColor = isUser
        ? navy
        : isError
            ? const Color(0xFFFFF1F0)
            : Colors.white;

    final foregroundColor = isUser
        ? Colors.white
        : isError
            ? const Color(0xFF9B2525)
            : textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 330,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17),
                  topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(
                    isUser ? 17 : 5,
                  ),
                  bottomRight: Radius.circular(
                    isUser ? 5 : 17,
                  ),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isError
                            ? const Color(0xFFF3C4C0)
                            : borderColor,
                      ),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isError) ...[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: Color(0xFFD92D35),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  isUser
                      ? 'You'
                      : isError
                          ? 'Connection issue'
                          : 'Raksha Mitra',
                  style: TextStyle(
                    fontSize: 10,
                    color: isError
                        ? const Color(0xFFD92D35)
                        : mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (isError && _lastFailedQuestion != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 4,
              ),
              child: OutlinedButton.icon(
                onPressed: _sending
                    ? null
                    : _retryLastMessage,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 17,
                ),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: const BorderSide(
                    color: borderColor,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickPromptCard(_QuickPrompt prompt) {
    return InkWell(
      onTap: _sending
          ? null
          : () => _sendMessage(prompt.question),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: prompt.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                prompt.icon,
                color: prompt.color,
                size: 19,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              prompt.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              prompt.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.35,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Choose a topic or type your question below.',
            style: TextStyle(
              fontSize: 11,
              color: mutedColor,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 9),
              itemBuilder: (context, index) {
                return _quickPromptCard(
                  _quickPrompts[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const RakshaMitraLogo(
            size: 30,
            backgroundColor: Color(0xFFEDE9FE),
            shieldColor: Color(0xFF173B70),
          ),

          const SizedBox(width: 9),

          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: purple,
            ),
          ),

          const SizedBox(width: 9),

          const Text(
            'Raksha Mitra is responding…',
            style: TextStyle(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        titleSpacing: 4,

        title: const Row(
          children: [
            RakshaMitraLogo(
              size: 48,
              backgroundColor: Color(0xFFEDE9FE),
              shieldColor: Color(0xFF173B70),
            ),

            SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raksha Mitra',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  Text(
                    'Your Campus Safety Companion',
                    style: TextStyle(
                      fontSize: 11,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  14,
                  12,
                  14,
                  12,
                ),
                itemCount:
                    _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return _typingIndicator();
                  }

                  return _messageBubble(
                    _messages[index],
                  );
                },
              ),
            ),

            // Quick prompts only appear before the conversation begins.
            if (_messages.length == 1 && !_sending)
              _buildQuickPrompts(),

            // Message composer
            Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                  ),
                ),
              ),

              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          enabled: !_sending,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization:
                              TextCapitalization.sentences,
                          textInputAction:
                              TextInputAction.send,
                          onSubmitted: (_) =>
                              _sendMessage(),
                          decoration: InputDecoration(
                            hintText:
                                'Ask about safety or guidance…',
                            hintStyle: const TextStyle(
                              color: mutedColor,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFFF5F7FA),
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        height: 48,
                        width: 48,
                        child: IconButton.filled(
                          onPressed: _sending
                              ? null
                              : () => _sendMessage(),
                          style: IconButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                navy.withValues(alpha: 0.4),
                          ),
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 20,
                          ),
                          tooltip: 'Send question',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Emergency reminder
                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: mutedColor,
                      ),

                      SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          'For immediate danger in India, call 112. '
                          'Do not wait for an AI response.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.4,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final bool isError;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.isError = false,
  });
}

class _QuickPrompt {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String question;

  const _QuickPrompt({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.question,
  });
}
