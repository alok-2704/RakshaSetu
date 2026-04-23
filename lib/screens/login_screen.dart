import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart';
import '../main.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _emailCtrl =
      TextEditingController();
  final _passCtrl =
      TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  String? _error;
  String? selectedRole;

  final roles = [
    'Student',
    'Fire',
    'Medical',
    'Security',
  ];
  

  Future<void> _login() async {
    if (selectedRole == null) {
      setState(() {
        _error = 'Choose role first';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email:
            _emailCtrl.text.trim(),
        password:
            _passCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      final doc =
          await FirebaseFirestore
              .instance
              .collection('users')
              .doc(uid)
              .get();

      if (!doc.exists) {
        throw Exception('No user');
      }

      final data = doc.data()!;
      final role = data['role']
          .toString()
          .toLowerCase();

      final department =
          data['department']
              .toString();

      if (!mounted) return;

      if (selectedRole ==
          'Student') {
        if (role != 'student') {
          throw Exception(
              'Wrong role');
        }
        await loadUserTheme();

        Navigator.pushReplacementNamed(
          context,
          '/student',
        );
      } else {
        if (role != 'admin' ||
            department
                    .toLowerCase() !=
                selectedRole!
                    .toLowerCase()) {
          throw Exception(
              'Wrong role');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminDashboard(
              adminDepartment:
                  department,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error =
            'Login failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'fire':
        return Colors.redAccent;
      case 'medical':
        return Colors.lightBlueAccent;
      case 'security':
        return Colors.greenAccent;
      default:
        return Colors.orange;
    }
  }

  IconData roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'fire':
        return Icons
            .local_fire_department;
      case 'medical':
        return Icons
            .medical_services;
      case 'security':
        return Icons.shield;
      default:
        return Icons.school;
    }
  }

  InputDecoration box(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
          cs.surfaceVariant.withOpacity(.5),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
                18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget roleCard(
    BuildContext context,
    String role,
  ) {
    final selected =
        selectedRole == role;

    final color =
        roleColor(role);

    return InkWell(
      onTap: () {
        setState(() {
          selectedRole = role;
          _error = null;
        });
      },
      borderRadius:
          BorderRadius.circular(
              20),
      child: Container(
        decoration:
            BoxDecoration(
          color: selected
              ? color.withOpacity(
                  .14)
              : Theme.of(context)
                  .colorScheme
                  .surface,
          borderRadius:
              BorderRadius.circular(
                  20),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(.2),
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              roleIcon(role),
              color: color,
              size: 28,
            ),
            const SizedBox(
                height: 8),
            Text(
              role,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,
      body: Center(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
                  18),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 500,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(
                      26),
              decoration:
                  BoxDecoration(
                color: cs.surface,
                borderRadius:
                    BorderRadius
                        .circular(
                            28),
                border:
                    Border.all(
                  color: cs.outline
                      .withOpacity(
                          .2),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor:
                        cs.primary,
                    child: const Icon(
                      Icons.shield,
                      color:
                          Colors.white,
                      size: 34,
                    ),
                  ),

                  const SizedBox(
                      height: 18),

                  Text(
                    'RakshaSetu Emergency',
                    style: Theme.of(
                            context)
                        .textTheme
                        .headlineSmall,
                  ),

                  const SizedBox(
                      height: 8),

                  Text(
                    'Choose access role',
                    style: TextStyle(
                      color: cs
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(
                      height: 22),

                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount:
                        2,
                    crossAxisSpacing:
                        12,
                    mainAxisSpacing:
                        12,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    childAspectRatio:
                        1.45,
                    children: roles
                        .map((r) =>
                            roleCard(
                              context,
                              r,
                            ))
                        .toList(),
                  ),

                  if (selectedRole !=
                      null) ...[
                    const SizedBox(
                        height: 24),

                    TextField(
                      controller:
                          _emailCtrl,
                      decoration:
                          box(
                        context,
                        'Email',
                        Icons.email,
                      ),
                    ),

                    const SizedBox(
                        height: 14),

                    TextField(
                      controller:
                          _passCtrl,
                      obscureText:
                          _hidePassword,
                      decoration:
                          box(
                        context,
                        'Password',
                        Icons.lock,
                      ).copyWith(
                        suffixIcon:
                            IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed:
                              () {
                            setState(() {
                              _hidePassword =
                                  !_hidePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child:
                          ElevatedButton(
                        onPressed:
                            _loading
                                ? null
                                : _login,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              roleColor(
                            selectedRole!,
                          ),
                          foregroundColor:
                              Colors.white,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Login ',
                              ),
                      ),
                    ),
                  ],

                  if (_error !=
                      null) ...[
                    const SizedBox(
                        height: 14),
                    Text(
                      _error!,
                      style:
                          const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
 
  }
}