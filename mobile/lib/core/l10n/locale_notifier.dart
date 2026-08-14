import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/shared_preferences_provider.dart';

part 'locale_notifier.g.dart';

/// App locale, persisted under `user_locale` (spec R13). The saved value is
/// read synchronously from the app-wide [sharedPreferencesProvider] in
/// [build]; `main()` guarantees that provider is overridden before the app
/// builds, so no async init is needed.
@Riverpod(keepAlive: true)
class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'user_locale';

  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}
