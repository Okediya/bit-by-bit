import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/conversation.dart';
import '../models/ai_provider.dart';

/// Repository for managing all data persistence
class DataRepository {
  static const _storage = FlutterSecureStorage();
  static const _conversationsKey = 'conversations';
  static const _messagesKey = 'messages';
  static const _providersKey = 'ai_providers';

  // ============== CONVERSATIONS ==============
  
  Future<List<Conversation>> getAllConversations() async {
    final data = await _storage.read(key: _conversationsKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    final conversations = jsonList.map((json) => Conversation.fromJson(json)).toList();
    // Sort by most recent first
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  Future<Conversation?> getConversationById(String id) async {
    final conversations = await getAllConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConversation(Conversation conversation) async {
    final conversations = await getAllConversations();
    final index = conversations.indexWhere((c) => c.id == conversation.id);
    
    if (index >= 0) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }
    
    await _storage.write(
      key: _conversationsKey,
      value: jsonEncode(conversations.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> deleteConversation(String id) async {
    final conversations = await getAllConversations();
    
    // Also delete all sub-conversations recursively
    Future<void> deleteWithChildren(String convId) async {
      final children = conversations.where((c) => c.parentConversationId == convId).toList();
      for (final child in children) {
        await deleteWithChildren(child.id);
      }
      conversations.removeWhere((c) => c.id == convId);
    }
    
    await deleteWithChildren(id);
    
    await _storage.write(
      key: _conversationsKey,
      value: jsonEncode(conversations.map((c) => c.toJson()).toList()),
    );
    
    // Also delete all messages for this conversation and its children
    final messages = await getAllMessages();
    final deletedIds = <String>{id};
    // Collect all deleted conversation IDs
    for (final conv in conversations) {
      if (!conversations.any((c) => c.id == conv.id)) {
        deletedIds.add(conv.id);
      }
    }
    messages.removeWhere((m) => deletedIds.contains(m.conversationId));
    await _storage.write(
      key: _messagesKey,
      value: jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  /// Get all sub-conversations for a parent conversation
  Future<List<Conversation>> getSubConversations(String parentId) async {
    final conversations = await getAllConversations();
    return conversations.where((c) => c.parentConversationId == parentId).toList();
  }

  /// Get only root conversations (no parent)
  Future<List<Conversation>> getRootConversations() async {
    final conversations = await getAllConversations();
    return conversations.where((c) => c.parentConversationId == null).toList();
  }

  /// Get conversation hierarchy (tree structure)
  Future<Map<String, List<Conversation>>> getConversationHierarchy() async {
    final conversations = await getAllConversations();
    final hierarchy = <String, List<Conversation>>{};
    
    // Root level (no parent)
    hierarchy['root'] = conversations.where((c) => c.parentConversationId == null).toList();
    
    // Group children by parent
    for (final conv in conversations) {
      if (conv.parentConversationId != null) {
        hierarchy.putIfAbsent(conv.parentConversationId!, () => []);
        hierarchy[conv.parentConversationId!]!.add(conv);
      }
    }
    
    return hierarchy;
  }

  /// Get message by ID
  Future<ChatMessage?> getMessageById(String id) async {
    final messages = await getAllMessages();
    try {
      return messages.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a highlight to a message
  Future<void> addHighlightToMessage(String messageId, TextHighlight highlight) async {
    final messages = await getAllMessages();
    final index = messages.indexWhere((m) => m.id == messageId);
    
    if (index >= 0) {
      final message = messages[index];
      final updatedHighlights = [...message.highlights, highlight];
      messages[index] = message.copyWith(highlights: updatedHighlights);
      
      await _storage.write(
        key: _messagesKey,
        value: jsonEncode(messages.map((m) => m.toJson()).toList()),
      );
    }
  }

  /// Get all highlights for a message
  Future<List<TextHighlight>> getHighlightsForMessage(String messageId) async {
    final message = await getMessageById(messageId);
    return message?.highlights ?? [];
  }

  // ============== MESSAGES ==============
  
  Future<List<ChatMessage>> getAllMessages() async {
    final data = await _storage.read(key: _messagesKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<List<ChatMessage>> getMessagesForConversation(String conversationId) async {
    final messages = await getAllMessages();
    final conversationMessages = messages.where((m) => m.conversationId == conversationId).toList();
    // Sort by timestamp
    conversationMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return conversationMessages;
  }

  Future<void> saveMessage(ChatMessage message) async {
    final messages = await getAllMessages();
    final index = messages.indexWhere((m) => m.id == message.id);
    
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    
    await _storage.write(
      key: _messagesKey,
      value: jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> deleteMessage(String id) async {
    final messages = await getAllMessages();
    messages.removeWhere((m) => m.id == id);
    
    await _storage.write(
      key: _messagesKey,
      value: jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  // ============== AI PROVIDERS ==============
  
  Future<List<AIProvider>> getAllProviders() async {
    final data = await _storage.read(key: _providersKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => AIProvider.fromJson(json)).toList();
  }

  Future<AIProvider?> getActiveProvider() async {
    final providers = await getAllProviders();
    try {
      return providers.firstWhere((p) => p.isActive);
    } catch (_) {
      return providers.isNotEmpty ? providers.first : null;
    }
  }

  Future<void> saveProvider(AIProvider provider) async {
    final providers = await getAllProviders();
    final index = providers.indexWhere((p) => p.id == provider.id);
    
    // If this provider is being set as active, deactivate others
    if (provider.isActive) {
      for (int i = 0; i < providers.length; i++) {
        if (providers[i].id != provider.id && providers[i].isActive) {
          providers[i] = providers[i].copyWith(isActive: false);
        }
      }
    }
    
    if (index >= 0) {
      providers[index] = provider;
    } else {
      providers.add(provider);
    }
    
    await _storage.write(
      key: _providersKey,
      value: jsonEncode(providers.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> deleteProvider(String id) async {
    final providers = await getAllProviders();
    providers.removeWhere((p) => p.id == id);
    
    await _storage.write(
      key: _providersKey,
      value: jsonEncode(providers.map((p) => p.toJson()).toList()),
    );
  }
}
