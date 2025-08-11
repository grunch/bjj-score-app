import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:purplebase/purplebase.dart';
import 'package:bjj_score/models/bjj_match.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user's matches - query all matches for now
    final matchesState = ref.watch(
      query<BjjMatch>(
        // Use local storage for deduplicated results
        source: LocalSource(stream: true),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('BJJ Score'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (matchesState) {
          StorageLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          StorageError(:final exception) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $exception'),
                ],
              ),
            ),
          StorageData(:final models) {
            // Deduplicate matches by matchId and take the latest version
            final matches = _deduplicateMatches(
              models.cast<BjjMatch>(),
            );

            return matches.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_mma,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No matches yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first BJJ match to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Match'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                    children: [
                      // Status filters
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              'Your Matches',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Spacer(),
                            Text('${matches.length} total'),
                          ],
                        ),
                      ),

                      // Match list
                      Expanded(
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            return MatchCard(match: match);
                          },
                        ),
                      ),
                    ],
                  );
          },
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Deduplicate matches by their address (matchId) and keep latest version
List<BjjMatch> _deduplicateMatches(List<BjjMatch> matches) {
  final Map<String, BjjMatch> latest = {};
  for (final match in matches) {
    final existing = latest[match.matchId];
    if (existing == null ||
        match.event.createdAt > existing.event.createdAt) {
      latest[match.matchId] = match;
    }
  }
  final result = latest.values.toList();
  result.sort(
    (a, b) => b.event.createdAt.compareTo(a.event.createdAt),
  );
  return result;
}

String _formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 7) {
    return '${dateTime.day}/${dateTime.month}';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'now';
  }
}

class MatchCard extends StatelessWidget {
  final BjjMatch match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final f1Color = Color(int.parse(match.f1Color.replaceFirst('#', '0xFF')));
    final f2Color = Color(int.parse(match.f2Color.replaceFirst('#', '0xFF')));

    Color statusColor;
    IconData statusIcon;
    
    switch (match.status) {
      case 'waiting':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'in-progress':
        statusColor = Colors.green;
        statusIcon = Icons.play_arrow;
        break;
      case 'finished':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'canceled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => context.push('/match/${match.matchId}'),
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with match ID and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          match.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${match.matchId.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Fighters and scores
              Row(
                children: [
                  // Fighter 1
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: f1Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.f1Name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${match.f1Score}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('vs', style: TextStyle(fontSize: 12)),
                  ),
                  
                  // Fighter 2
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '${match.f2Score}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.f2Name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: f2Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Match details
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${match.duration ~/ 60}:${(match.duration % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (match.event.createdAt != null)
                    Text(
                      _formatRelativeTime(match.event.createdAt!),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}