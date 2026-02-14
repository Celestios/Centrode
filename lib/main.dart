import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/src/rust/frb_generated.dart'; // Core FFI
import 'package:mycelium/src/rust/bridge/api.dart';     // AppHandle

// Import your screens
import 'features/graph/ui/graph_screen.dart';
import 'features/graph/state/graph_controller.dart';

Future<void> main() async {
  // 1. Initialize the low-level FFI bridge
  await RustLib.init();

  // 2. Initialize the Rust App State (The "Backend")
  // Note: We use a local file path for the DB.
  // In a real app, use 'path_provider' to get a valid documents directory.
  final appHandle = await AppHandle.newInstance(storagePath: "mycelium.db");

  runApp(
    MultiProvider(
      providers: [
        // 3. Inject the Controller, passing the Rust handle to it
        ChangeNotifierProvider<GraphController>(
          create: (_) => GraphController(appHandle),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mycelium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      // 4. Set the Home Screen
      home: const GraphScreen(),
    );
  }
}
