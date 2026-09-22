import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TaskDev')),
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What needs to be done now?', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text('Flutter client foundation is ready. The shared task pool comes next.'),
      const Spacer(),
      Text('API: ${AppConfig.apiBaseUrl}', style: Theme.of(context).textTheme.bodySmall),
    ]))),
  );
}
