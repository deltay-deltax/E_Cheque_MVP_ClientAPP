import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bank_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('sign_in_cancelled');
    }
    // Gate: only allow if email is present in bankUsers
    final bank = await BankService.instance.findByEmail(googleUser.email);
    if (bank == null) {
      // Ensure sign-out from the transient Google session
      try { await _googleSignIn.signOut(); } catch (_) {}
      throw Exception('bank_email_not_registered');
    }
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google [UserCredential]
    final cred = await _auth.signInWithCredential(credential);

    // Persist to Firestore 'users' collection (upsert)
    final user = cred.user;
    if (user != null) {
      await _upsertUser(user);
    }

    return cred;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    // Gate by bankUsers email
    final bank = await BankService.instance.findByEmail(email);
    if (bank == null) {
      throw Exception('bank_email_not_registered');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(fullName);
      await _upsertUser(user, extra: {
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'provider': 'password',
      });
    }
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Gate by bankUsers email
    final bank = await BankService.instance.findByEmail(email);
    if (bank == null) {
      throw Exception('bank_email_not_registered');
    }
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Optionally refresh Firestore basic fields
    final user = cred.user;
    if (user != null) {
      await _upsertUser(user);
    }
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
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

