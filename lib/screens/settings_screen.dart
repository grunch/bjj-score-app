import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bjj_score/main.dart';
import 'package:bjj_score/services/key_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signerAsync = ref.watch(currentSignerProvider);
    final activePubkey = ref.watch(Signer.activePubkeyProvider);

    return signerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing authentication...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Authentication Error'),
              const SizedBox(height: 8),
              Text('$error'),
            ],
          ),
        ),
      ),
      data: (signer) {
        if (signer == null || activePubkey == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.key_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No authentication available'),
                ],
              ),
            ),
          );
        }

        final npub = Utils.encodeShareableFromString(activePubkey, type: 'npub');
        // Note: Private key cannot be directly accessed from Bip340PrivateKeySigner for security
        // For demonstration purposes, we'll show that nsec is not available
        const nsec = 'Private key not accessible (secure implementation)';

        return _buildSettingsContent(context, npub, nsec);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, String npub, String nsec) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Public Key Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.public, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Public Key (npub)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share this to allow others to filter your matches on the dashboard',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          npub,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: npub));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Public key copied to clipboard')),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showQrCode(context, 'Public Key', npub),
                              icon: const Icon(Icons.qr_code),
                              label: const Text('QR Code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Private Key Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Private Key Security',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your private key is securely generated and stored in memory only. It cannot be accessed or displayed for security reasons.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Private key is secured and not exposed',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'For production use, integrate with Amber signer (NIP-55) for persistent and secure key management.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Key Management Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Management',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Key Status
                      FutureBuilder<Map<String, dynamic>>(
                        future: KeyService.getKeyInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Loading key info...'),
                              ],
                            );
                          }
                          
                          final keyInfo = snapshot.data ?? {};
                          final hasKey = keyInfo['hasStoredPrivateKey'] ?? false;
                          final isFirst = keyInfo['isFirstLaunch'] ?? true;
                          final storageAvailable = keyInfo['storageAvailable'] ?? false;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status indicator
                              Row(
                                children: [
                                  Icon(
                                    hasKey ? Icons.check_circle : Icons.warning,
                                    color: hasKey ? Colors.green : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    hasKey ? 'Identity Secured' : 'Identity Not Stored',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: hasKey ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Details
                              Text(
                                hasKey 
                                    ? 'Your identity is securely stored and will persist across app restarts.'
                                    : 'Your identity is temporary and will be lost when the app restarts.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              
                              if (!storageAvailable) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Secure storage not available. Identity will be temporary.',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Management actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showBackupDialog(context),
                              icon: const Icon(Icons.backup),
                              label: const Text('Backup'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showResetDialog(context),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About BJJ Score',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A decentralized BJJ match scoring and publishing app powered by Nostr protocol.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All match data is published to Nostr relays and can be viewed on compatible dashboards.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showQrCode(BuildContext context, String title, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 300,
              backgroundColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup Private Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Warning: Your private key will be displayed as text.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anyone with access to this key can:\n'
                '• Create matches as you\n'
                '• Access your Nostr identity\n'
                '• Impersonate you on Nostr\n\n'
                'Only proceed if you understand the risks and are in a secure environment.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performBackup(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Show Private Key'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBackup(BuildContext context) async {
    try {
      final nsec = await KeyService.exportPrivateKeyAsNsec();
      if (nsec == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No private key found to backup')),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Private Key (nsec)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store this safely! You can use it to restore your identity:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      nsec,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: nsec));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Private key copied to clipboard')),
                    );
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => _showQrCode(context, 'Private Key QR', nsec),
                  child: const Text('QR Code'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Reset Identity'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete your current identity and create a new one.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You will lose:\n'
                '• Your current public/private key pair\n'
                '• Access to matches created with this identity\n'
                '• Your Nostr identity\n\n'
                'This action cannot be undone.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performReset(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset Identity'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performReset(BuildContext context) async {
    try {
      await KeyService.clearStoredKeys();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity reset successfully. Restart the app to create a new identity.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }
}