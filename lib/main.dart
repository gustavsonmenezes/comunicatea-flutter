import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const ComunicaTeaApp());
}

class ComunicaTeaApp extends StatelessWidget {
  const ComunicaTeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMUNICA-TEA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
