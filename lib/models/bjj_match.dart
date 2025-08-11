import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

/// A BJJ match event containing match data and scoring information.
/// 
/// Represents a Brazilian Jiu-Jitsu match with fighters, scores, and match status.
/// Uses kind 31914 for addressable match events with JSON content.
class BjjMatch extends ParameterizableReplaceableModel<BjjMatch> {
  BjjMatch.fromMap(Map<String, dynamic> map, Ref ref) : super.fromMap(map, ref);

  /// The unique match identifier (4 hex characters)
  String get matchId => event.getFirstTagValue('d') ?? '';

  /// Current match status
  String get status => _parseJsonContent()['status'] ?? 'waiting';

  /// Start timestamp for the match
  int get startAt => _parseJsonContent()['start_at'] ?? 0;

  /// Match duration in seconds
  int get duration => _parseJsonContent()['duration'] ?? 0;

  /// Fighter 1 name
  String get f1Name => _parseJsonContent()['f1_name'] ?? '';

  /// Fighter 2 name
  String get f2Name => _parseJsonContent()['f2_name'] ?? '';

  /// Fighter 1 gi color (hex)
  String get f1Color => _parseJsonContent()['f1_color'] ?? '#0066cc';

  /// Fighter 2 gi color (hex)  
  String get f2Color => _parseJsonContent()['f2_color'] ?? '#cc0066';

  /// Fighter 1 - 2 point moves
  int get f1Pt2 => _parseJsonContent()['f1_pt2'] ?? 0;

  /// Fighter 2 - 2 point moves
  int get f2Pt2 => _parseJsonContent()['f2_pt2'] ?? 0;

  /// Fighter 1 - 3 point moves
  int get f1Pt3 => _parseJsonContent()['f1_pt3'] ?? 0;

  /// Fighter 2 - 3 point moves
  int get f2Pt3 => _parseJsonContent()['f2_pt3'] ?? 0;

  /// Fighter 1 - 4 point moves
  int get f1Pt4 => _parseJsonContent()['f1_pt4'] ?? 0;

  /// Fighter 2 - 4 point moves
  int get f2Pt4 => _parseJsonContent()['f2_pt4'] ?? 0;

  /// Fighter 1 advantages
  int get f1Adv => _parseJsonContent()['f1_adv'] ?? 0;

  /// Fighter 2 advantages
  int get f2Adv => _parseJsonContent()['f2_adv'] ?? 0;

  /// Fighter 1 penalties
  int get f1Pen => _parseJsonContent()['f1_pen'] ?? 0;

  /// Fighter 2 penalties
  int get f2Pen => _parseJsonContent()['f2_pen'] ?? 0;

  /// Calculate Fighter 1 total score: (pt2 × 2) + (pt3 × 3) + (pt4 × 4)
  int get f1Score => (f1Pt2 * 2) + (f1Pt3 * 3) + (f1Pt4 * 4);

  /// Calculate Fighter 2 total score: (pt2 × 2) + (pt3 × 3) + (pt4 × 4)
  int get f2Score => (f2Pt2 * 2) + (f2Pt3 * 3) + (f2Pt4 * 4);

  /// Check if match is currently active
  bool get isActive => status == 'in-progress';

  /// Check if match is waiting to start
  bool get isWaiting => status == 'waiting';

  /// Check if match is finished
  bool get isFinished => status == 'finished';

