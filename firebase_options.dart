import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('This platform is not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4pVDieUq9Kq5aCIoYtTSXxcfgX2LUEX8',           // 👈 Firebase Console se copy karein
    appId: '1:651643699950:android:f96407ab784bd6a89829ff',             // 👈 Firebase Console se copy karein
    messagingSenderId: '651643699950', // 👈 Firebase Console se copy karein
    projectId: 'smartbuild-68507',     // 👈 Firebase Console se copy karein
    storageBucket: 'smartbuild-68507.firebasestorage.app', // 👈 Firebase Console se copy karein
  );
}