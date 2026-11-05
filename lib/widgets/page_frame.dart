import 'package:flutter/material.dart';

import '../ui/organic.dart';

/// Grundrahmen jeder Seite: Kiesel-Hintergrund, schmale Spalte, scrollbar.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.children,
    this.title,
    this.actions,
    this.showBack = false,
    this.seed = 3,
  });

  final List<Widget> children;
  final Widget? title;
  final List<Widget>? actions;
  final bool showBack;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PebbleBackground(
        seed: seed,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                automaticallyImplyLeading: showBack,
                title: title,
                actions: actions,
                backgroundColor: Colors.transparent,
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
