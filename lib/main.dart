import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/frb_generated.dart'; // Core FFI
import 'package:mycelium/src/rust/bridge/api.dart'; // AppHandle
import 'package:provider/provider.dart';

// Import your screens
import 'features/graph/ui/graph_screen.dart';
import 'features/graph/state/theme_controller.dart';
import 'features/graph/state/graph_data_controller.dart';
import 'features/graph/state/graph_ui_controller.dart';

// Import the central logger
import 'core/logging/log_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the low-level FFI bridge FIRST
  //    Rust library must be loaded into memory before LogManager can call FFI functions
  await RustLib.init();

  // 2. Initialize Central Logger (now safe to call FFI)
  await LogManager().init();
  final log = Logger('BootSequence');
  log.info('LogManager online. Booting Mycelium...');
  log.info('Rust FFI Loaded.');

  // 3. Initialize the Rust App State
  final appHandle = await AppHandle.newInstance(storagePath: "mycelium.db");
  log.info('SurrealDB Engine connected.');

  runApp(
    MultiProvider(
      providers: [
        // 1. Independent Theme Domain
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(appHandle)..loadThemes(),
        ),
        // 2. Core Graph Data Domain (Depends on Theme for styling nodes)
        ChangeNotifierProxyProvider<ThemeController, GraphDataController>(
          create: (context) =>
              GraphDataController(appHandle, context.read<ThemeController>()),
          update: (context, theme, previous) =>
              previous ?? GraphDataController(appHandle, theme),
        ),
        // 3. Volatile UI Domain (Depends on Graph Data)
        ChangeNotifierProxyProvider<GraphDataController, GraphUIController>(
          create: (context) =>
              GraphUIController(context.read<GraphDataController>()),
          update: (context, data, previous) =>
              previous ?? GraphUIController(data),
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
