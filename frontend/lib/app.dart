import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/theme/masse_dev_theme.dart';
import 'features/auth/session_gate.dart';

class TaskDevApp extends StatelessWidget {
  const TaskDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    return MaterialApp(
      title: 'TaskDev',
      debugShowCheckedModeBanner: false,
      theme: TaskDevTheme.light,
      home: SessionGate(api: api),
    );
  }
}
