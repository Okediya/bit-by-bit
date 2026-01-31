// Conversation and ChatMessage models for AI chat

/// Represents a text highlight linking to a sub-conversation
class TextHighlight {
  final String id;
  final String messageId;         // The message containing this highlight
  final String conversationId;    // The sub-conversation this highlight links to
  final int startOffset;          // Start position in text
  final int endOffset;            // End position in text
  final String highlightedText;   // The actual highlighted text

  TextHighlight({
    required this.id,
    required this.messageId,
    required this.conversationId,
    required this.startOffset,
    required this.endOffset,
    required this.highlightedText,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'conversationId': conversationId,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'highlightedText': highlightedText,
    };
  }

  factory TextHighlight.fromJson(Map<String, dynamic> json) {
    return TextHighlight(
      id: json['id'],
      messageId: json['messageId'],
      conversationId: json['conversationId'],
      startOffset: json['startOffset'],
      endOffset: json['endOffset'],
      highlightedText: json['highlightedText'],
    );
  }
}

class Conversation {
  final String id;
  final String title;
  final String? providerId;
  final String? parentConversationId; // Link to parent conversation for branching
  final String? parentMessageId;      // Which message this branches from
  final String? highlightedText;      // The text that was highlighted to create this branch
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    this.providerId,
    this.parentConversationId,
    this.parentMessageId,
    this.highlightedText,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if this is a sub-conversation (has a parent)
  bool get isSubConversation => parentConversationId != null;

  Conversation copyWith({
    String? id,
    String? title,
    String? providerId,
    String? parentConversationId,
    String? parentMessageId,
    String? highlightedText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      providerId: providerId ?? this.providerId,
      parentConversationId: parentConversationId ?? this.parentConversationId,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      highlightedText: highlightedText ?? this.highlightedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'providerId': providerId,
      'parentConversationId': parentConversationId,
      'parentMessageId': parentMessageId,
      'highlightedText': highlightedText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      providerId: json['providerId'],
      parentConversationId: json['parentConversationId'],
      parentMessageId: json['parentMessageId'],
      highlightedText: json['highlightedText'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<TextHighlight> highlights; // Highlights linking to sub-conversations

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    DateTime? timestamp,
    List<TextHighlight>? highlights,
  }) : timestamp = timestamp ?? DateTime.now(),
       highlights = highlights ?? [];

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    List<TextHighlight>? highlights,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      highlights: highlights ?? this.highlights,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'highlights': highlights.map((h) => h.toJson()).toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversationId'],
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      highlights: (json['highlights'] as List<dynamic>?)
          ?.map((h) => TextHighlight.fromJson(h))
          .toList() ?? [],
    );
  }
}
