import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/inventory/data/inventory_repository.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds an [InventoryController] from the ambient scopes. Screens own their
/// controller (the inventory lives under More and is not always mounted).
InventoryController? buildInventoryController(BuildContext context) {
  final operational = OperationalContextScope.maybeOf(context);
  if (operational == null) return null;
  final services = AppServicesScope.maybeOf(context);
  final base = SupabaseInventoryRepository(Supabase.instance.client);
  return InventoryController(
    repository: services == null
        ? base
        : CachingInventoryRepository(inner: base, store: services.cacheStore),
    farmId: operational.selectedMembership.farm.id,
  );
}

String formatQuantity(double value) {
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({this.controller, super.key});

  final InventoryController? controller;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  InventoryController? _controller;
  bool _owns = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      if (injected.status == InventoryStatus.idle) injected.load();
      return;
    }
    _controller = buildInventoryController(context);
    _owns = true;
    _controller?.load();
  }

  @override
  void dispose() {
    if (_owns) _controller?.dispose();
    super.dispose();
  }

  bool get _canManage =>
      OperationalContextScope.maybeOf(context)
          ?.selectedMembership
          .role
          .canManageInventory ??
      false;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // No Scaffold/SafeArea here: the app shell already provides the top
    // inset and overlays the floating bottom navigation (extendBody), so the
    // list keeps 110 bottom padding and the add action lives in the header.
    return PaperBackground(
      child: Material(
        type: MaterialType.transparency,
        child: controller == null
            ? Center(child: Text(context.l10n.inventoryLoadFailed))
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) => _body(context, controller),
              ),
      ),
    );
  }

  Widget _body(BuildContext context, InventoryController controller) {
    final l10n = context.l10n;
    final items = controller.items;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        key: const Key('inventory-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              WahatBackButton(
                tooltip: l10n.commonBack,
                onPressed: () => context.go('/more'),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Eyebrow(l10n.inventoryEyebrow),
                    Text(
                      l10n.inventoryTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              if (_canManage)
                FilledButton.icon(
                  key: const Key('inventory-add-item'),
                  onPressed: () => context.go('/more/inventory/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.inventoryAddItem),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('inventory-search'),
            onChanged: controller.setSearch,
            decoration: InputDecoration(
              hintText: l10n.inventorySearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ChoiceChip(
                  key: const Key('inventory-filter-all'),
                  label: Text(l10n.inventoryAllCategories),
                  selected: controller.categoryFilter == null,
                  onSelected: (_) => controller.setCategoryFilter(null),
                ),
                for (final category in controller.categories) ...<Widget>[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    key: Key('inventory-filter-${category.code}'),
                    label: Text(category.localizedLabel(l10n)),
                    selected: controller.categoryFilter == category.id,
                    onSelected: (_) =>
                        controller.setCategoryFilter(category.id),
                  ),
                ],
              ],
            ),
          ),
          if (controller.lowStockCount > 0) ...<Widget>[
            const SizedBox(height: 10),
            DecoratedBox(
              key: const Key('inventory-low-stock-banner'),
              decoration: BoxDecoration(
                color: AppColors.issue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.issue.withOpacity(0.4)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.issue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.inventoryLowStockCount(controller.lowStockCount),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (controller.status == InventoryStatus.loading && items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.status == InventoryStatus.failure &&
              items.isEmpty)
            WahatCard(
              child: Column(
                children: <Widget>[
                  const Icon(Icons.sync_problem_outlined,
                      size: 38, color: AppColors.green),
                  const SizedBox(height: 10),
                  Text(l10n.inventoryLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.load,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            )
          else if (items.isEmpty)
            WahatCard(
              child: Column(
                children: <Widget>[
                  const Icon(Icons.inventory_2_outlined,
                      size: 38, color: AppColors.green),
                  const SizedBox(height: 10),
                  Text(l10n.inventoryEmptyTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    _canManage
                        ? l10n.inventoryEmptyManager
                        : l10n.inventoryEmptyWorker,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final item in items) ...<Widget>[
              _ItemTile(
                item: item,
                category: controller.categoryById(item.categoryId),
                onTap: () => context.go('/more/inventory/item/${item.id}'),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.category,
    required this.onTap,
  });

  final InventoryItem item;
  final InventoryCategory? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WahatCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('inventory-item-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.softGreen,
                foregroundColor: AppColors.green,
                child: Icon(_categoryIcon(category?.code)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${category?.localizedLabel(l10n) ?? ''} · '
                      '${formatQuantity(item.quantity)} '
                      '${item.unit.localizedLabel(l10n)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (item.isLowStock)
                DecoratedBox(
                  key: Key('inventory-low-${item.id}'),
                  decoration: BoxDecoration(
                    color: AppColors.issue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                    border:
                        Border.all(color: AppColors.issue.withOpacity(0.35)),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      l10n.inventoryLowStock,
                      style: const TextStyle(
                        color: AppColors.issue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String? code) => switch (code) {
      'pipe' => Icons.horizontal_rule,
      'pipe_joint' => Icons.call_split,
      'fertilizer' => Icons.compost_outlined,
      'dripper' => Icons.water_drop_outlined,
      'insecticide' => Icons.pest_control_outlined,
      'herbicide' => Icons.grass_outlined,
      'fungicide' => Icons.coronavirus_outlined,
      'tool' => Icons.handyman_outlined,
      _ => Icons.inventory_2_outlined,
    };
