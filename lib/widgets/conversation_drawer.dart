import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../data/models/conversation.dart';
import '../providers/providers.dart';

class ConversationDrawer extends ConsumerStatefulWidget {
  final String? currentConversationId;
  final Function(String) onConversationSelected;
  final VoidCallback onNewConversation;

  const ConversationDrawer({
    super.key,
    this.currentConversationId,
    required this.onConversationSelected,
    required this.onNewConversation,
  });

  @override
  ConsumerState<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationDrawerState extends ConsumerState<ConversationDrawer> {
  final Set<String> _expandedConversations = {};

  @override
  Widget build(BuildContext context) {
    final hierarchyAsync = ref.watch(conversationHierarchyProvider);

    return Drawer(
      backgroundColor: AppTheme.darkBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Bit by Bit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onNewConversation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('New Chat'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Divider(color: AppTheme.darkBorder, height: 1),
            
            // Conversations List with Tree View
            Expanded(
              child: hierarchyAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                data: (hierarchy) {
                  final rootConversations = hierarchy['root'] ?? [];
                  
                  if (rootConversations.isEmpty) {
                    return const Center(
                      child: Text(
                        'No conversations',
                        style: TextStyle(color: Colors.white38),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: rootConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = rootConversations[index];
                      return _buildConversationTile(
                        context,
                        ref,
                        conversation,
                        hierarchy,
                        depth: 0,
                        animationIndex: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WidgetRef ref,
    Conversation conversation,
    Map<String, List<Conversation>> hierarchy, {
    required int depth,
    required int animationIndex,
  }) {
    final isSelected = conversation.id == widget.currentConversationId;
    final subConversations = hierarchy[conversation.id] ?? [];
    final hasChildren = subConversations.isNotEmpty;
    final isExpanded = _expandedConversations.contains(conversation.id);

    return Column(
      children: [
        Dismissible(
          key: Key(conversation.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red.withValues(alpha: 0.1),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          ),
          confirmDismiss: (direction) async {
            final hasSubConvs = subConversations.isNotEmpty;
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.darkCard,
                title: const Text('Delete', style: TextStyle(color: Colors.white)),
                content: Text(
                  hasSubConvs 
                      ? 'This will delete ${subConversations.length} branch(es) too.'
                      : 'Delete this conversation?',
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) {
            ref.read(conversationNotifierProvider.notifier).deleteConversation(conversation.id);
          },
          child: InkWell(
            onTap: () => widget.onConversationSelected(conversation.id),
            child: Container(
              padding: EdgeInsets.only(
                left: 16 + (depth * 16.0),
                right: 16,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.05) : null,
                border: isSelected 
                    ? const Border(left: BorderSide(color: Colors.white, width: 2))
                    : null,
              ),
              child: Row(
                children: [
                  // Expand/collapse button for conversations with children
                  if (hasChildren)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedConversations.remove(conversation.id);
                          } else {
                            _expandedConversations.add(conversation.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ),
                    )
                  else
                    SizedBox(width: depth > 0 ? 8 : 24),
                  
                  // Title and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatDate(conversation.updatedAt),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            if (hasChildren) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${subConversations.length} branch${subConversations.length > 1 ? 'es' : ''}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: 30 * animationIndex)).fadeIn().slideX(begin: -0.05),
        
        // Sub-conversations (children)
        if (hasChildren && isExpanded)
          ...subConversations.asMap().entries.map((entry) {
            final index = entry.key;
            final subConv = entry.value;
            return _buildConversationTile(
              context,
              ref,
              subConv,
              hierarchy,
              depth: depth + 1,
              animationIndex: animationIndex + index + 1,
            );
          }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
