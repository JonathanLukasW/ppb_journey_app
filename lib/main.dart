import 'package:flutter/material.dart';
import 'package:ppb_journey_app/screens/events/event_list_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pendukung Event Trip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal, 
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins', 
      ),

      home: const EventListScreen(),
    );
  }
}