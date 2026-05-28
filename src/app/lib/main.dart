import 'package:flutter/material.dart';
import 'package:gesture/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gesture/routing/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GestureApp());
}

class GestureApp extends StatelessWidget {
  const GestureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final materialTheme = MaterialTheme(textTheme);

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        theme: materialTheme.light(),
        darkTheme: materialTheme.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

}
