// // services/auth_service.dart
// import 'package:firebase_auth/firebase_auth.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Future<void> sendOtp(String phoneNumber, Function(String) codeSent) async {
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) {},
//       verificationFailed: (FirebaseAuthException e) {
//         throw e.message ?? "Verification failed.";
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         codeSent(verificationId);
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {},
//     );
//   }
//
//   Future<UserCredential> verifyOtp(String verificationId, String otp) async {
//     PhoneAuthCredential credential = PhoneAuthProvider.credential(
//       verificationId: verificationId,
//       smsCode: otp,
//     );
//     return await _auth.signInWithCredential(credential);
//   }
// }
