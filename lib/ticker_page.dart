import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/tick.dart';
import 'providers/ticker_providers.dart';
import 'widgets/tick_row.dart';

class TickerPage extends ConsumerWidget {
  const TickerPage({super.key});

  Widget _rows(List<Tick> ticks, WidgetRef ref) => RefreshIndicator(
        onRefresh: () => ref.refresh(tickerProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [for (final t in ticks) TickRow(t, key: ValueKey(t.symbol))],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticks = ref.watch(tickerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live ticker'),
        actions: [
          IconButton(
            tooltip: 'Simulate feed failure',
            icon: const Icon(Icons.bug_report),
            onPressed: () => ref.read(failAfterProvider.notifier).state = 5,
          ),
          IconButton(
            tooltip: 'Restore feed',
            icon: const Icon(Icons.wifi),
            onPressed: () => ref.read(failAfterProvider.notifier).state = null,
          ),
        ],
      ),
      body: switch (ticks) {
        // Error with stale data: show rows dimmed, banner on top
        AsyncError(:final error, :final value?) => Column(children: [
            MaterialBanner(
              content: Text('Feed error: $error — showing last prices'),
              actions: [
                TextButton(
                  onPressed: () => ref.invalidate(tickerProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            Expanded(
              child: Opacity(opacity: 0.5, child: _rows(value, ref)),
            ),
          ]),

        // Error with nothing to show
        AsyncError(:final error) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Could not load ticker\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(tickerProvider),
                child: const Text('Retry'),
              ),
            ]),
          ),

        // Refresh in progress, keep rows, show thin progress bar
        AsyncValue(:final value?, isLoading: true) => Column(children: [
            const LinearProgressIndicator(),
            Expanded(child: _rows(value, ref)),
          ]),

        // Content patterns (Exercise 3.4) - must sit above the general arm
        AsyncData(value: []) => const Center(child: Text('No symbols subscribed')),
        AsyncData(value: [final only]) => Center(child: TickRow(only)),

        AsyncData(:final value) => _rows(value, ref),

        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
