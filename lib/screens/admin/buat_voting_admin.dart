import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/custom_button.dart';

class BuatVotingAdminScreen extends StatefulWidget {
  const BuatVotingAdminScreen({super.key, this.poll});

  final Poll? poll;

  @override
  State<BuatVotingAdminScreen> createState() => _BuatVotingAdminScreenState();
}

class _BuatVotingAdminScreenState extends State<BuatVotingAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;
  late final List<FocusNode> _optionFocusNodes;
  bool _isActive = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.poll != null;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.poll?.question ?? '',
    );
    final initialOptions = widget.poll?.options ?? const ['', ''];
    _optionControllers = initialOptions
        .map((option) => TextEditingController(text: option))
        .toList();
    _optionFocusNodes = List.generate(
      _optionControllers.length,
      (_) => FocusNode(),
    );
    if (_optionControllers.length < 2) {
      _optionControllers.addAll(
        List.generate(
          2 - _optionControllers.length,
          (_) => TextEditingController(),
        ),
      );
      _optionFocusNodes.addAll(
        List.generate(2 - _optionFocusNodes.length, (_) => FocusNode()),
      );
    }
    _isActive = widget.poll?.isActive ?? true;
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    for (final focusNode in _optionFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 5) {
      setState(() {
        _optionControllers.add(TextEditingController());
        _optionFocusNodes.add(FocusNode());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal hanya diperbolehkan 5 pilihan.'),
        ),
      );
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final removed = _optionControllers.removeAt(index);
        final removedFocusNode = _optionFocusNodes.removeAt(index);
        removed.dispose();
        removedFocusNode.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus menyertakan 2 pilihan.')),
      );
    }
  }

  void _focusOptionField(int index) {
    if (index < 0 || index >= _optionFocusNodes.length) return;
    _optionFocusNodes[index].requestFocus();
  }

  bool _validateOptionValues() {
    final normalizedOptions = _optionControllers
        .map((controller) => controller.text.trim())
        .toList();

    for (var index = 0; index < normalizedOptions.length; index++) {
      if (normalizedOptions[index].isEmpty) {
        _focusOptionField(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua pilihan voting wajib diisi.')),
        );
        return false;
      }
    }

    final seen = <String, int>{};
    for (var index = 0; index < normalizedOptions.length; index++) {
      final normalized = normalizedOptions[index].toLowerCase();
      final previousIndex = seen[normalized];
      if (previousIndex != null) {
        _focusOptionField(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pilihan voting tidak boleh sama. Ubah salah satu pilihan yang duplikat.',
            ),
          ),
        );
        return false;
      }
      seen[normalized] = index;
    }

    return true;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal terdapat 2 pilihan yang valid.')),
      );
      return;
    }

    if (!_validateOptionValues()) return;

    final state = context.read<AppState>();
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditing) {
        await state.updatePoll(
          pollId: widget.poll!.id,
          question: question,
          isActive: _isActive,
          options: options,
        );
      } else {
        await state.createPoll(question: question, options: options);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voting berhasil dipublikasikan.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mempublikasikan voting: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isEditing ? 'Edit Voting' : 'Buat Voting';
    final submitText = _isEditing ? 'Simpan Perubahan' : 'Publikasikan Voting';
    final optionCount = _optionControllers.length;
    final canAddOption = optionCount < 5;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0.5,
        actions: const [NotificationBellButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pertanyaan / Topik Voting',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'Misal: Apakah warga setuju diadakan fogging demam berdarah?',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Topik voting tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Status Voting',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  _isActive ? 'Voting aktif untuk warga' : 'Voting ditutup',
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                value: _isActive,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilihan Jawaban (2 - 5 Pilihan)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: canAddOption ? _addOption : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Tambah Opsi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$optionCount / 5 pilihan',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _optionControllers.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            focusNode: _optionFocusNodes[index],
                            decoration: InputDecoration(
                              hintText: switch (index) {
                                0 => 'Masukkan pilihan pertama',
                                1 => 'Masukkan pilihan kedua',
                                _ => 'Masukkan pilihan ${index + 1}',
                              },
                              fillColor: Colors.white,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pilihan tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (index >= 2)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeOption(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: submitText,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
