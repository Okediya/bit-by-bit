import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/conversation.dart';

import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../../widgets/conversation_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentConversationId;
  List<ChatMessage> _messages = [];
  Conversation? _currentConversation;

  @override
  void initState() {
    super.initState();
    _initOrLoadConversation();
  }

  Future<void> _initOrLoadConversation() async {
    final conversations = await ref.read(conversationsProvider.future);
    if (conversations.isNotEmpty) {
      setState(() {
        _currentConversationId = conversations.first.id;
      });
      _loadConversation();
    }
  }

  Future<void> _loadConversation() async {
    if (_currentConversationId == null) return;
    final conversation = await ref.read(dataRepositoryProvider).getConversationById(_currentConversationId!);
    final messages = await ref.read(dataRepositoryProvider).getMessagesForConversation(_currentConversationId!);
    setState(() {
      _currentConversation = conversation;
      _messages = messages;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(activeAIProviderProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show breadcrumb if this is a sub-conversation
            if (_currentConversation?.isSubConversation == true)
              GestureDetector(
                onTap: () => _navigateToParent(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        'Back to parent',
                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            providerAsync.when(
              loading: () => const Text('Loading...', style: TextStyle(fontSize: 14, color: Colors.white54)),
              error: (_, __) => const Text('Error', style: TextStyle(fontSize: 14, color: Colors.white54)),
              data: (provider) => Text(
                provider?.model ?? 'No Model',
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createNewConversation,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      drawer: ConversationDrawer(
        currentConversationId: _currentConversationId,
        onConversationSelected: (id) {
          setState(() => _currentConversationId = id);
          _loadConversation();
          Navigator.pop(context);
        },
        onNewConversation: () {
          _createNewConversation();
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          // Show highlighted text context if this is a sub-conversation
          if (_currentConversation?.highlightedText != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONTEXT',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentConversation!.highlightedText!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _SelectableMessageBubble(
                        message: message,
                        onAskAboutText: (selectedText, startOffset, endOffset) {
                          _showAskAboutDialog(message, selectedText, startOffset, endOffset);
                        },
                        onHighlightTap: (highlight) {
                          _navigateToSubConversation(highlight.conversationId);
                        },
                        key: ValueKey(message.id),
                      ).animate().fadeIn(duration: 200.ms);
                    },
                  ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white54,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Thinking...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkBg,
              border: Border(top: BorderSide(color: AppTheme.darkBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: Icon(
                        Icons.arrow_upward,
                        color: _isLoading ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSubConversation = _currentConversation?.isSubConversation == true;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isSubConversation ? 'Ask about the highlighted text' : 'Start a conversation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSubConversation 
                ? 'Your question will focus on the selected context'
                : 'Send a message to get started',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _navigateToParent() async {
    if (_currentConversation?.parentConversationId != null) {
      setState(() {
        _currentConversationId = _currentConversation!.parentConversationId;
      });
      await _loadConversation();
    }
  }

  void _navigateToSubConversation(String conversationId) async {
    setState(() {
      _currentConversationId = conversationId;
    });
    await _loadConversation();
  }

  void _showAskAboutDialog(ChatMessage message, String selectedText, int startOffset, int endOffset) {
    final questionController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASK ABOUT SELECTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Text(
                selectedText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: questionController,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What would you like to know?',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final question = questionController.text.trim();
                  if (question.isEmpty) return;
                  
                  Navigator.pop(context);
                  await _createSubConversation(
                    message: message,
                    selectedText: selectedText,
                    question: question,
                    startOffset: startOffset,
                    endOffset: endOffset,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create Branch',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _createSubConversation({
    required ChatMessage message,
    required String selectedText,
    required String question,
    required int startOffset,
    required int endOffset,
  }) async {
    final provider = await ref.read(activeAIProviderProvider.future);
    if (provider == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No AI provider configured')),
        );
      }
      return;
    }

    // Create sub-conversation
    final notifier = ref.read(conversationNotifierProvider.notifier);
    final subConversation = await notifier.createSubConversation(
      parentConversationId: _currentConversationId!,
      parentMessageId: message.id,
      highlightedText: selectedText,
      providerId: provider.id,
    );

    // Add highlight to the parent message
    final highlight = TextHighlight(
      id: const Uuid().v4(),
      messageId: message.id,
      conversationId: subConversation.id,
      startOffset: startOffset,
      endOffset: endOffset,
      highlightedText: selectedText,
    );
    await ref.read(dataRepositoryProvider).addHighlightToMessage(message.id, highlight);

    // Switch to sub-conversation
    setState(() {
      _currentConversationId = subConversation.id;
      _currentConversation = subConversation;
      _messages = [];
    });

    // Send the question in the sub-conversation
    _messageController.text = question;
    await _sendMessage();

    // Generate title for sub-conversation
    _generateSubConversationTitle(selectedText, question);
  }

  Future<void> _generateSubConversationTitle(String selectedText, String question) async {
    try {
      final provider = await ref.read(activeAIProviderProvider.future);
      if (provider == null) return;

      final aiService = AIServiceFactory.create(provider);
      final title = await aiService.complete(
        'Generate a very short title (3-5 words max) for a sub-conversation about this:\nContext: "$selectedText"\nQuestion: "$question"\n\nTitle:',
        systemPrompt: 'You generate very short conversation titles. Reply with only the title, no quotes or extra text.',
      );

      final conversation = await ref.read(dataRepositoryProvider).getConversationById(_currentConversationId!);
      if (conversation != null) {
        await ref.read(dataRepositoryProvider).saveConversation(
          conversation.copyWith(title: title.trim()),
        );
        ref.invalidate(conversationsProvider);
        await _loadConversation();
      }
    } catch (_) {
      // Silently fail - title generation is not critical
    }
  }

  Future<void> _createNewConversation() async {
    final notifier = ref.read(conversationNotifierProvider.notifier);
    final provider = await ref.read(activeAIProviderProvider.future);
    final conversation = await notifier.createConversation(providerId: provider?.id);
    setState(() {
      _currentConversationId = conversation.id;
      _currentConversation = conversation;
      _messages = [];
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final provider = await ref.read(activeAIProviderProvider.future);
    if (!mounted) return;
    
    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI provider configured')),
      );
      return;
    }

    // Create conversation if needed
    if (_currentConversationId == null) {
      await _createNewConversation();
    }

    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      conversationId: _currentConversationId!,
      role: MessageRole.user,
      content: text,
    );

    await ref.read(dataRepositoryProvider).saveMessage(userMessage);
    setState(() {
      _messages = [..._messages, userMessage];
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Get AI response
      final aiService = AIServiceFactory.create(provider);
      
      // Build prompt - for sub-conversations, include only highlighted text as context
      String prompt;
      if (_currentConversation?.highlightedText != null && _messages.length <= 2) {
        // First message in sub-conversation - include highlighted context
        prompt = 'Context: "${_currentConversation!.highlightedText}"\n\nQuestion: $text';
      } else {
        // Normal conversation or follow-up in sub-conversation
        final conversationHistory = _messages.map((m) => 
          '${m.role == MessageRole.user ? 'User' : 'Assistant'}: ${m.content}'
        ).join('\n\n');
        prompt = '$conversationHistory\n\nUser: $text';
      }
      
      final response = await aiService.complete(
        prompt,
        systemPrompt: 'You are a helpful AI assistant. Respond naturally and helpfully.',
      );

      // Add assistant message
      final assistantMessage = ChatMessage(
        id: const Uuid().v4(),
        conversationId: _currentConversationId!,
        role: MessageRole.assistant,
        content: response,
      );

      await ref.read(dataRepositoryProvider).saveMessage(assistantMessage);
      setState(() {
        _messages = [..._messages, assistantMessage];
      });
      _scrollToBottom();

      // Auto-generate title after first exchange (only for root conversations)
      if (_messages.length == 2 && mounted && _currentConversation?.isSubConversation != true) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _generateTitle(text, response);
        });
      }

      // Update conversation timestamp
      final conversation = await ref.read(dataRepositoryProvider).getConversationById(_currentConversationId!);
      if (conversation != null) {
        await ref.read(dataRepositoryProvider).saveConversation(
          conversation.copyWith(updatedAt: DateTime.now()),
        );
        ref.invalidate(conversationsProvider);
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
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

  Future<void> _generateTitle(String userMessage, String aiResponse) async {
    try {
      final provider = await ref.read(activeAIProviderProvider.future);
      if (provider == null) return;

      final aiService = AIServiceFactory.create(provider);
      final title = await aiService.complete(
        'Generate a very short title (3-5 words max) for this conversation:\nUser: $userMessage\nAssistant: $aiResponse\n\nTitle:',
        systemPrompt: 'You generate very short conversation titles. Reply with only the title, no quotes or extra text.',
      );

      final conversation = await ref.read(dataRepositoryProvider).getConversationById(_currentConversationId!);
      if (conversation != null) {
        await ref.read(dataRepositoryProvider).saveConversation(
          conversation.copyWith(title: title.trim()),
        );
        ref.invalidate(conversationsProvider);
      }
    } catch (_) {
      // Silently fail - title generation is not critical
    }
  }
}

/// Message bubble with selectable text and highlight support
class _SelectableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(String selectedText, int startOffset, int endOffset) onAskAboutText;
  final Function(TextHighlight highlight) onHighlightTap;

  const _SelectableMessageBubble({
    super.key,
    required this.message,
    required this.onAskAboutText,
    required this.onHighlightTap,
  });

  @override
  State<_SelectableMessageBubble> createState() => _SelectableMessageBubbleState();
}

class _SelectableMessageBubbleState extends State<_SelectableMessageBubble> {
  String? _selectedText;
  int _selectionStart = 0;
  int _selectionEnd = 0;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: const Center(
                    child: Text('AI', style: TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.black : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser 
                        ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5)
                        : Border.all(color: AppTheme.darkBorder),
                    boxShadow: isUser 
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            )
                          ]
                        : null,
                  ),
                  child: isUser
                      ? Text(
                          widget.message.content,
                          style: const TextStyle(color: Colors.white),
                        )
                      : _buildSelectableContent(),
                ),
              ),
              if (isUser) const SizedBox(width: 10),
            ],
          ),
          
          // Show existing highlights as clickable chips
          if (widget.message.highlights.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 8,
                left: isUser ? 0 : 34,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.message.highlights.map((highlight) {
                  return InkWell(
                    onTap: () => widget.onHighlightTap(highlight),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_forward, size: 12, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text(
                            highlight.highlightedText.length > 25
                                ? '${highlight.highlightedText.substring(0, 25)}...'
                                : highlight.highlightedText,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Show "Ask about selection" button when text is selected
          if (_selectedText != null && _selectedText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 34),
              child: InkWell(
                onTap: () {
                  widget.onAskAboutText(_selectedText!, _selectionStart, _selectionEnd);
                  setState(() => _selectedText = null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_split, size: 14, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        'Branch from selection',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 150.ms),
        ],
      ),
    );
  }

  Widget _buildSelectableContent() {
    return SelectableText(
      widget.message.content,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onSelectionChanged: (selection, cause) {
        if (selection.baseOffset != selection.extentOffset) {
          final start = selection.baseOffset < selection.extentOffset 
              ? selection.baseOffset 
              : selection.extentOffset;
          final end = selection.baseOffset > selection.extentOffset 
              ? selection.baseOffset 
              : selection.extentOffset;
          
          setState(() {
            _selectedText = widget.message.content.substring(start, end);
            _selectionStart = start;
            _selectionEnd = end;
          });
        }
      },
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              onPressed: () {
                final selection = editableTextState.textEditingValue.selection;
                final text = editableTextState.textEditingValue.text.substring(
                  selection.start,
                  selection.end,
                );
                Clipboard.setData(ClipboardData(text: text));
                editableTextState.hideToolbar();
              },
              type: ContextMenuButtonType.copy,
            ),
            ContextMenuButtonItem(
              onPressed: () {
                final selection = editableTextState.textEditingValue.selection;
                final text = editableTextState.textEditingValue.text.substring(
                  selection.start,
                  selection.end,
                );
                editableTextState.hideToolbar();
                widget.onAskAboutText(text, selection.start, selection.end);
              },
              label: 'Branch',
            ),
          ],
        );
      },
    );
  }
}
