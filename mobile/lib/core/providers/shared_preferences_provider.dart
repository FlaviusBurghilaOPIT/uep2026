import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide [SharedPreferences] instance, loaded once in `main()` and injected
/// through `ProviderScope` via `overrideWithValue`. Providers that need
/// preferences read them through this provider (spec R8) rather than calling
/// `SharedPreferences.getInstance()` themselves.
///
/// A non-`autoDispose` provider is keep-alive by default; combined with the
/// `main()` override this instance lives for the whole app lifetime.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
