import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_enums.dart';
import '../../core/storage/settings_keys.dart';
import '../../core/storage/shared_prefs_provider.dart';

final lastOpenedContentServiceProvider = Provider<LastOpenedContentService>((ref) {
  return LastOpenedContentService(ref.watch(sharedPreferencesProvider));
});

class LastOpenedEntry {
  final String id;
  final String title;
  final ContentType type;
  final DateTime openedAt;

  const LastOpenedEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.openedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type == ContentType.lesson ? 'lesson' : 'exam',
        'opened_at': openedAt.toIso8601String(),
      };

  factory LastOpenedEntry.fromJson(Map<String, dynamic> json) => LastOpenedEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        type: ContentType.fromString(json['type'] as String),
        openedAt: DateTime.parse(json['opened_at'] as String),
      );
}

/// يحفظ آخر المحتوى الذي فتحه الطالب محليًا (حتى 5 عناصر) — Phase 7.
class LastOpenedContentService {
  final SharedPreferences _prefs;
  static const _maxEntries = 5;

  LastOpenedContentService(this._prefs);

  Future<void> recordOpen({
    required String contentId,
    required String title,
    required ContentType type,
  }) async {
    final existing = readEntries();
    final filtered = existing.where((e) => e.id != contentId).toList();
    filtered.insert(
      0,
      LastOpenedEntry(
        id: contentId,
        title: title,
        type: type,
        openedAt: DateTime.now(),
      ),
    );
    final trimmed = filtered.take(_maxEntries).toList();
    await _prefs.setString(
      SettingsKeys.lastOpenedContents,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  List<LastOpenedEntry> readEntries() {
    final raw = _prefs.getString(SettingsKeys.lastOpenedContents);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LastOpenedEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final lastOpenedRefreshProvider = StateProvider<int>((ref) => 0);

final lastOpenedEntriesProvider = Provider<List<LastOpenedEntry>>((ref) {
  ref.watch(lastOpenedRefreshProvider);
  return ref.watch(lastOpenedContentServiceProvider).readEntries();
});

/// يسجّل فتح المحتوى مرة واحدة عند بناء الشاشة.
class RecordLastOpenedContent extends ConsumerStatefulWidget {
  final String contentId;
  final String title;
  final ContentType type;
  final Widget child;

  const RecordLastOpenedContent({
    super.key,
    required this.contentId,
    required this.title,
    required this.type,
    required this.child,
  });

  @override
  ConsumerState<RecordLastOpenedContent> createState() => _RecordLastOpenedContentState();
}

class _RecordLastOpenedContentState extends ConsumerState<RecordLastOpenedContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(lastOpenedContentServiceProvider).recordOpen(
            contentId: widget.contentId,
            title: widget.title,
            type: widget.type,
          );
      ref.read(lastOpenedRefreshProvider.notifier).state++;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
