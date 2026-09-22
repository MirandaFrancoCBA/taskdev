import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_screen.dart';

class TaskDevApp extends StatelessWidget {
  const TaskDevApp({super.key});
  static final GoRouter _router = GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())]);
  @override
  Widget build(BuildContext context) => MaterialApp.router(title: 'TaskDev', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true), routerConfig: _router);
}
