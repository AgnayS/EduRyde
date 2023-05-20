// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
/// 
class DefaultFirebaseOptions {
  
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC0QvbIKZ1Ib3YhPqsXZUpyjVXD6evhBxY',
    appId: '1:168247508765:web:9c5553ef6fabb93e38ebf4',
    messagingSenderId: '168247508765',
    projectId: 'eduryde',
    authDomain: 'eduryde.firebaseapp.com',
    storageBucket: 'eduryde.appspot.com',
    measurementId: 'G-NL47S8RR44',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBaJt7zrKMTZSYJz6vD2CTOA-8HdZ3ghII',
    appId: '1:168247508765:android:85850294d429dee738ebf4',
    messagingSenderId: '168247508765',
    projectId: 'eduryde',
    storageBucket: 'eduryde.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAlBX90zh6ErB0mW-FvNDEC3xZ8cKFNdK4',
    appId: '1:168247508765:ios:2df5ab1351ffa28a38ebf4',
    messagingSenderId: '168247508765',
    projectId: 'eduryde',
    storageBucket: 'eduryde.appspot.com',
    iosClientId: '168247508765-tcoltq95g1oahsg25428mmqv3aj16j8a.apps.googleusercontent.com',
    iosBundleId: 'com.example.eduryde',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAlBX90zh6ErB0mW-FvNDEC3xZ8cKFNdK4',
    appId: '1:168247508765:ios:2df5ab1351ffa28a38ebf4',
    messagingSenderId: '168247508765',
    projectId: 'eduryde',
    storageBucket: 'eduryde.appspot.com',
    iosClientId: '168247508765-tcoltq95g1oahsg25428mmqv3aj16j8a.apps.googleusercontent.com',
    iosBundleId: 'com.example.eduryde',
  );
}
