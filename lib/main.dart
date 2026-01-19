import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';


void suppressFirebaseWarnings() {
  // Only suppress in release mode
  
    FlutterError.onError = (FlutterErrorDetails details) {
      if (!details.toString().contains('permission-denied')) {
        FlutterError.presentError(details);
      }
    };
  
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // Call this before initialization
    suppressFirebaseWarnings();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    runApp(MyApp());
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Todo App',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}

