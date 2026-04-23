import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference alerts =
      FirebaseFirestore.instance.collection('alerts');

  Future<void> saveUserProfile(
    String uid,
    String name,
    String role,
  ) async {
    await users.doc(uid).set({
      'uid': uid,
      'name': name,
      'role': role,
      'fcmToken': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendSOS(
    String uid,
    String building,
    String floor,
    String type,
  ) async {
    await alerts.add({
      'senderId': uid,
      'locationDetail': {
        'building': building,
        'floor': floor,
      },
      'type': type,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> get activeAlerts {
    return alerts
        .where('status', isEqualTo: 'pending')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots();
  }

  Future<void> acceptAlert(String alertId) async {
    await alerts.doc(alertId).update({
      'status': 'accepted',
      'acceptedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveAlert(String alertId) async {
    await alerts.doc(alertId).update({
      'status': 'resolved',
      'resolvedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getUserDetails(
    String uid,
  ) {
    return users.doc(uid).get();
  }
}