/// AI Provider configuration for BYOK (Bring Your Own Key) model
class AIProvider {
  final String id;
  final String name;
  final AIProviderType type;
  final String apiKey;
  final String? baseUrl;
  final String model;
  final bool isActive;
  final DateTime createdAt;

  AIProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AIProvider copyWith({
    String? id,
    String? name,
    AIProviderType? type,
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AIProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': model,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AIProvider.fromJson(Map<String, dynamic> json) {
    return AIProvider(
      id: json['id'],
      name: json['name'],
      type: AIProviderType.values.firstWhere((e) => e.name == json['type']),
      apiKey: json['apiKey'],
      baseUrl: json['baseUrl'],
      model: json['model'],
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// Get default models for each provider type
  static List<String> getDefaultModels(AIProviderType type) {
    switch (type) {
      case AIProviderType.openai:
        return ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case AIProviderType.gemini:
        return ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.0-flash-lite', 'gemini-2.5-pro'];
      case AIProviderType.claude:
        return ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229', 'claude-3-haiku-20240307'];
      case AIProviderType.groq:
        return ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'mixtral-8x7b-32768', 'gemma2-9b-it'];
      case AIProviderType.xai:
        return ['grok-2-latest'];
      case AIProviderType.ollama:
        return ['llama3.2', 'llama3.1', 'mistral', 'codellama', 'mixtral'];
      case AIProviderType.custom:
        return [];
    }
  }

  /// Get default base URL for each provider type
  static String? getDefaultBaseUrl(AIProviderType type) {
    switch (type) {
      case AIProviderType.openai:
        return 'https://api.openai.com/v1';
      case AIProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AIProviderType.claude:
        return 'https://api.anthropic.com/v1';
      case AIProviderType.groq:
        return 'https://api.groq.com/openai/v1';
      case AIProviderType.xai:
        return 'https://api.x.ai/v1';
      case AIProviderType.ollama:
        return 'http://localhost:11434';
      case AIProviderType.custom:
        return null;
    }
  }
}

enum AIProviderType {
  openai,
  gemini,
  claude,
  groq,
  xai,
  ollama,
  custom,
}

extension AIProviderTypeExtension on AIProviderType {
  String get displayName {
    switch (this) {
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.gemini:
        return 'Google Gemini';
      case AIProviderType.claude:
        return 'Anthropic Claude';
      case AIProviderType.groq:
        return 'Groq';
      case AIProviderType.xai:
        return 'xAI (Grok)';
      case AIProviderType.ollama:
        return 'Ollama (Local)';
      case AIProviderType.custom:
        return 'Custom API';
    }
  }

  String get description {
    switch (this) {
      case AIProviderType.openai:
        return 'GPT-4, GPT-3.5 and other OpenAI models';
      case AIProviderType.gemini:
        return 'Google\'s Gemini models';
      case AIProviderType.claude:
        return 'Anthropic\'s Claude models';
      case AIProviderType.groq:
        return 'Fast inference with LLaMA & Mixtral';
      case AIProviderType.xai:
        return 'Grok models by xAI';
      case AIProviderType.ollama:
        return 'Run models locally with Ollama';
      case AIProviderType.custom:
        return 'Any OpenAI-compatible endpoint';
    }
  }
}
