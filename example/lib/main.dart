import 'package:flutter/material.dart';
import 'package:mapkit_lite_extension/mapkit_lite_extension.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: AspectRatio(aspectRatio: 16 / 9, child: ExtendedMapWidget())));
  }
}
