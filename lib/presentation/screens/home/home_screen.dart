import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/languages.dart';
import '../../providers/language_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _swapTurns = 0.0;

  void _showLanguageSelector({
    required BuildContext context,
    required String title,
    required AppLanguage currentLanguage,
    required ValueChanged<AppLanguage> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = supportedLanguages[index];
                    final isSelected = language.code == currentLanguage.code;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        leading: Text(
                          language.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(
                          language.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          language.nativeName,
                          style: TextStyle(
                            color: isSelected 
                                ? theme.colorScheme.primary.withOpacity(0.8) 
                                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              )
                            : null,
                        onTap: () {
                          onSelected(language);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceLang = ref.watch(sourceLanguageProvider);
    final targetLang = ref.watch(targetLanguageProvider);
    final isValid = sourceLang.code != targetLang.code;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                : [const Color(0xFFEDF2F7), const Color(0xFFF7FAFC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Logo & Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BhashaBridge',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bridges voices, breaks boundaries',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                const Spacer(),

                // Source Language Card
                _buildLanguageCard(
                  context: context,
                  theme: theme,
                  label: 'I Speak',
                  language: sourceLang,
                  onTap: () {
                    _showLanguageSelector(
                      context: context,
                      title: 'Select Your Language',
                      currentLanguage: sourceLang,
                      onSelected: (lang) =>
                          ref.read(sourceLanguageProvider.notifier).state = lang,
                    );
                  },
                ),

                // Swap Button with Micro-Interaction Animation
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: _swapTurns,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutBack,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _swapTurns += 0.5;
                            });
                            final temp = sourceLang;
                            ref.read(sourceLanguageProvider.notifier).state = targetLang;
                            ref.read(targetLanguageProvider.notifier).state = temp;
                          },
                          icon: Icon(
                            Icons.swap_vert_rounded,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Target Language Card
                _buildLanguageCard(
                  context: context,
                  theme: theme,
                  label: 'They Speak',
                  language: targetLang,
                  onTap: () {
                    _showLanguageSelector(
                      context: context,
                      title: 'Select Their Language',
                      currentLanguage: targetLang,
                      onSelected: (lang) =>
                          ref.read(targetLanguageProvider.notifier).state = lang,
                    );
                  },
                ),

                if (!isValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Source and target must be different.',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(flex: 2),

                // Start button with beautiful gradient background
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: isValid
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          )
                        : null,
                    boxShadow: isValid
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isValid
                        ? () {
                            context.push('/conversation');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic_none_rounded, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Start Translate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required AppLanguage language,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface.withOpacity(0.85),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      language.flag,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          language.nativeName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
