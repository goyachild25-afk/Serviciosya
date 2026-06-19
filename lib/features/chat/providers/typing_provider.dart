import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado local de escritura para cada chat
final typingStatusProvider = StateProvider.family<bool, String>((ref, bookingId) => false);

// Rastrear cuándo el usuario está escribiendo
final userTypingProvider = StateNotifierProvider.family<
    UserTypingNotifier,
    bool,
    String>((ref, bookingId) {
  return UserTypingNotifier(bookingId: bookingId);
});

class UserTypingNotifier extends StateNotifier<bool> {
  final String bookingId;
  DateTime? _lastTypingTime;

  UserTypingNotifier({required this.bookingId}) : super(false);

  void setTyping(bool isTyping) {
    if (isTyping) {
      _lastTypingTime = DateTime.now();
    }
    state = isTyping;
  }

  void resetTyping() {
    state = false;
    _lastTypingTime = null;
  }

  bool get isRecentlyTyping {
    if (!state) return false;
    final now = DateTime.now();
    final lastTime = _lastTypingTime;
    if (lastTime == null) return false;
    // Considerar como "escribiendo" si fue en los últimos 2 segundos
    return now.difference(lastTime).inSeconds < 2;
  }
}
