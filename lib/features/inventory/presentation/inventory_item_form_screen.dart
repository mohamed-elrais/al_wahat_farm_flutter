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

/// Create/edit form for an inventory item. When [itemId] is null it creates;
/// otherwise it edits the existing item (quantity is never edited here — the
/// ledger owns quantity changes).
class InventoryItemFormScreen extends StatefulWidget {
  const InventoryItemFormScreen({this.itemId, this.controller, super.key});

  final String? itemId;
  final InventoryController? controller;

  @override
  State<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState extends State<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _minimumStock = TextEditingController();
  final _initialQuantity = TextEditingController();
  final List<(TextEditingController, TextEditingController)> _attributes =
      <(TextEditingController, TextEditingController)>[];
  InventoryController? _controller;
  bool _owns = false;
  bool _prefilled = false;
  String? _categoryId;
  InventoryUnit _unit = InventoryUnit.piece;

  bool get _isEdit => widget.itemId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final injected = widget.controller;
      if (injected != null) {
        _controller = injected;
        if (injected.status == InventoryStatus.idle) injected.load();
      } else {
        _controller = buildInventoryController(context);
        _owns = true;
        _controller?.load();
      }
      _controller?.addListener(_prefillFromItem);
    }
    _prefillFromItem();
  }

  void _prefillFromItem() {
    if (_prefilled || !_isEdit) return;
    final item = _controller?.itemById(widget.itemId!);
    if (item == null) return;
    _prefilled = true;
    _name.text = item.name;
    _description.text = item.description ?? '';
    _minimumStock.text =
        item.minimumStock == null ? '' : formatQuantity(item.minimumStock!);
    _categoryId = item.categoryId;
    _unit = item.unit;
    for (final entry in item.attributes.entries) {
      _attributes.add((
        TextEditingController(text: entry.key),
        TextEditingController(text: '${entry.value}'),
      ));
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_prefillFromItem);
    if (_owns) _controller?.dispose();
    _name.dispose();
    _description.dispose();
    _minimumStock.dispose();
    _initialQuantity.dispose();
    for (final pair in _attributes) {
      pair.$1.dispose();
      pair.$2.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canManage = OperationalContextScope.maybeOf(context)
            ?.selectedMembership
            .role
            .canManageInventory ??
        false;
    // The app shell owns the safe areas; a nested Scaffold/SafeArea would
    // double the top inset below the shell's top bar.
    return PaperBackground(
      child: Material(
        type: MaterialType.transparency,
        child: controller == null || !canManage
            ? Center(child: Text(context.l10n.inventoryLoadFailed))
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) => _form(context, controller),
              ),
      ),
    );
  }

  Widget _form(BuildContext context, InventoryController controller) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('inventory-item-form'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: <Widget>[
          Row(
            children: <Widget>[
              WahatBackButton(
                tooltip: l10n.commonBack,
                onPressed: () => context.go(
                  _isEdit
                      ? '/more/inventory/item/${widget.itemId}'
                      : '/more/inventory',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isEdit ? l10n.inventoryEditItem : l10n.inventoryAddItem,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: const Key('inventory-name-field'),
                  controller: _name,
                  decoration:
                      InputDecoration(labelText: l10n.inventoryItemName),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.inventoryItemNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('inventory-category-field'),
                  value: _categoryId,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: l10n.inventoryCategoryField),
                  items: controller.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.localizedLabel(l10n)),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? l10n.inventoryCategoryField : null,
                  onChanged: controller.isBusy
                      ? null
                      : (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InventoryUnit>(
                  key: const Key('inventory-unit-field'),
                  value: _unit,
                  decoration:
                      InputDecoration(labelText: l10n.inventoryUnitField),
                  items: InventoryUnit.values
                      .map(
                        (unit) => DropdownMenuItem<InventoryUnit>(
                          value: unit,
                          child: Text(unit.localizedLabel(l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.isBusy || _isEdit
                      ? null
                      : (value) => setState(() => _unit = value ?? _unit),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.inventoryDescriptionField,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('inventory-minimum-field'),
                  controller: _minimumStock,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.inventoryMinimumStockField,
                  ),
                  validator: _optionalNonNegative(l10n),
                ),
                if (!_isEdit) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('inventory-initial-field'),
                    controller: _initialQuantity,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.inventoryInitialQuantityField,
                    ),
                    validator: _optionalNonNegative(l10n),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.inventoryAttributesTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                for (var i = 0; i < _attributes.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _attributes[i].$1,
                            decoration: InputDecoration(
                              labelText: l10n.inventoryAttributeName,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _attributes[i].$2,
                            decoration: InputDecoration(
                              labelText: l10n.inventoryAttributeValue,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.commonCancel,
                          onPressed: () => setState(() {
                            final removed = _attributes.removeAt(i);
                            removed.$1.dispose();
                            removed.$2.dispose();
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  key: const Key('inventory-add-attribute'),
                  onPressed: () => setState(() {
                    _attributes.add(
                      (TextEditingController(), TextEditingController()),
                    );
                  }),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.inventoryAddAttribute),
                ),
              ],
            ),
          ),
          if (controller.message != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              controller.message!.call(l10n),
              key: const Key('inventory-form-message'),
              style: const TextStyle(
                color: AppColors.issue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('inventory-save-button'),
            onPressed: controller.isBusy ? null : () => _submit(controller),
            icon: controller.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.inventory_2_outlined),
            label: Text(
              controller.isBusy ? l10n.inventorySaving : l10n.inventorySaveItem,
            ),
          ),
        ],
      ),
    );
  }

  String? Function(String?) _optionalNonNegative(AppLocalizations l10n) =>
      (value) {
        if (value == null || value.trim().isEmpty) return null;
        final parsed = double.tryParse(value.trim());
        if (parsed == null || parsed < 0) return l10n.inventoryInvalidNumber;
        return null;
      };

  Map<String, Object?> _collectAttributes() => <String, Object?>{
        for (final pair in _attributes)
          if (pair.$1.text.trim().isNotEmpty)
            pair.$1.text.trim():
                num.tryParse(pair.$2.text.trim()) ?? pair.$2.text.trim(),
      };

  Future<void> _submit(InventoryController controller) async {
    if (!_formKey.currentState!.validate()) return;
    final offline =
        AppServicesScope.maybeOf(context)?.connectivity.isOffline ?? false;
    if (offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.inventoryOffline)),
      );
      return;
    }
    final operational = OperationalContextScope.maybeOf(context);
    final farmId = operational?.selectedMembership.farm.id;
    if (farmId == null || _categoryId == null) return;

    final minimum = _minimumStock.text.trim().isEmpty
        ? null
        : double.parse(_minimumStock.text.trim());
    String? resultId;
    if (_isEdit) {
      resultId = await controller.updateItem(
        widget.itemId!,
        name: _name.text.trim(),
        categoryId: _categoryId,
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        clearDescription: _description.text.trim().isEmpty,
        minimumStock: minimum,
        clearMinimumStock: minimum == null,
        attributes: _collectAttributes(),
      );
    } else {
      resultId = await controller.createItem(
        InventoryItemDraft(
          farmId: farmId,
          categoryId: _categoryId!,
          name: _name.text,
          unit: _unit,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          minimumStock: minimum,
          attributes: _collectAttributes(),
          initialQuantity: _initialQuantity.text.trim().isEmpty
              ? 0
              : double.parse(_initialQuantity.text.trim()),
        ),
      );
    }
    if (!mounted) return;
    if (resultId != null) {
      context.go('/more/inventory/item/$resultId');
    }
  }
}
