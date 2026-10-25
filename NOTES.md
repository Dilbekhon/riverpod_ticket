# Lab 6 — Riverpod AsyncValue Ticker — Notes

Mukhammadali Khayotov

## Part 2 questions

**Why is the feed behind its own Provider?**
Dependency injection: tests and the error demo can override `tickFeedProvider` with a different `TickFeed` (empty symbols, `failAfter`) without touching `tickerProvider`. Also, `tickerProvider` watches it, so when `failAfterProvider` changes the feed is rebuilt and the stream restarts automatically.

**What does `autoDispose` do when the user navigates away mid-stream?**
When the last listener is removed, the provider is disposed: the stream subscription is cancelled (the `async*` generator stops) and the state is thrown away. Coming back creates a fresh stream that starts from `AsyncLoading` again.

**What does `tickerProvider` hold during the 800 ms delay?**
`AsyncLoading`, and `hasValue` is `false` (nothing has been emitted yet).

## Part 3 questions

**3.3 Diagnostic when `AsyncLoading()` arm is removed**
The analyzer reports a non-exhaustive switch expression, in the form:
`The type 'AsyncValue<List<Tick>>' is not exhaustively matched by the switch cases since it doesn't match 'AsyncLoading<List<Tick>>()'.`
(Paste the exact text from your own `flutter analyze` run here.)

**3.4 Why must the empty / single-symbol arms come before the general `AsyncData` arm?**
Switch arms are checked top to bottom and the first match wins. `AsyncData(:final value)` matches every list, so if it came first the specific arms would never be reached (the analyzer also flags them as unreachable).

## Part 4 questions

**4.3 `ref.refresh(...future)` vs `ref.invalidate`**
Both keep the previous rows in state while reloading (`isLoading: true`, `hasValue: true`), so the `AsyncValue(:final value?, isLoading: true)` arm keeps the list on screen. The difference is the return value: `ref.refresh(tickerProvider.future)` returns a `Future` that completes when the new data arrives, so `RefreshIndicator.onRefresh` can await it and hide its spinner at the right time. `ref.invalidate` returns `void`, so the indicator would finish immediately.

**4.4 Reconnect vs first load**
Yes: the `AsyncValue(:final value?, isLoading: true)` arm sits above `AsyncData` and `AsyncLoading`, so once any data existed the full-screen spinner never returns; only the thin `LinearProgressIndicator` shows.
`isRefreshing`: loading flag set on top of an existing data/error state by `ref.refresh` / `ref.invalidate`. `isReloading`: loading with a previous value because the provider rebuilt after a dependency changed.

## Checkpoint questions

1. **Subtypes:** `AsyncData`, `AsyncLoading`, `AsyncError`. If a switch expression misses one, the analyzer reports that the type is not exhaustively matched by the switch cases (error, code does not compile).
2. **`AsyncError.value`:** non-null when data was emitted before the error (or kept through a reload); null when the error is the first result.
3. **`ref.refresh(provider)`** invalidates and immediately re-reads, returning the new `AsyncValue`. **`ref.refresh(provider.future)`** does the same but returns a `Future` you can await until the new value/error arrives. **`ref.invalidate(provider)`** only marks it stale and returns `void`; it rebuilds when next read (immediately if something is watching).
4. An `AsyncData` that is refreshing has `isLoading: true` and still matches `AsyncData(:final value)`. Because the first match wins, the general arm would swallow it and the progress bar would never show.
5. **Switch over `.when`:** exhaustiveness plus the ability to match on content and combinations (`:final value?`, `isLoading: true`, empty list) in a single expression. **`.when` is still convenient** for a quick three-callback widget where you don't need stale-data or content-specific handling.
