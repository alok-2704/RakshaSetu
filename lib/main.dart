
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';

const Color rakshaNavy = Color(0xFF173B70);
const Color rakshaRed = Color(0xFFD92D35);
const Color rakshaBackground = Color(0xFFF7F8FA);

// Light mode is the default. Users can switch modes in their profile.
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel androidNotificationChannel =
    AndroidNotificationChannel(
  'rakshasetu_alerts',
  'RakshaSetu Alerts',
  description: 'Notifications about emergency alerts and response updates.',
  importance: Importance.high,
);

// Prevent repeated initialization when the authentication stream rebuilds.
final Set<String> _initializedUsers = <String>{};

Future<void> loadUserTheme() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final theme = doc.data()?['theme']?.toString().toLowerCase();

    themeNotifier.value =
        theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  } catch (_) {
    themeNotifier.value = ThemeMode.light;
  }
}

Future<void> saveUserTheme(bool dark) async {
  final user = FirebaseAuth.instance.currentUser;

  themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;

  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {'theme': dark ? 'dark' : 'light'},
      SetOptions(merge: true),
    );
  } catch (_) {
    // The local theme still changes if saving the preference fails.
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> setupNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const settings = InitializationSettings(
    android: androidSettings,
  );

  await localNotifications.initialize(settings);

  final androidPlugin = localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
    androidNotificationChannel,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    await localNotifications.show(
      message.hashCode,
      notification.title ?? 'RakshaSetu',
      notification.body ?? 'You have a new notification.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidNotificationChannel.id,
          androidNotificationChannel.name,
          channelDescription: androidNotificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  });
}

Future<void> _saveDeviceToken(String uid) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();

    if (token == null || token.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  } catch (_) {
    // FCM token registration can be retried later.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Groq API key from .env
  await dotenv.load(fileName: ".env");

  // Existing Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  await setupNotifications();

  runApp(const RakshaSetuApp());
}


ThemeData _lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: rakshaNavy,
      brightness: Brightness.light,
      primary: rakshaNavy,
      error: rakshaRed,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: rakshaBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: rakshaBackground,
      foregroundColor: Color(0xFF172B4D),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE6E9EF),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD9DEE7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD9DEE7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: rakshaNavy,
          width: 1.5,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: rakshaNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      elevation: 0,
      height: 68,
    ),
  );
}

ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7EA7E8),
      brightness: Brightness.dark,
      primary: const Color(0xFF9DBEF0),
      error: const Color(0xFFFF747B),
      surface: const Color(0xFF171B23),
    ),
    scaffoldBackgroundColor: const Color(0xFF101319),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF101319),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF171B23),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFF303744),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF202631),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF394352),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF9DBEF0),
          width: 1.5,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF294C7C),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      elevation: 0,
      height: 68,
    ),
  );
}

class RakshaSetuApp extends StatelessWidget {
  const RakshaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'RakshaSetu',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: mode,
          routes: {
            '/login': (_) => const LoginScreen(),
            '/student': (_) => const HomeScreen(),
            '/admin': (_) => const AdminDashboard(
                  adminDepartment: 'Security',
                ),
          },
          home: const _AuthenticationGate(),
        );
      },
    );
  }
}

class _AuthenticationGate extends StatelessWidget {
  const _AuthenticationGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError ||
                !profileSnapshot.hasData ||
                !profileSnapshot.data!.exists) {
              return _ProfileErrorScreen(
                onSignOut: () async {
                  await FirebaseAuth.instance.signOut();
                },
              );
            }

            final profile = profileSnapshot.data!.data()!;
            final role = (profile['role'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final department = (profile['department'] ?? '')
                .toString()
                .trim();

            if (!_initializedUsers.contains(user.uid)) {
              _initializedUsers.add(user.uid);
              _initializeUser(user.uid);
            }

            if (role == 'student') {
              return const HomeScreen();
            }

            if (role == 'admin') {
              if (department.isEmpty) {
                return const _ProfileErrorScreen();
              }

              return AdminDashboard(
                adminDepartment: department,
              );
            }

            if (role == 'organization_admin') {
              return const AdminDashboard(
                adminDepartment: 'All',
              );
            }

            return _ProfileErrorScreen(
              onSignOut: () async {
                await FirebaseAuth.instance.signOut();
              },
            );
          },
        );
      },
    );
  }

  static Future<void> _initializeUser(String uid) async {
    await loadUserTheme();
    await _saveDeviceToken(uid);
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  final Future<void> Function()? onSignOut;

  const _ProfileErrorScreen({
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 46,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account profile unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account could not be matched with an authorized '
                  'RakshaSetu profile. Please contact your organization '
                  'administrator.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onSignOut == null
                      ? null
                      : () async {
                          await onSignOut!();
                        },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