  /// Parse JSON content safely
  Map<String, dynamic> _parseJsonContent() {
    try {
      return jsonDecode(event.content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}

/// Partial (mutable) BJJ match for creating and editing matches.
class PartialBjjMatch extends ParameterizableReplaceablePartialModel<BjjMatch> {
  PartialBjjMatch({
    required String matchId,
    String status = 'waiting',
    int startAt = 0,
    int duration = 600, // 10 minutes default
    String f1Name = '',
    String f2Name = '',
    String f1Color = '#0066cc',
    String f2Color = '#cc0066',
    int f1Pt2 = 0,
    int f2Pt2 = 0,
    int f1Pt3 = 0,
    int f2Pt3 = 0,
    int f1Pt4 = 0,
    int f2Pt4 = 0,
    int f1Adv = 0,
    int f2Adv = 0,
    int f1Pen = 0,
    int f2Pen = 0,
    DateTime? createdAt,
  }) : super() {
    // Set event properties via available methods
    if (createdAt != null) {
      event.createdAt = createdAt;
    }
    
    // Set the 'd' tag for addressable events
    event.setTagValue('d', matchId);

    // Set JSON content
    _updateJsonContent({
      'id': matchId,
      'status': status,
      'start_at': startAt,
      'duration': duration,
      'f1_name': f1Name,
      'f2_name': f2Name,
      'f1_color': f1Color,
      'f2_color': f2Color,
      'f1_pt2': f1Pt2,
      'f2_pt2': f2Pt2,
      'f1_pt3': f1Pt3,
      'f2_pt3': f2Pt3,
      'f1_pt4': f1Pt4,
      'f2_pt4': f2Pt4,
      'f1_adv': f1Adv,
      'f2_adv': f2Adv,
      'f1_pen': f1Pen,
      'f2_pen': f2Pen,
    });
  }

  PartialBjjMatch.fromMap(Map<String, dynamic> map) : super.fromMap(map);

  @override
  int get kind => 31914;

  /// The unique match identifier (4 hex characters)
  String get matchId => event.getFirstTagValue('d') ?? '';
  set matchId(String value) {
    event.setTagValue('d', value);
    _updateJsonField('id', value);
  }

  /// Current match status
  String get status => _parseJsonContent()['status'] ?? 'waiting';
  set status(String value) => _updateJsonField('status', value);

  /// Start timestamp for the match
  int get startAt => _parseJsonContent()['start_at'] ?? 0;
  set startAt(int value) => _updateJsonField('start_at', value);

  /// Match duration in seconds
  int get duration => _parseJsonContent()['duration'] ?? 0;
  set duration(int value) => _updateJsonField('duration', value);

  /// Fighter 1 name
  String get f1Name => _parseJsonContent()['f1_name'] ?? '';
  set f1Name(String value) => _updateJsonField('f1_name', value);

  /// Fighter 2 name
  String get f2Name => _parseJsonContent()['f2_name'] ?? '';
  set f2Name(String value) => _updateJsonField('f2_name', value);

  /// Fighter 1 gi color (hex)
  String get f1Color => _parseJsonContent()['f1_color'] ?? '#0066cc';
  set f1Color(String value) => _updateJsonField('f1_color', value);

  /// Fighter 2 gi color (hex)
  String get f2Color => _parseJsonContent()['f2_color'] ?? '#cc0066';
  set f2Color(String value) => _updateJsonField('f2_color', value);

  /// Fighter 1 - 2 point moves
  int get f1Pt2 => _parseJsonContent()['f1_pt2'] ?? 0;
  set f1Pt2(int value) => _updateJsonField('f1_pt2', value);

  /// Fighter 2 - 2 point moves
  int get f2Pt2 => _parseJsonContent()['f2_pt2'] ?? 0;
  set f2Pt2(int value) => _updateJsonField('f2_pt2', value);

  /// Fighter 1 - 3 point moves
  int get f1Pt3 => _parseJsonContent()['f1_pt3'] ?? 0;
  set f1Pt3(int value) => _updateJsonField('f1_pt3', value);

  /// Fighter 2 - 3 point moves
  int get f2Pt3 => _parseJsonContent()['f2_pt3'] ?? 0;
  set f2Pt3(int value) => _updateJsonField('f2_pt3', value);

  /// Fighter 1 - 4 point moves
  int get f1Pt4 => _parseJsonContent()['f1_pt4'] ?? 0;
  set f1Pt4(int value) => _updateJsonField('f1_pt4', value);

  /// Fighter 2 - 4 point moves
  int get f2Pt4 => _parseJsonContent()['f2_pt4'] ?? 0;
  set f2Pt4(int value) => _updateJsonField('f2_pt4', value);

  /// Fighter 1 advantages
  int get f1Adv => _parseJsonContent()['f1_adv'] ?? 0;
  set f1Adv(int value) => _updateJsonField('f1_adv', value);

  /// Fighter 2 advantages
  int get f2Adv => _parseJsonContent()['f2_adv'] ?? 0;
  set f2Adv(int value) => _updateJsonField('f2_adv', value);

  /// Fighter 1 penalties
  int get f1Pen => _parseJsonContent()['f1_pen'] ?? 0;
  set f1Pen(int value) => _updateJsonField('f1_pen', value);

  /// Fighter 2 penalties
  int get f2Pen => _parseJsonContent()['f2_pen'] ?? 0;
  set f2Pen(int value) => _updateJsonField('f2_pen', value);

  /// Calculate Fighter 1 total score
  int get f1Score => (f1Pt2 * 2) + (f1Pt3 * 3) + (f1Pt4 * 4);

  /// Calculate Fighter 2 total score
  int get f2Score => (f2Pt2 * 2) + (f2Pt3 * 3) + (f2Pt4 * 4);

  /// Check if match is currently active
  bool get isActive => status == 'in-progress';

  /// Check if match is waiting to start
  bool get isWaiting => status == 'waiting';

  /// Check if match is finished
  bool get isFinished => status == 'finished';

  /// Generate a random 4-character hex match ID
  static String generateMatchId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 0x10000).toRadixString(16).padLeft(4, '0');
  }

  /// Start the match (change status to in-progress and set start time)
  void startMatch() {
    status = 'in-progress';
    startAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Finish the match
  void finishMatch() {
    status = 'finished';
    // Add expiration tag for 1 week from now
    final expiration = DateTime.now().add(const Duration(days: 7));
    event.setTagValue('expiration', (expiration.millisecondsSinceEpoch ~/ 1000).toString());
  }

  /// Cancel the match
  void cancelMatch() {
    status = 'canceled';
    // Add expiration tag for 1 week from now
    final expiration = DateTime.now().add(const Duration(days: 7));
    event.setTagValue('expiration', (expiration.millisecondsSinceEpoch ~/ 1000).toString());
  }

  /// Parse JSON content safely
  Map<String, dynamic> _parseJsonContent() {
    try {
      return jsonDecode(event.content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Update a single field in JSON content
  void _updateJsonField(String field, dynamic value) {
    final current = _parseJsonContent();
    current[field] = value;
    _updateJsonContent(current);
  }

  /// Update entire JSON content
  void _updateJsonContent(Map<String, dynamic> data) {
    event.content = jsonEncode(data);
  }
}