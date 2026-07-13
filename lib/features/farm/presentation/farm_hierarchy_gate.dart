import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_controller.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmHierarchyScope extends InheritedWidget {
  const FarmHierarchyScope({
    required this.snapshot,
    required super.child,
    super.key,
  });

  final FarmHierarchySnapshot snapshot;

  static FarmHierarchySnapshot? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FarmHierarchyScope>()
      ?.snapshot;

  @override
  bool updateShouldNotify(FarmHierarchyScope oldWidget) =>
      oldWidget.snapshot != snapshot;
}

class FarmHierarchyGate extends StatefulWidget {
  const FarmHierarchyGate({
    required this.farmId,
    required this.child,
    this.repository,
    super.key,
  });

  final String farmId;
  final Widget child;
  final FarmHierarchyRepository? repository;

  @override
  State<FarmHierarchyGate> createState() => _FarmHierarchyGateState();
}

class _FarmHierarchyGateState extends State<FarmHierarchyGate> {
  FarmHierarchyController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final store = AppServicesScope.maybeOf(context)?.cacheStore;
    final repository = widget.repository ??
        DefaultFarmHierarchyRepository(
          SupabaseFarmHierarchyDataSource(Supabase.instance.client),
          store == null
              ? MemoryFarmHierarchyCache()
              : PersistentFarmHierarchyCache(store),
        );
    _controller = FarmHierarchyController(repository)..load(widget.farmId);
  }

  @override
  void didUpdateWidget(FarmHierarchyGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farmId != widget.farmId) {
      _controller?.load(widget.farmId);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(
        body: PaperBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.state) {
        FarmHierarchyReady(:final snapshot) => FarmHierarchyScope(
            snapshot: snapshot,
            child: widget.child,
          ),
        FarmHierarchyFailure() => _HierarchyFailure(
            onRetry: () => controller.load(widget.farmId),
          ),
        _ => const Scaffold(
            body: PaperBackground(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      },
    );
  }
}

class _HierarchyFailure extends StatelessWidget {
  const _HierarchyFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PaperBackground(
          child: Center(
            child: WahatCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Unable to load farm data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your connection and farm access, then try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
}
