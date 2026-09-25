import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/root_shell.dart';

void main() {
  runApp(const YmentorApp());
}

class YmentorApp extends StatelessWidget {
  const YmentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Ymentor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RootShell(),
      ),
    );
  }
}
