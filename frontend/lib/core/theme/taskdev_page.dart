import 'package:flutter/material.dart';

import 'masse_dev_theme.dart';

class TaskDevPage extends StatelessWidget {
  const TaskDevPage({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.floatingActionButton,
    this.maxWidth = MasseDevTokens.pageMaxWidth,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: title == null
            ? null
            : AppBar(
                title: Row(
                  children: [
                    const _BrandMark(),
                    const SizedBox(width: MasseDevTokens.spaceSm),
                    Flexible(
                      child: Text(
                        title!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                actions: actions,
              ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'TaskDev by MasseDev',
        image: true,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MasseDevTokens.brandPurple, MasseDevTokens.brandBlue],
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'T',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      );
}
