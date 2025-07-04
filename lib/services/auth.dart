// ignore_for_file: use_build_context_synchronously

import '/constants/widgets.dart';
import '/screens/auth/email_verify_screen.dart';
import '/screens/auth/phone_otp_screen.dart';
import '/screens/location_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();
  User? currentUser = FirebaseAuth.instance.currentUser;
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference categories =
      FirebaseFirestore.instance.collection('categories');
  CollectionReference products =
      FirebaseFirestore.instance.collection('products');
  CollectionReference messages =
      FirebaseFirestore.instance.collection('messages');

  Future<void> getAdminCredentialPhoneNumber(BuildContext context, user) async {
    final QuerySnapshot userDataQuery =
        await users.where('uid', isEqualTo: user!.uid).get();
    List<DocumentSnapshot> wasUserPresentInDatabase = userDataQuery.docs;
    if (wasUserPresentInDatabase.isNotEmpty) {
      // Navigator.pushReplacementNamed(context, LocationScreen.screenId);
    } else {
      await registerWithPhoneNumber(user, context);
    }
  }

  Future<void> registerWithPhoneNumber(user, context) async {
    final uid = user!.uid;
    final mobileNo = user!.phoneNumber;
    final email = user!.email;
    // Navigator.pushReplacementNamed(context, LocationScreen.screenId);
    return users.doc(uid).set({
      'uid': uid,
      'mobile': mobileNo,
      'email': email,
      'name': '',
      'address': ''
    }).then((value) {
      if (kDebugMode) {
        print('user added successfully');
      }
      // ignore: invalid_return_type_for_catch_error, avoid_print
    }).catchError((error) => print("Failed to add user: $error"));
  }

  Future<void> verifyPhoneNumber(BuildContext context, number) async {
    loadingDialogBox(context, 'Please wait');

    // ignore: prefer_function_declarations_over_variables
    final PhoneVerificationCompleted verificationCompleted =
        (phoneAuthCredential) async {
      await _firebaseAuth.signInWithCredential(phoneAuthCredential);
    };

    // ignore: prefer_function_declarations_over_variables
    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException e) {
      if (e.code == 'invalid-phone-number') {
        Navigator.pop(context);
        wrongDetailsAlertBox(
            'The phone number that you entered is invalid. Please enter a valid phone number.',
            context);
      } else {
        Navigator.pop(context);
        wrongDetailsAlertBox(e.code, context);
      }
    };
    final PhoneCodeSent phoneCodeSent =
        ((verificationId, forceResendingToken) async {
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (builder) => PhoneOTPScreen(
                    phoneNumber: number,
                    verificationIdFinal: verificationId,
                  )));
    });
    try {
      _firebaseAuth.verifyPhoneNumber(
          phoneNumber: number,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          timeout: const Duration(seconds: 60),
          codeSent: phoneCodeSent,
          codeAutoRetrievalTimeout: (String verificationId) {
            print(verificationId);
          });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> signInwithPhoneNumber(
      String verificationId, String smsCode, BuildContext context) async {
    try {
      loadingDialogBox(context, 'Please Wait');
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);

      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      Navigator.pop(context);
      if (userCredential != null) {
        getAdminCredentialPhoneNumber(context, userCredential.user);
      } else {
        wrongDetailsAlertBox('Login Failed, Please retry again.', context);
      }
    } catch (e) {
      Navigator.pop(context);
      wrongDetailsAlertBox(
          'The details you entered is not matching with our database. Please validate details again, before proceeding. ',
          context);
    }
  }

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);

          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            customSnackBar(
              context: context,
              content: 'The account already exists with a different credential',
            );
          } else if (e.code == 'invalid-credential') {
            customSnackBar(
              context: context,
              content: 'Error occurred while accessing credentials. Try again.',
            );
          }
        } catch (e) {
          customSnackBar(
            context: context,
            content: 'Error occurred using Google Sign In. Try again.',
          );
        }
      }
    }

    return user;
  }

  Future<DocumentSnapshot> getAdminCredentialEmailAndPassword(
      {required BuildContext context,
      required String email,
      String? firstName,
      String? lastName,
      required String password,
      required bool isLoginUser}) async {
    DocumentSnapshot result = await users.doc(email).get();
    if (kDebugMode) {
      print(result);
    }
    try {
      if (isLoginUser) {
        print('loggin user');
        signInWithEmail(context, email, password);
      } else {
        if (result.exists) {
          customSnackBar(
              context: context,
              content: 'An account already exists with this email');
        } else {
          registerWithEmail(context, email, password, firstName!, lastName!);
        }
      }
    } catch (e) {
      customSnackBar(context: context, content: e.toString());
    }
    return result;
  }

  signInWithEmail(BuildContext context, String email, String password) async {
    try {
      loadingDialogBox(context, 'Validating details');
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (kDebugMode) {
        print(credential);
      }
      Navigator.pop(context);
      if (credential.user!.uid != null) {
        Navigator.pushReplacementNamed(context, 'home_screen');
      } else {
        customSnackBar(
            context: context, content: 'Please check with your credentials');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'user-not-found') {
        customSnackBar(
            context: context, content: 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        customSnackBar(
            context: context,
            content: 'Wrong password provided for that user.');
      }
    }
  }

  void registerWithEmail(BuildContext context, String email, String password,
      String firstName, String lastName) async {
    try {
      loadingDialogBox(context, 'Validating details');

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return users.doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': "$firstName $lastName",
        'email': email,
        'mobile': '',
        'address': ''
      }).then((value) async {
        await credential.user!.sendEmailVerification().then((value) {
          Navigator.pushReplacementNamed(context, EmailVerifyScreen.screenId);
        });

        customSnackBar(context: context, content: 'Registered successfully');
      }).catchError((onError) {
        if (kDebugMode) {
          print(onError);
        }
        customSnackBar(
            context: context,
            content:
                'Failed to add user to database, please try again $onError');
      });
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'weak-password') {
        customSnackBar(
            context: context, content: 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        customSnackBar(
            context: context,
            content: 'The account already exists for that email.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      customSnackBar(
          context: context, content: 'Error occured: ${e.toString()}');
    }
  }
}
