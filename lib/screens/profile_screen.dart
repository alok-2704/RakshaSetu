import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user found'),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!.data()
                  as Map<String, dynamic>? ??
              {};

          final name =
              (data['name'] ?? 'User')
                  .toString();

          final email =
              (data['email'] ??
                      user.email ??
                      'No Email')
                  .toString();

          final role =
              (data['role'] ?? 'Unknown')
                  .toString();

          final department =
              (data['department'] ??
                      'General')
                  .toString();

          final organization =
              (data['organizationId'] ??
                      'org_demo')
                  .toString();

          final status =
              data['isActive'] == false
                  ? 'Inactive'
                  : 'Active';

          return Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                      18),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 720,
                ),
                child: Column(
                  children: [
                    card(
                      context,
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor:
                                cs.primary,
                            child: Text(
                              name[0]
                                  .toUpperCase(),
                              style:
                                  const TextStyle(
                                color: Colors
                                    .white,
                                fontSize:
                                    28,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 14),
                          Text(
                            name,
                            style: Theme.of(
                                    context)
                                .textTheme
                                .headlineSmall,
                          ),
                          const SizedBox(
                              height: 4),
                          Text(
                            email,
                            style:
                                TextStyle(
                              color: cs
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(
                              height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              chip(
                                  context,
                                  role,
                                  Icons.badge),
                              chip(
                                  context,
                                  department,
                                  Icons.business),
                              chip(
                                  context,
                                  status,
                                  Icons.verified_user),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    card(
                      context,
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Account Details',
                            style: Theme.of(
                                    context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(
                              height: 14),
                          rowItem(
                              'UID',
                              user.uid),
                          rowItem(
                              'Role',
                              role),
                          rowItem(
                              'Department',
                              department),
                          rowItem(
                              'Organization',
                              organization),
                          rowItem(
                              'Status',
                              status),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    card(
                      context,
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color:
                                cs.primary,
                          ),
                          const SizedBox(
                              width: 12),
                          const Expanded(
                            child: Text(
                              'Dark / Light Theme',
                            ),
                          ),
                          Switch(
                           value: themeNotifier.value == ThemeMode.dark,
                            onChanged: (value) async {
                            await saveUserTheme(value);
                           },
                         ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        height: 18),

                    SizedBox(
                      width: double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            () async {
                          await FirebaseAuth
                              .instance
                              .signOut();
                              themeNotifier.value = ThemeMode.dark;

                          if (!context
                              .mounted) {
                            return;
                          }

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) =>
                                false,
                          );
                        },
                        icon: const Icon(
                            Icons.logout),
                        label:
                            const Text(
                                'Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget card(
    BuildContext context,
    Widget child,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              cs.outline.withOpacity(.2),
        ),
      ),
      child: child,
    );
  }

  Widget chip(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
            cs.primary.withOpacity(.12),
        borderRadius:
            BorderRadius.circular(
                30),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget rowItem(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}