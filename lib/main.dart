import 'package:admin/LocalAndWebObjects.dart';
import 'package:admin/map.dart';
import 'package:flutter/material.dart';

import 'DebugOptions.dart';
import 'LOGIN SIGNUP/SignIn.dart';
import 'SharedPreferenceHelper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<SharedPreferenceHelper> _preferencesFuture;

  @override
  void initState() {
    super.initState();
    _preferencesFuture = SharedPreferenceHelper.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferenceHelper>(
      future: _preferencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SignIn();
        } else if (snapshot.hasError) {
          return SignIn();
        } else if (snapshot.hasData) {
          if (snapshot.data?.getMap("signin") == null) {
            return SignIn();
          } else {
            return const googleMap();
          }
        } else {
          return SignIn();
        }
      },
    );
  }
}
