import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation.dart';
import '../data/models/ai_provider.dart';
import '../data/repositories/data_repository.dart';

// Repository provider
final dataRepositoryProvider = Provider((ref) => DataRepository());

// ============== AI PROVIDERS ==============

final aiProvidersProvider = FutureProvider<List<AIProvider>>((ref) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getAllProviders();
});

final activeAIProviderProvider = FutureProvider<AIProvider?>((ref) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getActiveProvider();
});

// ============== CONVERSATIONS ==============

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getAllConversations();
});

final currentConversationIdProvider = StateProvider<String?>((ref) => null);

final currentConversationProvider = FutureProvider<Conversation?>((ref) async {
  final id = ref.watch(currentConversationIdProvider);
  if (id == null) return null;
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getConversationById(id);
});

// ============== MESSAGES ==============

final messagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getMessagesForConversation(conversationId);
});

// ============== NOTIFIERS ==============

class ConversationNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final DataRepository _repo;
  final Ref _ref;
  
  ConversationNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _loadConversations();
  }
  
  Future<void> _loadConversations() async {
    state = const AsyncValue.loading();
    try {
      final conversations = await _repo.getAllConversations();
      state = AsyncValue.data(conversations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<Conversation> createConversation({String? providerId}) async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      providerId: providerId,
    );
    await _repo.saveConversation(conversation);
    await _loadConversations();
    _ref.invalidate(conversationsProvider);
    return conversation;
  }

  /// Create a sub-conversation branching from highlighted text
  Future<Conversation> createSubConversation({
    required String parentConversationId,
    required String parentMessageId,
    required String highlightedText,
    String? providerId,
    String? title,
  }) async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'Sub-chat',
      providerId: providerId,
      parentConversationId: parentConversationId,
      parentMessageId: parentMessageId,
      highlightedText: highlightedText,
    );
    await _repo.saveConversation(conversation);
    await _loadConversations();
    _ref.invalidate(conversationsProvider);
    _ref.invalidate(subConversationsProvider(parentConversationId));
    return conversation;
  }
  
  Future<void> updateConversation(Conversation conversation) async {
    await _repo.saveConversation(conversation.copyWith(updatedAt: DateTime.now()));
    await _loadConversations();
    _ref.invalidate(conversationsProvider);
  }
  
  Future<void> deleteConversation(String id) async {
    await _repo.deleteConversation(id);
    await _loadConversations();
    _ref.invalidate(conversationsProvider);
  }
  
  Future<void> refresh() async {
    await _loadConversations();
  }
}

final conversationNotifierProvider = StateNotifierProvider<ConversationNotifier, AsyncValue<List<Conversation>>>((ref) {
  final repo = ref.watch(dataRepositoryProvider);
  return ConversationNotifier(repo, ref);
});

/// Provider for sub-conversations of a parent
final subConversationsProvider = FutureProvider.family<List<Conversation>, String>((ref, parentId) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getSubConversations(parentId);
});

/// Provider for root conversations only (no parent)
final rootConversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getRootConversations();
});

/// Provider for conversation hierarchy
final conversationHierarchyProvider = FutureProvider<Map<String, List<Conversation>>>((ref) async {
  final repo = ref.watch(dataRepositoryProvider);
  return repo.getConversationHierarchy();
});

class MessageNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final DataRepository _repo;
  final Ref _ref;
  final String conversationId;
  
  MessageNotifier(this._repo, this._ref, this.conversationId) : super(const AsyncValue.loading()) {
    _loadMessages();
  }
  
  Future<void> _loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repo.getMessagesForConversation(conversationId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addMessage(ChatMessage message) async {
    await _repo.saveMessage(message);
    await _loadMessages();
    _ref.invalidate(messagesProvider(conversationId));
  }
  
  Future<void> refresh() async {
    await _loadMessages();
  }
}

final messageNotifierProvider = StateNotifierProvider.family<MessageNotifier, AsyncValue<List<ChatMessage>>, String>((ref, conversationId) {
  final repo = ref.watch(dataRepositoryProvider);
  return MessageNotifier(repo, ref, conversationId);
});
