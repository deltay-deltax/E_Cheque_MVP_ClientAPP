import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/routes/app_routes.dart';
import 'view_model/splash_view_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'services/key.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  final fromFile = AppSecrets.geminiApiKey.trim();
  final fromEnv = const String.fromEnvironment('GEMINI_API_KEY');
  final apiKey = fromFile.isNotEmpty ? fromFile : fromEnv;

  if (apiKey.isNotEmpty) {
    Gemini.init(
      apiKey: apiKey,
      enableDebugging: true, // optional for debugging
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SplashViewModel())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'E-Cheque MVP',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
