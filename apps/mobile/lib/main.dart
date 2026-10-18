import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:go_router/go_router.dart';
import 'app/providers.dart';
import 'core/design_system/qchat_theme.dart';
import 'core/design_system/components.dart';
import 'features/auth/auth_screen.dart';
import 'features/chats/home_screen.dart';
import 'features/chats/chat_screen.dart';
import 'features/chats/media_screen.dart';
import 'features/contacts/friends_screen.dart';
import 'features/groups/group_screen.dart';
import 'features/moments/moments_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/calls/call_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: QChatApp()));
}

class QChatApp extends ConsumerStatefulWidget {
  const QChatApp({super.key});
  @override
  ConsumerState<QChatApp> createState() => _QChatAppState();
}

class _QChatAppState extends ConsumerState<QChatApp> {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, s) => const AuthScreen()),
        GoRoute(path: '/home', builder: (_, s) => const HomeScreen()),
        GoRoute(
          path: '/chat/:id',
          builder: (_, s) => ChatScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/friends',
          builder: (_, s) => FriendsScreen(query: s.uri.queryParameters['q']),
        ),
        GoRoute(path: '/groups/new', builder: (_, s) => const GroupScreen()),
        GoRoute(path: '/moments', builder: (_, s) => const MomentsScreen()),
        GoRoute(path: '/profile', builder: (_, s) => const ProfileScreen()),
        GoRoute(path: '/qr', builder: (_, s) => const ProfileScreen(qr: true)),
        GoRoute(path: '/scan', builder: (_, s) => const ScanScreen()),
        GoRoute(path: '/settings', builder: (_, s) => const SettingsScreen()),
        GoRoute(
          path: '/sessions',
          builder: (_, s) => const DataListScreen(kind: 'sessions'),
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, s) => const DataListScreen(kind: 'favorites'),
        ),
        GoRoute(
          path: '/media/:id',
          builder: (_, s) => MediaScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/call/:id',
          builder: (_, s) => CallScreen(
            conversationId: s.pathParameters['id']!,
            video: s.uri.queryParameters['video'] == 'true',
          ),
        ),
        GoRoute(
          path: '/about',
          builder: (c, s) => QChatPage(
            title: 'QChat',
            leading: QChatIconButton(
              'back',
              label: 'Back',
              onTap: () => c.pop(),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'QChat 0.1.0\n\nIndependent messaging software. Messages are stored on your QChat server. This release does not provide end-to-end encryption.\n\nMedia, camera and microphone access require your explicit permission.',
              ),
            ),
          ),
        ),
      ],
    );
    restore();
  }

  Future<void> restore() async {
    try {
      if (await ref.read(clientProvider).restore() && mounted) {
        router.go('/home');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final prefs = ref.watch(preferencesProvider);
    return MaterialApp.router(
      title: 'QChat',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Material(type: MaterialType.transparency, child: child),
      theme: qchatTheme(prefs.dark),
      locale: Locale(prefs.locale),
      supportedLocales: const [Locale('en'), Locale('vi'), Locale('zh')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
