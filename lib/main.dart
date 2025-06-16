import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/splash_screen.dart';

void main() async {
  // supabase setup
  await Supabase.initialize(
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhubGJtdGtwenhqZXF6cXp1aWZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY2MzUyODMsImV4cCI6MjA2MjIxMTI4M30.36uElwy5C75sZ-fHXPCKp2AKiVhTAaB5Ycp25-rLdKA",
    url: "https://xnlbmtkpzxjeqzqzuiff.supabase.co",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
