import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/languages.dart';
import '../../providers/api_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/translation_notifier.dart';
import '../../providers/translation_state.dart';
import '../../../domain/entities/conversation_message.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _ipController.text = ref.read(apiBaseUrlProvider);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Server Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the backend server base URL. For real phones, use your PC local IP (e.g. http://192.168.1.50:8000).',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  border: OutlineInputBorder(),
                  hintText: 'http://10.0.2.2:8000',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String input = _ipController.text.trim();
                if (!input.startsWith("http://") && !input.startsWith("https://")) {
                  input = "http://$input";
                }
                ref.read(apiBaseUrlProvider.notifier).state = input;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server updated to: $input')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(conversationMessagesProvider);
    final activeSpeaker = ref.watch(activeSpeakerProvider);
    final direction = ref.watch(activeDirectionProvider);
    final translationState = ref.watch(translationNotifierProvider);

    // Auto-scroll on new message
    ref.listen<List<dynamic>>(conversationMessagesProvider, (prev, next) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'BhashaBridge',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${direction.source.flag} ${direction.source.name} ⇄ ${direction.target.name} ${direction.target.flag}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Server Settings',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text('Are you sure you want to clear the conversation history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(conversationMessagesProvider.notifier).clearHistory();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Message feed
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No translation history yet.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Press and hold the microphone at the bottom to speak.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(context, theme, message);
                    },
                  ),
          ),

          // Action/Recording Area
          _buildControlPanel(theme, translationState, activeSpeaker),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme, ConversationMessage message) {
    final isYou = message.speaker == 'You';
    final Alignment bubbleAlignment = isYou ? Alignment.centerRight : Alignment.centerLeft;

    final primaryColor = isYou ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer;
    final onPrimaryColor = isYou ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer;

    // Resolve flags
    final List<AppLanguage> matchingLangs = supportedLanguages;
    final sourceFlag = matchingLangs.firstWhere((l) => l.code == message.sourceLanguage, orElse: () => supportedLanguages.first).flag;
    final targetFlag = matchingLangs.firstWhere((l) => l.code == message.targetLanguage, orElse: () => supportedLanguages.first).flag;

    final formattedTime = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: bubbleAlignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isYou ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isYou ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.speaker,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onPrimaryColor.withOpacity(0.8),
                  ),
                ),
                Text(
                  formattedTime,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onPrimaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Source Speech Text
            Text(
              message.sourceText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.sourceLanguage.toUpperCase()} $sourceFlag',
              style: theme.textTheme.labelSmall?.copyWith(
                color: onPrimaryColor.withOpacity(0.5),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: onPrimaryColor.withOpacity(0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_downward_rounded, size: 16, color: onPrimaryColor.withOpacity(0.5)),
                  ),
                  Expanded(child: Divider(color: onPrimaryColor.withOpacity(0.2))),
                ],
              ),
            ),

            // Translated Speech Text
            Text(
              message.translatedText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.targetLanguage.toUpperCase()} $targetFlag',
              style: theme.textTheme.labelSmall?.copyWith(
                color: onPrimaryColor.withOpacity(0.5),
              ),
            ),

            if (message.audioPath != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(translationNotifierProvider.notifier).replayAudio(message.audioPath),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Play', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme, TranslationState state, Speaker activeSpeaker) {
    String statusText = 'Hold and speak';
    bool showSpinner = false;
    bool isRecording = false;

    // Handle states
    switch (state) {
      case TranslationInitial():
        statusText = 'Hold to speak';
        break;
      case TranslationRecording():
        statusText = '🎤 Listening... Speak now';
        isRecording = true;
        break;
      case TranslationUploading():
        statusText = '📤 Uploading audio...';
        showSpinner = true;
        break;
      case TranslationTranscribing():
        statusText = '📝 Converting speech to text...';
        showSpinner = true;
        break;
      case TranslationTranslating():
        statusText = '🌐 Translating...';
        showSpinner = true;
        break;
      case TranslationGeneratingSpeech():
        statusText = '🔊 Generating audio response...';
        showSpinner = true;
        break;
      case TranslationPlayingAudio():
        statusText = '🔊 Playing translation...';
        break;
      case TranslationSuccess():
        statusText = '✓ Translation complete';
        break;
      case TranslationError():
        statusText = 'Error occurred';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speaker selection toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Speaker:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<Speaker>(
                  segments: const [
                    ButtonSegment<Speaker>(
                      value: Speaker.you,
                      label: Text('You (A)'),
                      icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment<Speaker>(
                      value: Speaker.receiver,
                      label: Text('Receiver (B)'),
                      icon: Icon(Icons.person_pin_outlined),
                    ),
                  ],
                  selected: {activeSpeaker},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      ref.read(activeSpeakerProvider.notifier).state = set.first;
                      ref.read(translationNotifierProvider.notifier).reset();
                    }
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pipeline Progress / Error message
          if (state is TranslationError)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.message,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => ref.read(translationNotifierProvider.notifier).reset(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isRecording ? Colors.red : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Record action area
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated background ring for recording
                  if (isRecording)
                    _AnimatedPulseRing(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  if (showSpinner)
                    const SizedBox(
                      width: 86,
                      height: 86,
                      child: CircularProgressIndicator(strokeWidth: 4),
                    ),
                  GestureDetector(
                    onLongPressStart: (details) {
                      if (state is! TranslationUploading &&
                          state is! TranslationTranscribing &&
                          state is! TranslationTranslating &&
                          state is! TranslationGeneratingSpeech) {
                        ref.read(translationNotifierProvider.notifier).startRecording();
                      }
                    },
                    onLongPressEnd: (details) {
                      ref.read(translationNotifierProvider.notifier).stopAndTranslate();
                    },
                    child: FloatingActionButton(
                      onPressed: () {
                        // Standard click fallback message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Press and HOLD to record, release to translate.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      backgroundColor: isRecording ? Colors.red : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: Icon(
                        isRecording ? Icons.mic : Icons.mic_none,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isRecording && !showSpinner && state is! TranslationError)
            Text(
              'Hold button to speak',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedPulseRing extends StatefulWidget {
  final Color color;

  const _AnimatedPulseRing({required this.color});

  @override
  State<_AnimatedPulseRing> createState() => _AnimatedPulseRingState();
}

class _AnimatedPulseRingState extends State<_AnimatedPulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 86 + (30 * _controller.value),
          height: 86 + (30 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.3 * (1 - _controller.value)),
          ),
        );
      },
    );
  }
}
