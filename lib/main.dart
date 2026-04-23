import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/login_screen.dart';
import 'screens/panic_screen.dart';
import 'screens/admin_dashboard.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

Future<void> loadUserTheme() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    themeNotifier.value = ThemeMode.dark;
    return;
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    themeNotifier.value = ThemeMode.dark;
    return;
  }

  final data = doc.data()!;
  final saved =
      (data['theme'] ?? 'dark').toString();

  themeNotifier.value =
      saved == 'light'
          ? ThemeMode.light
          : ThemeMode.dark;
}

Future<void> saveUserTheme(
  bool dark,
) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({
    'theme': dark ? 'dark' : 'light',
  });

  themeNotifier.value =
      dark ? ThemeMode.dark : ThemeMode.light;
}
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel =
    AndroidNotificationChannel(
  'rakshasetu_alerts',
  'RakshaSetu Alerts',
  description: 'Emergency notifications',
  importance: Importance.max,
);

Future<void> setupNotifications() async {
  await FirebaseMessaging.instance
      .requestPermission();

  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
    ),
  );

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) {
      final title =
          message.notification?.title ??
              'Alert';

      final body =
          message.notification?.body ?? '';

      localNotifications.show(
        0,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rakshasetu_alerts',
            'RakshaSetu Alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    },
  );
}
Future<void> saveDeviceToken() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final token =
      await FirebaseMessaging.instance.getToken();

  if (token == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({
    'fcmToken': token,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupNotifications();

  await loadUserTheme();

  runApp(const RakshaSetuApp());
}

class RakshaSetuApp extends StatelessWidget{
 const RakshaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner:
              false,
          title: 'RakshaSetu',

          themeMode: mode,

          theme: ThemeData(
            useMaterial3: true,
            brightness:
                Brightness.light,
            colorSchemeSeed:
                Colors.orange,
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness:
                Brightness.dark,
            colorSchemeSeed:
                Colors.orange,
          ),

          routes: {
            '/login': (context) =>
                const LoginScreen(),
            '/student': (context) =>
                const PanicScreen(),
            '/admin': (context) =>
                const AdminDashboard(
                  adminDepartment:
                      'Security',
                ),
          },

          home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, authSnap) {
    if (authSnap.connectionState ==
        ConnectionState.waiting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authSnap.data;

    if (user == null) {
      return const LoginScreen();
    }
    saveDeviceToken();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final data =
            userSnap.data!.data()
                as Map<String, dynamic>?;

        if (data == null) {
          return const LoginScreen();
        }

        final role =
            (data['role'] ?? '')
                .toString()
                .toLowerCase();

        final department =
            (data['department'] ??
                    'Security')
                .toString();

        if (role == 'admin') {
          return AdminDashboard(
            adminDepartment:
                department,
          );
        }

        return const PanicScreen();
      },
    );
  },
),
        );
      },
    );
  }
}