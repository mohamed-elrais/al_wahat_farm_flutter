import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryItemScreen extends StatefulWidget {
  const InventoryItemScreen({
    required this.itemId,
    this.controller,
    super.key,
  });

  final String itemId;
  final InventoryController? controller;

  @override
  State<InventoryItemScreen> createState() => _InventoryItemScreenState();
}

class _InventoryItemScreenState extends State<InventoryItemScreen> {
  InventoryController? _controller;
  bool _owns = false;
  List<InventoryTransaction>? _transactions;
  Object? _transactionsError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      if (injected.status == InventoryStatus.idle) injected.load();
    } else {
      _controller = buildInventoryController(context);
      _owns = true;
      _controller?.load();
    }
    _controller?.addListener(_maybeLoadTransactions);
    _maybeLoadTransactions();
  }

  bool get _canManage =>
      OperationalContextScope.maybeOf(context)
          ?.selectedMembership
          .role
          .canManageInventory ??
      false;

  Future<void> _maybeLoadTransactions() async {
    if (!_canManage || _transactions != null) return;
    final controller = _controller;
    if (controller == null) return;
    try {
      final rows = await controller.loadTransactions(widget.itemId);
      if (mounted) setState(() => _transactions = rows);
    } catch (error) {
      if (mounted) setState(() => _transactionsError = error);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_maybeLoadTransactions);
    if (_owns) _controller?.dispose();
    super.dispose();
  }

  bool _requireOnline() {
    final offline =
        AppServicesScope.maybeOf(context)?.connectivity.isOffline ?? false;
    if (offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.inventoryOffline)),
      );
    }
    return !offline;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // The app shell owns the safe areas; a nested Scaffold/SafeArea would
    // double the top inset below the shell's top bar.
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
    final item = controller.itemById(widget.itemId);
    if (item == null) {
      return controller.status == InventoryStatus.loading ||
              controller.status == InventoryStatus.idle
          ? const Center(child: CircularProgressIndicator())
          : Center(child: Text(l10n.inventoryLoadFailed));
    }
    final category = controller.categoryById(item.categoryId);
    return ListView(
      key: const Key('inventory-item-detail'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            WahatBackButton(
              tooltip: l10n.commonBack,
              onPressed: () => context.go('/more/inventory'),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow(category?.localizedLabel(l10n) ?? ''),
                  Text(item.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            if (_canManage)
              IconButton(
                key: const Key('inventory-edit-item'),
                tooltip: l10n.inventoryEditItem,
                onPressed: () =>
                    context.go('/more/inventory/item/${item.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 8),
        WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Stat(
                      label: l10n.inventoryQuantityLabel,
                      value:
                          '${formatQuantity(item.quantity)} ${item.unit.localizedLabel(l10n)}',
                      highlight: item.isLowStock,
                    ),
                  ),
                  if (item.minimumStock != null)
                    Expanded(
                      child: _Stat(
                        label: l10n.inventoryMinimumLabel,
                        value:
                            '${formatQuantity(item.minimumStock!)} ${item.unit.localizedLabel(l10n)}',
                      ),
                    ),
                ],
              ),
              if (item.isLowStock) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  l10n.inventoryLowStock,
                  key: const Key('inventory-detail-low-stock'),
                  style: const TextStyle(
                    color: AppColors.issue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (item.description != null &&
                  item.description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(item.description!),
              ],
            ],
          ),
        ),
        if (item.attributes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.inventoryAttributesTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final entry in item.attributes.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text('${entry.value}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (_canManage) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                key: const Key('inventory-add-stock'),
                onPressed: controller.isBusy
                    ? null
                    : () => _recordMovement(
                          controller,
                          item,
                          InventoryTransactionType.addition,
                        ),
                icon: const Icon(Icons.add),
                label: Text(l10n.inventoryAddStock),
              ),
              OutlinedButton.icon(
                key: const Key('inventory-adjust'),
                onPressed: controller.isBusy
                    ? null
                    : () => _recordMovement(
                          controller,
                          item,
                          InventoryTransactionType.adjustment,
                        ),
                icon: const Icon(Icons.tune),
                label: Text(l10n.inventoryAdjust),
              ),
            ],
          ),
        ],
        if (controller.message != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            controller.message!.call(l10n),
            key: const Key('inventory-item-message'),
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (_canManage) ...<Widget>[
          const SizedBox(height: 16),
          Text(l10n.inventoryHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_transactionsError != null)
            Text(l10n.inventoryLoadFailed)
          else if (_transactions == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_transactions!.isEmpty)
            Text(l10n.inventoryHistoryEmpty)
          else
            WahatCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (final txn in _transactions!)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        txn.quantityDelta >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: txn.quantityDelta >= 0
                            ? AppColors.green
                            : AppColors.issue,
                      ),
                      title: Text(txn.type.localizedLabel(l10n)),
                      subtitle: Text(
                        '${txn.note ?? ''}\n'
                        '${txn.createdAt.toLocal().toString().substring(0, 16)}',
                      ),
                      isThreeLine: txn.note != null,
                      trailing: Text(
                        '${txn.quantityDelta > 0 ? '+' : ''}'
                        '${formatQuantity(txn.quantityDelta)}\n'
                        '= ${formatQuantity(txn.resultingQuantity)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _recordMovement(
    InventoryController controller,
    InventoryItem item,
    InventoryTransactionType type,
  ) async {
    if (!_requireOnline()) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              type == InventoryTransactionType.addition
                  ? l10n.inventoryAddStock
                  : l10n.inventoryAdjust,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('inventory-quantity-field'),
              controller: quantityController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.inventoryQuantityField,
                helperText: type == InventoryTransactionType.adjustment
                    ? l10n.inventoryAdjustHint
                    : null,
                suffixText: item.unit.localizedLabel(l10n),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: l10n.inventoryNoteField),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('inventory-record-button'),
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: Text(l10n.inventoryRecord),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    final quantity = double.tryParse(quantityController.text.trim());
    if (quantity == null || quantity == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.inventoryInvalidNumber)),
      );
      return;
    }
    await controller.recordTransaction(
      item.id,
      type: type,
      quantity: quantity,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );
    setState(() => _transactions = null);
    await _maybeLoadTransactions();
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: highlight ? AppColors.issue : null,
                ),
          ),
        ],
      );
}
