import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:purplebase/purplebase.dart';
import 'package:bjj_score/models/bjj_match.dart';
import 'package:bjj_score/main.dart';

class CreateMatchScreen extends HookConsumerWidget {
  const CreateMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f1NameController = useTextEditingController();
    final f2NameController = useTextEditingController();
    final durationController = useTextEditingController(text: '600');
    
    final f1Color = useState<Color>(const Color(0xFF0066CC));
    final f2Color = useState<Color>(const Color(0xFFCC0066));
    final isCreating = useState(false);

    Future<void> createMatch() async {
      if (f1NameController.text.trim().isEmpty || 
          f2NameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both fighter names')),
        );
        return;
      }

      final duration = int.tryParse(durationController.text) ?? 600;
      if (duration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duration must be greater than 0')),
        );
        return;
      }

      isCreating.value = true;
      
      try {
        final matchId = PartialBjjMatch.generateMatchId();
        
        final partialMatch = PartialBjjMatch(
          matchId: matchId,
          f1Name: f1NameController.text.trim(),
          f2Name: f2NameController.text.trim(),
          f1Color: '#${f1Color.value.value.toRadixString(16).substring(2)}',
          f2Color: '#${f2Color.value.value.toRadixString(16).substring(2)}',
          duration: duration,
        );

        // Get the signer for signing events
        final signerAsync = await ref.read(currentSignerProvider.future);
        if (signerAsync == null) {
          throw Exception('No signer available');
        }

        // Sign the match
        final signedMatch = await partialMatch.signWith(signerAsync);
        
        // Save locally and publish to relays
        await ref.read(storageNotifierProvider.notifier).save({signedMatch});
        await ref.read(storageNotifierProvider.notifier).publish({signedMatch});

        if (context.mounted) {
          // Navigate to the scoring screen
          context.go('/match/$matchId');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create match: $e')),
          );
        }
      } finally {
        isCreating.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create BJJ Match'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fighter Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      // Fighter 1
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: f1Color.value,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: f1NameController,
                              decoration: const InputDecoration(
                                labelText: 'Fighter 1 Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final color = await showDialog<Color>(
                                context: context,
                                builder: (context) => ColorPickerDialog(
                                  currentColor: f1Color.value,
                                ),
                              );
                              if (color != null) {
                                f1Color.value = color;
                              }
                            },
                            icon: const Icon(Icons.palette),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Fighter 2
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: f2Color.value,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: f2NameController,
                              decoration: const InputDecoration(
                                labelText: 'Fighter 2 Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final color = await showDialog<Color>(
                                context: context,
                                builder: (context) => ColorPickerDialog(
                                  currentColor: f2Color.value,
                                ),
                              );
                              if (color != null) {
                                f2Color.value = color;
                              }
                            },
                            icon: const Icon(Icons.palette),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Settings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (seconds)',
                          helperText: '600 = 10 minutes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isCreating.value ? null : createMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: isCreating.value
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Match...'),
                          ],
                        )
                      : const Text(
                          'Create Match',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorPickerDialog extends StatelessWidget {
  final Color currentColor;

  const ColorPickerDialog({
    super.key,
    required this.currentColor,
  });

  static const List<Color> predefinedColors = [
    Color(0xFF0066CC), // Blue
    Color(0xFFCC0066), // Pink/Red
    Color(0xFF2E7D32), // Green
    Color(0xFFFF6F00), // Orange
    Color(0xFF6A1B9A), // Purple
    Color(0xFF37474F), // Dark Gray
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Dark Blue
    Color(0xFF388E3C), // Dark Green
    Color(0xFFE64A19), // Deep Orange
    Color(0xFF7B1FA2), // Dark Purple
    Color(0xFF455A64), // Blue Gray
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Gi Color'),
      content: SizedBox(
        width: 250,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: predefinedColors.length,
          itemBuilder: (context, index) {
            final color = predefinedColors[index];
            final isSelected = color.value == currentColor.value;
            
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}