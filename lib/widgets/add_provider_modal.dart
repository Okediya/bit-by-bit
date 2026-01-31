import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../data/models/ai_provider.dart';

class ProviderFormModal extends StatefulWidget {
  final Function(AIProvider) onSave;
  final AIProvider? provider;

  const ProviderFormModal({super.key, required this.onSave, this.provider});

  @override
  State<ProviderFormModal> createState() => _ProviderFormModalState();
}

class _ProviderFormModalState extends State<ProviderFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late AIProviderType _selectedType;
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name);
    _apiKeyController = TextEditingController(text: widget.provider?.apiKey);
    _baseUrlController = TextEditingController(text: widget.provider?.baseUrl);
    _modelController = TextEditingController(text: widget.provider?.model);
    _selectedType = widget.provider?.type ?? AIProviderType.openai;
    _selectedModel = widget.provider?.model;
    
    // Ensure we have valid defaults even when editing, but don't overwrite existing values if valid
    // For dropdowns, we need to make sure the value is in the list
    if (widget.provider != null) {
      final models = AIProvider.getDefaultModels(_selectedType);
      if (models.isNotEmpty && !models.contains(_selectedModel)) {
        // If current model is not in list (legacy?), reset to first default
        _selectedModel = models.first;
      }
    } else {
      _updateDefaults();
    }
  }

  void _updateDefaults() {
    if (widget.provider == null) {
      _baseUrlController.text = AIProvider.getDefaultBaseUrl(_selectedType) ?? '';
    }
    final models = AIProvider.getDefaultModels(_selectedType);
    if (models.isNotEmpty) {
      if (!models.contains(_selectedModel)) {
        _selectedModel = models.first;
      }
    } else {
      _selectedModel = null;
      // If switching to Custom, maybe clear model controller or keep previous?
      // Let's keep it empty or default
      if (_modelController.text.isEmpty) _modelController.text = 'gpt-3.5-turbo';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final models = AIProvider.getDefaultModels(_selectedType);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(widget.provider == null ? 'Add AI Provider' : 'Edit AI Provider', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g., My OpenAI')),
              const SizedBox(height: 16),
              DropdownButtonFormField<AIProviderType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Provider Type'),
                items: AIProviderType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                onChanged: (type) {
                  if (type != null) {
                    setState(() {
                      _selectedType = type;
                      _updateDefaults();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(controller: _apiKeyController, obscureText: true, decoration: const InputDecoration(labelText: 'API Key')),
              const SizedBox(height: 16),
              
              if (models.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  decoration: const InputDecoration(labelText: 'Model'),
                  items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (m) => setState(() => _selectedModel = m),
                ),
              ] else ...[
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Model Name', hintText: 'e.g. gpt-4'),
                  onChanged: (v) => _selectedModel = v, // Keep sync
                ),
              ],
              
              const SizedBox(height: 16),
              TextField(controller: _baseUrlController, decoration: const InputDecoration(labelText: 'Base URL (optional)')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.provider == null ? 'Add Provider' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    // Determine final model string
    final models = AIProvider.getDefaultModels(_selectedType);
    String? finalModel = _selectedModel;
    
    if (models.isEmpty) {
      finalModel = _modelController.text;
    }
    
    if (_nameController.text.isEmpty || _apiKeyController.text.isEmpty || finalModel == null || finalModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    
    widget.onSave(AIProvider(
      id: widget.provider?.id ?? const Uuid().v4(),
      name: _nameController.text,
      type: _selectedType,
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
      model: finalModel,
      isActive: widget.provider?.isActive ?? true,
      createdAt: widget.provider?.createdAt,
    ));
  }
}
