// THIS FILE IS GENERATED — run `flutterfire configure` to populate it.
// See: https://firebase.flutter.dev/docs/cli
//
// Replace this file with the output of:
//   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWLQL2PnIu5YiSRO6slNeQEYGiiFoYi4M',
    appId: '1:999608961860:android:91f87f9d0f098ff246a511',
    messagingSenderId: '999608961860',
    projectId: 'khudmati-1089b',
    storageBucket: 'khudmati-1089b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_IOS_APP_ID',
    messagingSenderId: '999608961860',
    projectId: 'khudmati-1089b',
    storageBucket: 'khudmati-1089b.firebasestorage.app',
  );
}
