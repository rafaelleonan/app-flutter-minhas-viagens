import 'package:flutter/material.dart';
import 'package:app_minhas_viagens/views/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();

  runApp(MaterialApp(
    title: "Minhas viagens",
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      // Firebase app is already initialized, you can ignore this error.
      // However, if there is any other error, you should rethrow it.
    } else {
      rethrow;
    }
  }
}