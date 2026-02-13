import 'package:admin/map.dart';
import 'package:admin/pdrCalibration.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'DATABASE/DATABASEMODEL/markerModel.dart';
import 'LOGIN SIGNUP/SignIn.dart';
import 'SharedPreferenceHelper.dart';
import 'UserLog.dart';
import 'mainScreen.dart';


wsocket ws = wsocket("com.iwayplus.rni");
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var appDocDir = await getApplicationDocumentsDirectory();
  print("appDocDir:${appDocDir.path}");
  Hive.init(appDocDir.path);
  Hive.registerAdapter(MarkerModelAdapter());
  await Hive.openBox<MarkerModel>('markerBox');
  await cleanOldMarkers();
  runApp(MyApp());
}

Future<void> cleanOldMarkers() async {
  final box = Hive.box<MarkerModel>('markerBox');
  final now = DateTime.now();
  final keysToDelete = box.values
      .where((marker) => now.difference(marker.savedAt).inDays > 7)
      .map((marker) => marker.markerId)
      .toList();
  print("keys tht has to be deleted:${keysToDelete}");
  for (String key in keysToDelete) {
    await box.delete(key);
  }
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
    print("preferencesFuture:${_preferencesFuture}");
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: PDRCalibrationScreen(),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return FutureBuilder<SharedPreferenceHelper>(
  //     future: _preferencesFuture,
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return SignIn();
  //       } else if (snapshot.hasError) {
  //         return SignIn();
  //       } else if (snapshot.hasData) {
  //         print("data has been stored:${snapshot.data?.getMap("signin")}");
  //         if (snapshot.data?.getMap("signin") == null) {
  //           return SignIn();
  //         } else {
  //           return BeaconFingerprintScreen();
  //         }
  //       } else {
  //         return SignIn();
  //       }
  //     },
  //   );
  // }
}
