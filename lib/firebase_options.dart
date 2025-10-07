import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyAVwL778n-Cy2oifHI8L05_i0BWxcCMqw4',
  appId: '1:454098099389:android:7b6baa909bcce3d5eaabd4',
  messagingSenderId: '454098099389',
  projectId: 'ttcs-b1b7b',
  storageBucket: 'ttcs-b1b7b.firebasestorage.app',
);

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
              'Only Android is configured.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}