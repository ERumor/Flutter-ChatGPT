import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_gpt/screens/chat_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(
    const Duration(seconds: 3),
  );
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A67E)),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
