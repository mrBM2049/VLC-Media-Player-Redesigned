import 'dart:math';
import 'package:flutter/foundation.dart';

/// Repeat modes for the playback queue
enum QueueRepeatMode {
  off,
  all,
  one,
}

/// A media item in the active playback queue.
/// Separate from saved playlists in the medialibrary.
class QueueItem {
  final String id;
  final String mrl;
  final String title;
  final String? artist;
  final Duration duration;
  final String? thumbnailUri;
  final bool isPlaying;

  const QueueItem({
    required this.id,
    required this.mrl,
    required this.title,
    this.artist,
    required this.duration,
    this.thumbnailUri,
    this.isPlaying = false,
  });

  QueueItem copyWith({
    String? id,
    String? mrl,
    String? title,
    String? artist,
    Duration? duration,
    String? thumbnailUri,
    bool? isPlaying,
  }) {
    return QueueItem(
      id: id ?? this.id,
      mrl: mrl ?? this.mrl,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mrl == other.mrl &&
          title == other.title &&
          artist == other.artist &&
          duration == other.duration &&
          thumbnailUri == other.thumbnailUri &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode =>
      id.hashCode ^
      mrl.hashCode ^
      title.hashCode ^
      (artist?.hashCode ?? 0) ^
      duration.hashCode ^
      (thumbnailUri?.hashCode ?? 0) ^
      isPlaying.hashCode;

  @override
  String toString() =>
      'QueueItem(id: $id, title: $title, duration: $duration, isPlaying: $isPlaying)';
}

/// State controller for the temporary in-memory playback queue.
class QueueController extends ChangeNotifier {
  final List<QueueItem> _items = [];
  int _currentIndex = -1;
  QueueRepeatMode _repeatMode = QueueRepeatMode.off;
  bool _isShuffle = false;
  final Random _random = Random();

  QueueController({
    List<QueueItem>? initialItems,
    int initialIndex = -1,
  }) {
    if (initialItems != null && initialItems.isNotEmpty) {
      _items.addAll(initialItems);
      if (initialIndex >= 0 && initialIndex < _items.length) {
        _currentIndex = initialIndex;
        _updatePlayingState();
      }
    }
  }

  List<QueueItem> get items => List.unmodifiable(_items);
  int get currentIndex => _currentIndex;
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  QueueRepeatMode get repeatMode => _repeatMode;
  bool get isShuffle => _isShuffle;

  QueueItem? get currentItem {
    if (_currentIndex >= 0 && _currentIndex < _items.length) {
      return _items[_currentIndex];
    }
    return null;
  }

  Duration get totalDuration {
    return _items.fold<Duration>(
      Duration.zero,
      (total, item) => total + item.duration,
    );
  }

  Duration get totalRemainingDuration {
    if (_currentIndex < 0 || _currentIndex >= _items.length) {
      return totalDuration;
    }
    Duration remaining = Duration.zero;
    for (int i = _currentIndex; i < _items.length; i++) {
      remaining += _items[i].duration;
    }
    return remaining;
  }

  void _updatePlayingState() {
    for (int i = 0; i < _items.length; i++) {
      final shouldBePlaying = (i == _currentIndex);
      if (_items[i].isPlaying != shouldBePlaying) {
        _items[i] = _items[i].copyWith(isPlaying: shouldBePlaying);
      }
    }
  }

  void addItem(QueueItem item) {
    _items.add(item);
    if (_currentIndex == -1 && _items.length == 1) {
      _currentIndex = 0;
      _updatePlayingState();
    }
    notifyListeners();
  }

  void addItems(List<QueueItem> newItems) {
    if (newItems.isEmpty) return;
    _items.addAll(newItems);
    if (_currentIndex == -1) {
      _currentIndex = 0;
      _updatePlayingState();
    }
    notifyListeners();
  }

  void removeItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      removeAt(index);
    }
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;

    _items.removeAt(index);

    if (_items.isEmpty) {
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _items.length) {
        _currentIndex = _items.length - 1;
      }
      _updatePlayingState();
    }

    notifyListeners();
  }

  void clear() {
    _items.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    if (newIndex < 0 || newIndex > _items.length) return;

    // Flutter ReorderableListView quirk: when moving down, newIndex is off by 1
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    // Adjust currentIndex
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    _updatePlayingState();
    notifyListeners();
  }

  void playIndex(int index) {
    if (index < 0 || index >= _items.length) return;
    _currentIndex = index;
    _updatePlayingState();
    notifyListeners();
  }

  void playItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      playIndex(index);
    }
  }

  QueueItem? playNext() {
    if (_items.isEmpty) return null;

    if (_repeatMode == QueueRepeatMode.one && _currentIndex != -1) {
      return currentItem;
    }

    if (_isShuffle && _items.length > 1) {
      int nextIdx;
      do {
        nextIdx = _random.nextInt(_items.length);
      } while (nextIdx == _currentIndex);
      _currentIndex = nextIdx;
      _updatePlayingState();
      notifyListeners();
      return currentItem;
    }

    if (_currentIndex + 1 < _items.length) {
      _currentIndex++;
      _updatePlayingState();
      notifyListeners();
      return currentItem;
    } else if (_repeatMode == QueueRepeatMode.all) {
      _currentIndex = 0;
      _updatePlayingState();
      notifyListeners();
      return currentItem;
    }

    return null;
  }

  QueueItem? playPrevious() {
    if (_items.isEmpty) return null;

    if (_repeatMode == QueueRepeatMode.one && _currentIndex != -1) {
      return currentItem;
    }

    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      _updatePlayingState();
      notifyListeners();
      return currentItem;
    } else if (_repeatMode == QueueRepeatMode.all) {
      _currentIndex = _items.length - 1;
      _updatePlayingState();
      notifyListeners();
      return currentItem;
    }

    return null;
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void setRepeatMode(QueueRepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode = switch (_repeatMode) {
      QueueRepeatMode.off => QueueRepeatMode.all,
      QueueRepeatMode.all => QueueRepeatMode.one,
      QueueRepeatMode.one => QueueRepeatMode.off,
    };
    notifyListeners();
  }
}

