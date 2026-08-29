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
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.dns_rounded),
              SizedBox(width: 12),
              Text('Server Configuration'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the backend base URL (e.g. your Cloudflare Tunnel address or PC local IP).',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  hintText: 'https://structures-common-arrow-plasma.trycloudflare.com',
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
                if (input.isNotEmpty && !input.startsWith("http://") && !input.startsWith("https://")) {
                  input = "http://$input";
                }
                ref.read(apiBaseUrlProvider.notifier).state = input;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Text('Server updated to: $input'),
                  ),
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
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(direction.source.flag, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${direction.source.name} ⇄ ${direction.target.name}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(direction.target.flag, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
                  content: const Text('Are you sure you want to clear this conversation history?'),
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
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.forum_outlined,
                              size: 54,
                              color: theme.colorScheme.primary.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No translation history yet.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Press and hold the microphone at the bottom to translate your voice.',
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

          // Control and recording panel
          _buildControlPanel(theme, translationState, activeSpeaker),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme, ConversationMessage message) {
    final isYou = message.speaker == 'You';
    final Alignment bubbleAlignment = isYou ? Alignment.centerRight : Alignment.centerLeft;

    final formattedTime = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    final isDark = theme.brightness == Brightness.dark;

    // Use nice gradient for user speech bubble, and surface card for receiver
    final decoration = BoxDecoration(
      gradient: isYou
          ? LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: isYou ? null : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: isYou ? const Radius.circular(20) : const Radius.circular(4),
        bottomRight: isYou ? const Radius.circular(4) : const Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final textColor = isYou ? Colors.white : theme.colorScheme.onSurface;
    final subtitleColor = isYou ? Colors.white.withOpacity(0.6) : theme.colorScheme.onSurfaceVariant.withOpacity(0.7);

    // Find flags
    final sourceFlag = supportedLanguages.firstWhere((l) => l.code == message.sourceLanguage, orElse: () => supportedLanguages.first).flag;
    final targetFlag = supportedLanguages.firstWhere((l) => l.code == message.targetLanguage, orElse: () => supportedLanguages.first).flag;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: bubbleAlignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: decoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker Name & Flag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.speaker == 'You' ? 'You (A)' : 'Receiver (B)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
                Text(
                  formattedTime,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Original Speech text
            Text(
              message.sourceText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${message.sourceLanguage.toUpperCase()} $sourceFlag',
              style: theme.textTheme.labelSmall?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Soft Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                height: 1,
                color: textColor.withOpacity(0.12),
              ),
            ),

            // Translated text + volume trigger
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.translatedText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${message.targetLanguage.toUpperCase()} $targetFlag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: subtitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (message.audioPath != null && message.audioPath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.volume_up_rounded, size: 20, color: textColor),
                        onPressed: () => ref.read(translationNotifierProvider.notifier).replayAudio(message.audioPath!),
                        tooltip: 'Speak translation',
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme, TranslationState state, Speaker activeSpeaker) {
    String statusText = 'Hold and speak';
    bool showSpinner = false;
    bool isRecording = false;
    bool isProcessing = false;

    switch (state) {
      case TranslationInitial():
        statusText = 'Hold mic to speak';
        break;
      case TranslationRecording():
        statusText = 'Listening...';
        isRecording = true;
        break;
      case TranslationUploading():
        statusText = 'Uploading voice...';
        showSpinner = true;
        isProcessing = true;
        break;
      case TranslationTranscribing():
        statusText = 'Converting voice...';
        showSpinner = true;
        isProcessing = true;
        break;
      case TranslationTranslating():
        statusText = 'Translating...';
        showSpinner = true;
        isProcessing = true;
        break;
      case TranslationGeneratingSpeech():
        statusText = 'Generating audio...';
        showSpinner = true;
        isProcessing = true;
        break;
      case TranslationPlayingAudio():
        statusText = 'Speaking translation...';
        break;
      case TranslationSuccess():
        statusText = 'Translated!';
        break;
      case TranslationError():
        statusText = 'Translation error';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speaker toggles
          Row(
            children: [
              Text(
                'Speaker:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<Speaker>(
                  segments: const [
                    ButtonSegment<Speaker>(
                      value: Speaker.you,
                      label: Text('You (A)'),
                      icon: Icon(Icons.person_outline_rounded, size: 18),
                    ),
                    ButtonSegment<Speaker>(
                      value: Speaker.receiver,
                      label: Text('Receiver (B)'),
                      icon: Icon(Icons.person_pin_outlined, size: 18),
                    ),
                  ],
                  selected: {activeSpeaker},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      ref.read(activeSpeakerProvider.notifier).state = set.first;
                      ref.read(translationNotifierProvider.notifier).reset();
                    }
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: theme.colorScheme.primaryContainer,
                    selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Waveform Equalizer when active
          if (isRecording)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _VoiceWaveform(color: Colors.red),
            )
          else if (state is TranslationPlayingAudio)
             Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VoiceWaveform(color: theme.colorScheme.secondary),
            )
          else
            const SizedBox(height: 2),

          // Status & spinner indicator
          if (state is TranslationError)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.message,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer, 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => ref.read(translationNotifierProvider.notifier).reset(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              statusText.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: isRecording 
                    ? Colors.red 
                    : (isProcessing ? theme.colorScheme.secondary : theme.colorScheme.primary),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Record Floating button with pulse ring
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isRecording)
                    const _AnimatedPulseRing(color: Colors.red),
                  if (showSpinner)
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      if (!isProcessing && !isRecording) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            content: const Text('Press and HOLD to record, release to translate.'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    onLongPressStart: (details) {
                      if (!isProcessing) {
                        ref.read(translationNotifierProvider.notifier).startRecording();
                      }
                    },
                    onLongPressEnd: (details) {
                      ref.read(translationNotifierProvider.notifier).stopAndTranslate();
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording 
                            ? Colors.red 
                            : (isProcessing ? theme.colorScheme.surfaceVariant : theme.colorScheme.primary),
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? Colors.red : theme.colorScheme.primary).withOpacity(0.3),
                            blurRadius: isRecording ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size: 36,
                        color: isRecording 
                            ? Colors.white 
                            : (isProcessing ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5) : Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isRecording && !showSpinner && state is! TranslationError)
            Text(
              'Hold button to talk',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}

// Bouncing equalizer voice waves
class _VoiceWaveform extends StatefulWidget {
  final Color color;
  const _VoiceWaveform({required this.color});

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(8, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = (_controller.value + (index * 0.12)) % 1.0;
              final height = 6 + (18 * (value - 0.5).abs() * 2);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 3.5,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// Glowing rings indicator
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
      duration: const Duration(milliseconds: 1200),
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
          width: 96 + (40 * _controller.value),
          height: 96 + (40 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.25 * (1 - _controller.value)),
            border: Border.all(
              color: widget.color.withOpacity(0.15 * (1 - _controller.value)),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}
