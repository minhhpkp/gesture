import 'package:gesture/routing/routes.dart';
import 'package:gesture/ui/connect/connect_screen.dart';
import 'package:gesture/ui/prejoin/prejoin_screen.dart';
import 'package:gesture/ui/room/room_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: Routes.connect,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: Routes.connect,
      builder: (context, state) => ConnectScreen(),
    ),
    GoRoute(
      path: Routes.prejoin,
      builder: (context, state) => PrejoinScreen(),
    ),
    GoRoute(
      path: Routes.room,
      builder: (context, state) => RoomScreen(),
    ),
  ],
);
