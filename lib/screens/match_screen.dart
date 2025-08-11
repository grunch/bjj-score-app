import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:purplebase/purplebase.dart';
import 'package:bjj_score/models/bjj_match.dart';
import 'package:bjj_score/main.dart';

class MatchScreen extends HookConsumerWidget {
  final String matchId;

  const MatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(
      query<BjjMatch>(
        tags: {'#d': {matchId}},
        // Use local storage to leverage built-in deduplication
        source: LocalSource(),
      ),
    );

    return switch (matchState) {
      StorageLoading() => Scaffold(
          appBar: AppBar(title: const Text('Loading Match...')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      StorageError(:final exception) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading match: $exception'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      StorageData(:final models) => () {
        if (models.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Match Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64),
                  const SizedBox(height: 16),
                  Text('Match $matchId not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        final match = _latestMatch(models.cast<BjjMatch>());
        return MatchControlWidget(match: match);
      }(),
    };
  }
}

// Select the newest version of a match from a list
BjjMatch _latestMatch(List<BjjMatch> matches) {
  matches.sort((a, b) => b.event.createdAt.compareTo(a.event.createdAt));
  return matches.first;
}

class MatchControlWidget extends HookConsumerWidget {
  final BjjMatch match;

  const MatchControlWidget({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingSeconds = useState(match.duration);
    final isRunning = useState(match.isActive);

    useEffect(() {
      Timer? timer;
      if (isRunning.value && remainingSeconds.value > 0) {
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (remainingSeconds.value > 0) {
            remainingSeconds.value--;
          } else {
            isRunning.value = false;
          }
        });
      }
      return timer?.cancel;
    }, [isRunning.value]);

    // Update remaining seconds when match data changes
    useEffect(() {
      if (match.isActive && match.startAt > 0) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final elapsed = now - match.startAt;
        final remaining = match.duration - elapsed;
        remainingSeconds.value = remaining > 0 ? remaining : 0;
        isRunning.value = remaining > 0;
      } else {
        remainingSeconds.value = match.duration;
        isRunning.value = false;
      }
    }, [match.status, match.startAt, match.duration]);

