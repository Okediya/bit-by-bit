import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ai_provider.dart';
import '../../providers/providers.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  AIProviderType _selectedType = AIProviderType.gemini;
  String _selectedModel = '';
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _updateModels();
  }

  void _updateModels() {
    final models = AIProvider.getDefaultModels(_selectedType);
    setState(() {
      _selectedModel = models.isNotEmpty ? models.first : '';
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Title
              Center(
                child: Column(
                  children: [
                    Text(
                      'Bit by Bit',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'Configure your AI provider',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              
              // Provider Selection
              const Text(
                'PROVIDER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final type in [AIProviderType.gemini, AIProviderType.groq, AIProviderType.openai, AIProviderType.claude])
                    _ProviderChip(
                      type: type,
                      isSelected: _selectedType == type,
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });
                        _updateModels();
                      },
                    ),
                ].animate(interval: 50.ms).fadeIn().slideX(begin: -0.1),
              ),
              const SizedBox(height: 32),
              
              // API Key Input
              const Text(
                'API KEY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your API key...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 8),
              Text(
                _getApiKeyHint(),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 32),
              
              // Model Selection
              const Text(
                'MODEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedModel.isNotEmpty ? _selectedModel : null,
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: AIProvider.getDefaultModels(_selectedType).map((model) {
                    return DropdownMenuItem(value: model, child: Text(model));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedModel = value);
                    }
                  },
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 48),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5),
                        )
                      : const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  String _getApiKeyHint() {
    switch (_selectedType) {
      case AIProviderType.gemini:
        return 'Get your key at aistudio.google.com';
      case AIProviderType.groq:
        return 'Get your key at console.groq.com';
      case AIProviderType.openai:
        return 'Get your key at platform.openai.com';
      case AIProviderType.claude:
        return 'Get your key at console.anthropic.com';
      default:
        return '';
    }
  }

  Future<void> _handleGetStarted() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your API key')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = AIProvider(
        id: const Uuid().v4(),
        name: _selectedType.displayName,
        type: _selectedType,
        apiKey: apiKey,
        baseUrl: AIProvider.getDefaultBaseUrl(_selectedType),
        model: _selectedModel,
        isActive: true,
      );

      final repo = ref.read(dataRepositoryProvider);
      await repo.saveProvider(provider);
      ref.invalidate(aiProvidersProvider);
      ref.invalidate(activeAIProviderProvider);

      if (mounted) {
        context.go('/chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _ProviderChip extends StatelessWidget {
  final AIProviderType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : AppTheme.darkBorder,
          ),
        ),
        child: Text(
          type.displayName,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
