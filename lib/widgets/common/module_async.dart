import 'package:flutter/material.dart';
import 'package:ventos_pos/theme/ventos_colors.dart';
import 'package:ventos_pos/widgets/ventos/ventos.dart';

typedef ModuleLoader<T> = Future<T> Function();

class ModuleAsyncBody<T> extends StatefulWidget {
  const ModuleAsyncBody({
    super.key,
    required this.loader,
    required this.builder,
    this.reloadKey = 0,
  });

  final ModuleLoader<T> loader;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;
  final int reloadKey;

  @override
  State<ModuleAsyncBody<T>> createState() => _ModuleAsyncBodyState<T>();
}

class _ModuleAsyncBodyState<T> extends State<ModuleAsyncBody<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  void didUpdateWidget(ModuleAsyncBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadKey != oldWidget.reloadKey) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: VentosColors.destructive)),
                  const SizedBox(height: 12),
                  VentosButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) return const SizedBox.shrink();
        return widget.builder(context, snap.data as T, _reload);
      },
    );
  }
}
