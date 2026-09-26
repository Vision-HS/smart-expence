import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../database/database_helper.dart';

class AuthService {
  static final AuthService instance = AuthService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService._init();

  User? get currentUser => _auth.currentUser;

  /// Check if user has an active session (either Firebase or local SQLite)
  Future<bool> isUserAuthenticated() async {
    final localLoggedIn = await DatabaseHelper.instance.isUserLoggedIn();
    if (_auth.currentUser != null || localLoggedIn) {
      return true;
    }
    return false;
  }

  /// 1-Tap Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in prompt
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : googleUser.displayName ?? 'User';
        final email = user.email ?? googleUser.email;
        final photo = user.photoURL ?? googleUser.photoUrl;

        await DatabaseHelper.instance.saveUserProfile(
          displayName: name,
          email: email,
          photoUrl: photo,
          authProvider: 'Google',
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Send Phone OTP via Firebase SMS gateway
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;
          if (user != null) {
            await DatabaseHelper.instance.saveUserProfile(
              displayName: user.displayName ?? 'User',
              phone: user.phoneNumber ?? phoneNumber,
              authProvider: 'Phone',
            );
          }
        } catch (_) {}
        onVerificationCompleted(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
    );
  }

  /// Verify 6-digit OTP code and sign in
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
    String? preferredName,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    final phone = user?.phoneNumber ?? phoneNumber;
    final name = (preferredName != null && preferredName.trim().isNotEmpty)
        ? preferredName.trim()
        : 'Smart User';

    await DatabaseHelper.instance.saveUserProfile(
      displayName: name,
      phone: phone,
      authProvider: 'Phone',
    );

    return userCredential;
  }

  /// Sign out and clear session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    await DatabaseHelper.instance.logoutUser();
  }
}
