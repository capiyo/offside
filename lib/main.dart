import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const OffsideApp());
}

class OffsideApp extends StatelessWidget {
  const OffsideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offside',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}