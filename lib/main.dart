import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:purplebase/purplebase.dart';
import 'package:bjj_score/router.dart';
import 'package:bjj_score/theme.dart';
import 'package:bjj_score/models/bjj_match.dart';
import 'package:bjj_score/services/key_service.dart';

// Create and authenticate a persistent signer for the app
final currentSignerProvider = FutureProvider<Signer?>((ref) async {
  try {
    // Get or create a persistent private key
    final privateKey = await KeyService.getOrCreatePrivateKey();
    final signer = Bip340PrivateKeySigner(privateKey, ref);
    
    // Check if this is the first launch for logging
    final isFirstLaunch = await KeyService.isFirstLaunch();
    if (isFirstLaunch) {
      debugPrint('BJJ Score: First launch detected, new identity created');
    } else {
      debugPrint('BJJ Score: Using existing identity');
    }
    
    // Sign in the signer to make it active and accessible
    await signer.signIn(setAsActive: true);
    return signer;
  } catch (e) {
    debugPrint('Signer initialization failed: $e');
    return null;
  }
});

void main() {
  runZonedGuarded(() {
    runApp(
      ProviderScope(
        overrides: [
          storageNotifierProvider.overrideWith(
            (ref) => PurplebaseStorageNotifier(ref),
          ),
        ],
        child: const BjjScoreApp(),
      ),
    );
  }, errorHandler);

  FlutterError.onError = (details) {
    // Prevents debugger stopping multiple times
    FlutterError.dumpErrorToConsole(details);
    errorHandler(details.exception, details.stack);
  };
}

class BjjScoreApp extends ConsumerWidget {
  const BjjScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = 'BjjScore';
    final theme = ref.watch(themeProvider);

    return switch (ref.watch(appInitializationProvider)) {
      AsyncLoading() => MaterialApp(
        title: title,
        theme: theme,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      ),
      AsyncError(:final error) => MaterialApp(
        title: title,
        theme: theme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
      _ => MaterialApp.router(
        title: title,
        theme: theme,
        routerConfig: ref.watch(routerProvider),
        debugShowCheckedModeBanner: false,
        builder: (_, child) => child!,
      ),
    };
  }
}

class BjjScoreHome extends StatelessWidget {
  const BjjScoreHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rocket_launch,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'BjjScore',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Nostr-enabled Flutter development stack',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void errorHandler(Object exception, StackTrace? stack) {
  // TODO: Implement proper error handling
  debugPrint('Error: $exception');
  debugPrint('Stack trace: $stack');
}

final appInitializationProvider = FutureProvider<void>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  await ref.read(
    initializationProvider(
      StorageConfiguration(
        databasePath: path.join(dir.path, 'bjj_score.db'),
        relayGroups: {
          'default': {
            'wss://relay.mostro.network',
            'wss://relay.damus.io',
          },
        },
        defaultRelayGroup: 'default',
      ),
    ).future,
  );
  
  // Register the custom BJJ match model
  Model.register<BjjMatch>(
    kind: 31914,
    constructor: BjjMatch.fromMap,
    partialConstructor: PartialBjjMatch.fromMap,
  );
});
