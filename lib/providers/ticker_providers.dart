import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3.x moved StateProvider to the legacy entrypoint.
import 'package:flutter_riverpod/legacy.dart';
import '../models/tick.dart';
import '../services/tick_feed.dart';

/// Demo toggle: null = never fail, N = feed throws after N ticks.
final failAfterProvider = StateProvider<int?>((ref) => null);

/// Overridable in tests and in the error demo.
final tickFeedProvider = Provider<TickFeed>((ref) {
  return TickFeed(failAfter: ref.watch(failAfterProvider));
});

final tickerProvider = StreamProvider.autoDispose<List<Tick>>(
  (ref) => ref.watch(tickFeedProvider).watch(),
  // Riverpod 3 auto-retries failed providers by default. Disable it so the
  // error state (and the manual Retry button) is observable.
  retry: (retryCount, error) => null,
);