    Future<void> updateMatch(PartialBjjMatch Function(PartialBjjMatch) updater) async {
      try {
        final partial = match.toPartial<PartialBjjMatch>();
        final updated = updater(partial);
        
        final signerAsync = await ref.read(currentSignerProvider.future);
        if (signerAsync == null) throw Exception('No signer available');
        
        final signed = await updated.signWith(signerAsync);
        await ref.read(storageNotifierProvider.notifier).save({signed});
        await ref.read(storageNotifierProvider.notifier).publish({signed});
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $e')),
          );
        }
      }
    }

    Future<void> startMatch() async {
      await updateMatch((partial) {
        partial.startMatch();
        return partial;
      });
      remainingSeconds.value = match.duration;
      isRunning.value = true;
    }

    Future<void> finishMatch() async {
      await updateMatch((partial) {
        partial.finishMatch();
        return partial;
      });
      isRunning.value = false;
    }

    String formatTime(int seconds) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    final f1Color = Color(int.parse(match.f1Color.replaceFirst('#', '0xFF')));
    final f2Color = Color(int.parse(match.f2Color.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Match ${match.matchId.toUpperCase()}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (match.isWaiting)
            TextButton.icon(
              onPressed: startMatch,
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              label: const Text('START', style: TextStyle(color: Colors.green)),
            )
          else if (match.isActive)
            TextButton.icon(
              onPressed: finishMatch,
              icon: const Icon(Icons.stop, color: Colors.red),
              label: const Text('FINISH', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer and Status
            Container(
              width: double.infinity,
              color: match.isActive ? Colors.green : 
                    match.isFinished ? Colors.red : Colors.orange,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    formatTime(remainingSeconds.value),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Fighter Names and Total Scores
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: f1Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.f1Name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${match.f1Score}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: f2Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.f2Name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${match.f2Score}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Scoring Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Point categories
                    Expanded(
                      child: Row(
                        children: [
                          // Left fighter (F1)
                          Expanded(
                            child: Column(
                              children: [
                                // 2 Points
                                Expanded(
                                  child: ScoreCard(
                                    title: 'Montada, Toma de espalda',
                                    score: match.f1Pt2,
                                    color: Colors.blue,
                                    onIncrement: () => updateMatch((p) => p..f1Pt2 = p.f1Pt2 + 1),
                                    onDecrement: () => updateMatch((p) => p..f1Pt2 = (p.f1Pt2 - 1).clamp(0, 999)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 3 Points  
                                Expanded(
                                  child: ScoreCard(
                                    title: 'Pase de guardia',
                                    score: match.f1Pt3,
                                    color: Colors.blue,
                                    onIncrement: () => updateMatch((p) => p..f1Pt3 = p.f1Pt3 + 1),
                                    onDecrement: () => updateMatch((p) => p..f1Pt3 = (p.f1Pt3 - 1).clamp(0, 999)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 4 Points
                                Expanded(
                                  child: ScoreCard(
                                    title: 'Derribo, Raspada, Rodilla al pecho',
                                    score: match.f1Pt4,
                                    color: Colors.blue,
                                    onIncrement: () => updateMatch((p) => p..f1Pt4 = p.f1Pt4 + 1),
                                    onDecrement: () => updateMatch((p) => p..f1Pt4 = (p.f1Pt4 - 1).clamp(0, 999)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Right fighter (F2)
                          Expanded(
                            child: Column(
                              children: [
                                // 2 Points
                                Expanded(
                                  child: ScoreCard(
                                    title: 'Montada, Toma de espalda',
                                    score: match.f2Pt2,
                                    color: Colors.red,
                                    onIncrement: () => updateMatch((p) => p..f2Pt2 = p.f2Pt2 + 1),
                                    onDecrement: () => updateMatch((p) => p..f2Pt2 = (p.f2Pt2 - 1).clamp(0, 999)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 3 Points
                                Expanded(
                                  child: ScoreCard(
                                    title: 'Pase de guardia', 
                                    score: match.f2Pt3,
                                    color: Colors.red,
                                    onIncrement: () => updateMatch((p) => p..f2Pt3 = p.f2Pt3 + 1),
                                    onDecrement: () => updateMatch((p) => p..f2Pt3 = (p.f2Pt3 - 1).clamp(0, 999)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 4 Points
                                Expanded(
                                  child: ScoreCard(
                                    title: 'Derribo, Raspada, Rodilla al pecho',
                                    score: match.f2Pt4,
                                    color: Colors.red,
                                    onIncrement: () => updateMatch((p) => p..f2Pt4 = p.f2Pt4 + 1),
                                    onDecrement: () => updateMatch((p) => p..f2Pt4 = (p.f2Pt4 - 1).clamp(0, 999)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Advantages and Penalties Row
                    Row(
                      children: [
                        // F1 Advantages
                        Expanded(
                          child: ScoreCard(
                            title: 'Ventaja',
                            score: match.f1Adv,
                            color: Colors.blue,
                            onIncrement: () => updateMatch((p) => p..f1Adv = p.f1Adv + 1),
                            onDecrement: () => updateMatch((p) => p..f1Adv = (p.f1Adv - 1).clamp(0, 999)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // F1 Penalties
                        Expanded(
                          child: ScoreCard(
                            title: 'Penalización',
                            score: match.f1Pen,
                            color: Colors.blue,
                            onIncrement: () => updateMatch((p) => p..f1Pen = p.f1Pen + 1),
                            onDecrement: () => updateMatch((p) => p..f1Pen = (p.f1Pen - 1).clamp(0, 999)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // F2 Advantages
                        Expanded(
                          child: ScoreCard(
                            title: 'Ventaja',
                            score: match.f2Adv,
                            color: Colors.red,
                            onIncrement: () => updateMatch((p) => p..f2Adv = p.f2Adv + 1),
                            onDecrement: () => updateMatch((p) => p..f2Adv = (p.f2Adv - 1).clamp(0, 999)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // F2 Penalties
                        Expanded(
                          child: ScoreCard(
                            title: 'Penalización',
                            score: match.f2Pen,
                            color: Colors.red,
                            onIncrement: () => updateMatch((p) => p..f2Pen = p.f2Pen + 1),
                            onDecrement: () => updateMatch((p) => p..f2Pen = (p.f2Pen - 1).clamp(0, 999)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onIncrement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onDecrement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.remove),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}