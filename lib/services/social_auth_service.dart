import 'package:flutter/foundation.dart';
import 'package:flutter_activity_app/models/auth_credentials.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
/* import 'package:sign_in_with_apple/sign_in_with_apple.dart'; */
import 'dart:io';

class SocialAuthService {
  // Google Sign In
  Future<SocialLoginRequest?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      print('🔍 Attempting Google sign-in...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        print('❌ User cancelled Google sign-in');
        return null;
      }

      print('✅ Google user signed in: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('🔑 Access Token: ${googleAuth.accessToken}');
      print('🔐 ID Token: ${googleAuth.idToken}');

      // Handle null accessToken by providing a default empty string
      final accessToken = googleAuth.accessToken ?? '';
      final idToken = googleAuth.idToken;

      final request = SocialLoginRequest(
        provider: SocialLoginProvider.google,
        accessToken: accessToken,
        idToken: idToken,
        userData: {
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        },
      );

      print('📦 SocialLoginRequest created: $request');
      return request;
    } catch (e) {
      print('❗ Google sign in error: $e');
      return null;
    }
  }
  
  // Facebook Sign In
  Future<SocialLoginRequest?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      
      if (result.status != LoginStatus.success) return null;
      
      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();
      
      return SocialLoginRequest(
        provider: SocialLoginProvider.facebook,
        accessToken: accessToken.token,
        userData: userData,
      );
    } catch (e) {
      debugPrint('Facebook sign in error: $e');
      return null;
    }
  }
  
  // Apple Sign In
  Future<SocialLoginRequest?> signInWithApple() async {
    if (!Platform.isIOS) {
      debugPrint('Apple Sign In is only available on iOS');
      return null;
    }
    
    try {
      /* final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      return SocialLoginRequest(
        provider: SocialLoginProvider.apple,
        idToken: credential.identityToken,
        userData: {
          'email': credential.email,
          'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim(),
          'userIdentifier': credential.userIdentifier,
        },
      ); */
      return null;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return null;
    }
  }
}
