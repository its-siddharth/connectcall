import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/users_provider.dart';
import 'providers/theme_provider.dart';
import 'services/calling_service.dart';
import 'services/user_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/call/audio_call_screen.dart';
import 'screens/call/video_call_screen.dart';
import 'models/user_model.dart';
import 'models/call_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register our navigator key with Zego BEFORE runApp so that the
  // invitation service can push the incoming-call overlay on any device.
  ZegoUIKitPrebuiltCallInvitationService()
      .setNavigatorKey(AuthProvider.navigatorKey);

  final storage = await StorageService.getInstance();

  UserService.instance.init(storage);
  CallingService.instance.init(storage);

  final authProvider = AuthProvider();
  await authProvider.init(storage);

  final themeProvider = ThemeProvider();
  themeProvider.init(storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: CallingService.instance),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
      ],
      child: const ConnectCallApp(),
    ),
  );
}

class ConnectCallApp extends StatelessWidget {
  const ConnectCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'ConnectCall',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Zego uses this navigatorKey to push the incoming-call overlay on top
      // of whatever route is active. AuthProvider.navigatorKey is the single
      // GlobalKey we share across both MaterialApp and Zego.
      navigatorKey: AuthProvider.navigatorKey,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/user-profile':
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(builder: (_) => UserProfileScreen(user: user));
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case '/audio-call':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AudioCallScreen(
            call: args['call'] as CallModel,
            currentUser: args['currentUser'] as UserModel,
            remoteUser: args['remoteUser'] as UserModel,
          ),
        );
      case '/video-call':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            call: args['call'] as CallModel,
            currentUser: args['currentUser'] as UserModel,
            remoteUser: args['remoteUser'] as UserModel,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Page not found: ${settings.name}')),
          ),
        );
    }
  }
}
