import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> _upsertFirestoreUser({
    required User user,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('userss__id')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': now.toIso8601String(),
        'pass': password,
      }, SetOptions(merge: true));
      debugPrint('User document written to Firestore for uid=${user.uid}');
    } catch (e) {
      debugPrint('Error writing user to Firestore: $e');
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name to be used as chat username
      await credential.user?.updateDisplayName(username);
      await credential.user?.reload();

      // Also store basic user info in Cloud Firestore (no raw password)
      final user = credential.user;
      if (user != null) {
        await _upsertFirestoreUser(
          user: user,
          username: username,
          email: email,
          password: password,
        );
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth signUp error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unknown signUp error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure Firestore document exists / is updated on login too
      final user = credential.user;
      if (user != null) {
        // Prefer existing displayName; if missing, derive from email and save it
        String username = user.displayName?.trim() ?? '';

        if (username.isEmpty) {
          final effectiveEmail = (user.email ?? email).trim();
          if (effectiveEmail.isNotEmpty && effectiveEmail.contains('@')) {
            username = effectiveEmail.split('@').first;
          }

          if (username.isNotEmpty) {
            try {
              await user.updateDisplayName(username);
              await user.reload();
              debugPrint(
                'displayName was empty on signIn; set to derived username=$username',
              );
            } catch (e) {
              debugPrint('Error updating displayName on signIn: $e');
            }
          }
        }

        if (username.isNotEmpty) {
          await _upsertFirestoreUser(
            user: user,
            username: username,
            email: user.email ?? email,
            password: password,
          );
        } else {
          debugPrint(
            'Warning: Could not determine username on signIn; skipping Firestore upsert.',
          );
        }
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth signIn error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unknown signIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('FirebaseAuth signOut error: $e');
      rethrow;
    }
  }
}

