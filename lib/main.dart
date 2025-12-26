import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/socket_service.dart';
import 'screens/username_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _getServerUrl() {
    if (kIsWeb) {
      // For web browser
      return 'http://localhost:3000';
    } else {
      // For Android emulator use 10.0.2.2
      // For iOS simulator use localhost
      // For physical device use your computer's IP
      return 'http://10.0.2.2:3000';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final socketService = SocketService();
        socketService.connect(_getServerUrl());
        return socketService;
      },
      child: MaterialApp(
        title: 'Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const UsernameScreen(),
      ),
    );
  }
}
