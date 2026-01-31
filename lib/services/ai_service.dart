import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../data/models/ai_provider.dart';

/// Abstract AI service interface
abstract class AIService {
  Future<String> complete(String prompt, {String? systemPrompt});
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt});
}

/// Helper for linear backoff retries
Future<http.Response> _postWithRetry(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  int retries = 3,
}) async {
  int attempts = 0;
  while (attempts < retries) {
    try {
      final response = await http.post(url, headers: headers, body: body);
      
      // If success or not a transient error (like 400 Bad Request), return
      if (response.statusCode != 429 && response.statusCode < 500) {
        return response;
      }
      
      // If it's a 429 or 5xx, we retry
      attempts++;
      if (attempts == retries) return response;
      
      // Exponential backoff: 1s, 2s, 4s...
      final delay = Duration(seconds: pow(2, attempts - 1).toInt());
      debugPrint('API Error ${response.statusCode}. Retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
    } catch (e) {
      attempts++;
      if (attempts == retries) rethrow;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  throw Exception('Failed after $retries retries');
}

/// Factory to create AI service based on provider type
class AIServiceFactory {
  static AIService create(AIProvider provider) {
    switch (provider.type) {
      case AIProviderType.openai:
        return OpenAIService(provider);
      case AIProviderType.gemini:
        return GeminiService(provider);
      case AIProviderType.claude:
        return ClaudeService(provider);
      case AIProviderType.groq:
        return GroqService(provider);
      case AIProviderType.xai:
        return XAIService(provider);
      case AIProviderType.ollama:
        return OllamaService(provider);
      case AIProviderType.custom:
        return OpenAIService(provider); // Custom uses OpenAI-compatible API
    }
  }
}

/// OpenAI API implementation
class OpenAIService implements AIService {
  final AIProvider provider;
  
  OpenAIService(this.provider);
  
  @override
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final baseUrl = provider.baseUrl ?? 'https://api.openai.com/v1';
    final response = await _postWithRetry(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode({
        'model': provider.model,
        'messages': [
          if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
  
  @override
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt}) async {
    // For now, return a single-element stream
    final result = await complete(prompt, systemPrompt: systemPrompt);
    return Stream.value(result);
  }
}

/// Google Gemini API implementation
class GeminiService implements AIService {
  final AIProvider provider;
  
  GeminiService(this.provider);
  
  @override
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final baseUrl = provider.baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';
    final fullPrompt = systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt;
    
    final response = await _postWithRetry(
      Uri.parse('$baseUrl/models/${provider.model}:generateContent?key=${provider.apiKey}'),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': provider.apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
        },
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  }
  
  @override
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt}) async {
    final result = await complete(prompt, systemPrompt: systemPrompt);
    return Stream.value(result);
  }
}

/// Anthropic Claude API implementation
class ClaudeService implements AIService {
  final AIProvider provider;
  
  ClaudeService(this.provider);
  
  @override
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final baseUrl = provider.baseUrl ?? 'https://api.anthropic.com/v1';
    
    final response = await _postWithRetry(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': provider.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': provider.model,
        'max_tokens': 4096,
        'system': systemPrompt ?? 'You are a helpful assistant.',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    return data['content'][0]['text'];
  }
  
  @override
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt}) async {
    final result = await complete(prompt, systemPrompt: systemPrompt);
    return Stream.value(result);
  }
}

/// Ollama (local) API implementation
class OllamaService implements AIService {
  final AIProvider provider;
  
  OllamaService(this.provider);
  
  @override
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final baseUrl = provider.baseUrl ?? 'http://localhost:11434';
    final fullPrompt = systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt;
    
    final response = await _postWithRetry(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': provider.model,
        'prompt': fullPrompt,
        'stream': false,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    return data['response'];
  }
  
  @override
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt}) async {
    final result = await complete(prompt, systemPrompt: systemPrompt);
    return Stream.value(result);
  }
}

/// Groq API implementation (OpenAI-compatible)
class GroqService implements AIService {
  final AIProvider provider;
  
  GroqService(this.provider);
  
  @override
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final baseUrl = provider.baseUrl ?? 'https://api.groq.com/openai/v1';
    final response = await _postWithRetry(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode({
        'model': provider.model,
        'messages': [
          if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
  
  @override
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt}) async {
    final result = await complete(prompt, systemPrompt: systemPrompt);
    return Stream.value(result);
  }
}

/// xAI (Grok) API implementation (OpenAI-compatible)
class XAIService implements AIService {
  final AIProvider provider;
  
  XAIService(this.provider);
  
  @override
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final baseUrl = provider.baseUrl ?? 'https://api.x.ai/v1';
    final response = await _postWithRetry(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode({
        'model': provider.model,
        'messages': [
          if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
  
  @override
  Future<Stream<String>> streamComplete(String prompt, {String? systemPrompt}) async {
    final result = await complete(prompt, systemPrompt: systemPrompt);
    return Stream.value(result);
  }
}
