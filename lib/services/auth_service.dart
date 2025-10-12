import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bank_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      FirebaseFirestore.instance.collection('users');

  Future<UserCredential> signInWithGoogle() async {
    // Ensure account chooser shows by disconnecting any prior session
    try { await _googleSignIn.disconnect(); } catch (_) {}
    try { await _googleSignIn.signOut(); } catch (_) {}
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('sign_in_cancelled');
    }
    // Guard: if this email already has password but not Google, block linking via direct Google sign-in
    final email = googleUser.email;
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    final hasPassword = methods.contains('password');
    final hasGoogle = methods.contains('google.com');
    if (hasPassword && !hasGoogle) {
      try { await _googleSignIn.disconnect(); await _googleSignIn.signOut(); } catch (_) {}
      throw Exception('use_email_password_then_link_google');
    }

    // Obtain Google tokens
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google [UserCredential]
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;

    // Validate after sign-in; delete user immediately if policy fails to avoid ghost accounts
    if (user != null) {
      try {
        // Must be pre-registered in our users collection (by email or uid)
        final userDoc = await _usersCol.doc(user.uid).get();
        if (!userDoc.exists) {
          // Try lookup by email mapping
          final existingByEmail = await _usersCol.where('email', isEqualTo: user.email).limit(1).get();
          if (existingByEmail.docs.isEmpty) {
            // Not registered: remove auth user to avoid ghost
            await user.delete();
            await _auth.signOut();
            try { await _googleSignIn.disconnect(); await _googleSignIn.signOut(); } catch (_) {}
            throw Exception('not_registered');
          }
        }

        // Must exist in bank directory
        final bank = await BankService.instance.findByEmail(user.email ?? '');
        if (bank == null) {
          await user.delete();
          await _auth.signOut();
          try { await _googleSignIn.disconnect(); await _googleSignIn.signOut(); } catch (_) {}
          throw Exception('bank_email_not_registered');
        }

        await _upsertUser(user);
      } catch (e) {
        rethrow;
      }
    }
    return cred;
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    // Create auth user first so Firestore rules (auth required) permit bankUsers read
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('email_already_exists');
      }
      rethrow;
    }
    final user = cred.user;
    if (user != null) {
      try {
        // Validate against bankUsers after auth is established
        final bank = await BankService.instance.findByEmail(email);
        if (bank == null) {
          // Cleanup the just-created auth user per policy
          await user.delete();
          await _auth.signOut();
          throw Exception('bank_email_not_registered');
        }
        await user.updateDisplayName(fullName);
        await _upsertUser(user, extra: {
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'provider': 'password',
        });
      } on FirebaseException catch (e) {
        // If permission denied or other, cleanup account and surface error
        try { await user.delete(); } catch (_) {}
        await _auth.signOut();
        if (e.code == 'permission-denied') {
          throw Exception('bank_directory_unavailable');
        }
        rethrow;
      }
    }
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Optionally refresh Firestore basic fields
    final user = cred.user;
    if (user != null) {
      // Enforce: only signin after register (must have an existing users doc)
      final doc = await _usersCol.doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('not_registered');
      }
      await _upsertUser(user);
    }
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}

extension _AuthServiceFirestore on AuthService {
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      FirebaseFirestore.instance.collection('users');

  Future<void> _upsertUser(User user, {Map<String, dynamic>? extra}) async {
    final data = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (extra != null) {
      data.addAll(extra);
    }

    // Merge: don't overwrite createdAt if exists
    await _usersCol.doc(user.uid).set(data, SetOptions(merge: true));
  }
}

