import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/client.dart';

final clientProvider = Provider<QChatClient>((ref) {
  final client = QChatClient();
  ref.onDispose(client.dispose);
  return client;
});

class Preferences extends Notifier<({String locale, bool dark})> {
  @override
  ({String locale, bool dark}) build() => (locale: 'vi', dark: false);
  void language(String value) => state = (locale: value, dark: state.dark);
  void appearance(bool value) => state = (locale: state.locale, dark: value);
}

final preferencesProvider =
    NotifierProvider<Preferences, ({String locale, bool dark})>(
      Preferences.new,
    );
