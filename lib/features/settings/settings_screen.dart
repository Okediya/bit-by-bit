import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ai_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/add_provider_modal.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(aiProvidersProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(), 
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings', 
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI PROVIDERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAddProviderModal(context, ref),
                          child: const Text('Add', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure your API keys',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            providersAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Text('Error: $e', style: const TextStyle(color: Colors.white54)),
              ),
              data: (providers) => providers.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState(context, ref))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _ProviderCard(
                          provider: providers[i],
                          ref: ref,
                          onEdit: (p) => _showAddProviderModal(context, ref, providerToEdit: p),
                        ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(),
                        childCount: providers.length,
                      ),
                    ),
                  ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoTile('Version', '1.0.0'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(subtitle, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'No providers configured',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _showAddProviderModal(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Provider'),
          ),
        ],
      ),
    );
  }

  void _showAddProviderModal(BuildContext context, WidgetRef ref, {AIProvider? providerToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProviderFormModal(
        provider: providerToEdit,
        onSave: (provider) async {
          final repo = ref.read(dataRepositoryProvider);
          await repo.saveProvider(provider);
          ref.invalidate(aiProvidersProvider);
          ref.invalidate(activeAIProviderProvider);
          if (!context.mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final AIProvider provider;
  final WidgetRef ref;
  final Function(AIProvider) onEdit;
  
  const _ProviderCard({
    required this.provider,
    required this.ref,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: provider.isActive ? Colors.white : AppTheme.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    provider.name, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  if (provider.isActive) 
                    Container(
                      margin: const EdgeInsets.only(left: 8), 
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(4),
                      ), 
                      child: const Text(
                        'Active', 
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${provider.type.displayName} - ${provider.model}', 
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
            color: AppTheme.darkCard,
            onSelected: (v) async {
              final repo = ref.read(dataRepositoryProvider);
              if (v == 'edit') {
                onEdit(provider);
              }
              if (v == 'activate') await repo.saveProvider(provider.copyWith(isActive: true));
              if (v == 'delete') await repo.deleteProvider(provider.id);
              ref.invalidate(aiProvidersProvider);
              ref.invalidate(activeAIProviderProvider);
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'edit', 
                child: Text('Edit', style: TextStyle(color: Colors.white70)),
              ),
              if (!provider.isActive) 
                const PopupMenuItem(
                  value: 'activate', 
                  child: Text('Set Active', style: TextStyle(color: Colors.white70)),
                ),
              const PopupMenuItem(
                value: 'delete', 
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
