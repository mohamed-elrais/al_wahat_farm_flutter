import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _TargetMode { farm, sections, zones }

class ScheduleFormScreen extends StatefulWidget {
  const ScheduleFormScreen({
    this.controller,
    this.inventoryController,
    super.key,
  });

  final SchedulesController? controller;
  final InventoryController? inventoryController;

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _rate = TextEditingController();
  final _duration = TextEditingController();
  SchedulesController? _controller;
  InventoryController? _inventory;
  bool _ownsController = false;
  bool _ownsInventory = false;
  bool _membersRequested = false;

  OperationPlanType _type = OperationPlanType.irrigation;
  PlanScheduleType _recurrence = PlanScheduleType.daily;
  final Set<int> _weekdays = <int>{};
  DateTime _startsOn = DateTime.now();
  DateTime? _endsOn;
  TimeOfDay? _time;
  _TargetMode _targetMode = _TargetMode.farm;
  final Set<String> _sectionIds = <String>{};
  final Set<String> _zoneIds = <String>{};
  final Set<String> _assigneeIds = <String>{};
  String? _productItemId;
  RateBasis _basis = RateBasis.perFeddan;
  ApplicationMethod? _method;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = widget.controller ?? buildSchedulesController(context);
      _ownsController = widget.controller == null;
    }
    if (_inventory == null) {
      final injected = widget.inventoryController;
      _inventory = injected ?? buildInventoryController(context);
      _ownsInventory = injected == null;
      if (_inventory?.status == InventoryStatus.idle) _inventory?.load();
    }
    final workspace = TaskWorkspaceScope.maybeOf(context);
    if (!_membersRequested && workspace != null) {
      _membersRequested = true;
      workspace.loadAssignableMembers();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller?.dispose();
    if (_ownsInventory) _inventory?.dispose();
    _title.dispose();
    _description.dispose();
    _rate.dispose();
    _duration.dispose();
    super.dispose();
  }

  /// Inventory items whose category matches the selected operation type.
  List<InventoryItem> get _matchingProducts {
    final inventory = _inventory;
    if (inventory == null) return const <InventoryItem>[];
    final categoryIds = inventory.categories
        .where((category) => category.appliesToOperation == _type.wireValue)
        .map((category) => category.id)
        .toSet();
    return inventory.items
        .where((item) => categoryIds.contains(item.categoryId))
        .toList(growable: false);
  }

  InventoryItem? get _selectedProduct {
    if (_productItemId == null) return null;
    return _inventory?.itemById(_productItemId!);
  }

  /// Client-side preview of the per-run quantity for the current selection
  /// (display only — the backend computation is authoritative).
  double? get _previewQuantity {
    final rate = double.tryParse(_rate.text.trim());
    if (_productItemId == null || rate == null || rate <= 0) return null;
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    if (hierarchy == null) return null;
    int treeCount;
    switch (_targetMode) {
      case _TargetMode.farm:
        treeCount = hierarchy.trees.length;
      case _TargetMode.sections:
        treeCount = hierarchy.trees
            .where((tree) => _sectionIds.contains(tree.sectionId))
            .length;
      case _TargetMode.zones:
        treeCount = hierarchy.trees
            .where((tree) => _zoneIds.contains(tree.irrigationZoneId))
            .length;
    }
    return switch (_basis) {
      RateBasis.perFeddan => rate * treeCount / 60,
      RateBasis.perTree => rate * treeCount,
      RateBasis.absolute => rate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canManage = OperationalContextScope.maybeOf(context)
            ?.selectedMembership
            .role
            .canManageSchedules ??
        false;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: controller == null || !canManage
              ? Center(child: Text(context.l10n.schedulesLoadFailed))
              : ListenableBuilder(
                  listenable: Listenable.merge(
                    <Listenable?>[controller, _inventory],
                  ),
                  builder: (context, _) => _form(context, controller),
                ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, SchedulesController controller) {
    final l10n = context.l10n;
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final workspace = TaskWorkspaceScope.maybeOf(context);
    final members = workspace?.assignableMembers ?? const [];
    final preview = _previewQuantity;
    final product = _selectedProduct;
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('schedule-form'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: l10n.commonBack,
                onPressed: () => context.go('/more/schedules'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.scheduleNew,
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
                DropdownButtonFormField<OperationPlanType>(
                  key: const Key('schedule-type-field'),
                  value: _type,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: l10n.scheduleTypeField),
                  items: OperationPlanType.values
                      .map(
                        (type) => DropdownMenuItem<OperationPlanType>(
                          value: type,
                          child: Text(type.localizedLabel(l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.isBusy
                      ? null
                      : (value) => setState(() {
                            _type = value ?? _type;
                            _productItemId = null;
                          }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('schedule-title-field'),
                  controller: _title,
                  decoration:
                      InputDecoration(labelText: l10n.scheduleTitleField),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.scheduleTitleRequired
                      : null,
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.scheduleRecurrenceField,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PlanScheduleType.values
                      .map(
                        (type) => ChoiceChip(
                          key: Key('schedule-recurrence-${type.name}'),
                          label: Text(type.localizedLabel(l10n)),
                          selected: _recurrence == type,
                          onSelected: (_) => setState(() => _recurrence = type),
                        ),
                      )
                      .toList(growable: false),
                ),
                if (_recurrence == PlanScheduleType.weekly) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(l10n.scheduleWeekdaysField),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      for (var day = 1; day <= 7; day++)
                        FilterChip(
                          key: Key('schedule-weekday-$day'),
                          label: Text(weekdayShortLabel(context, day)),
                          selected: _weekdays.contains(day),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _weekdays.add(day);
                            } else {
                              _weekdays.remove(day);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      key: const Key('schedule-starts-on'),
                      onPressed: () => _pickDate(isEnd: false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                          '${l10n.scheduleStartsOn}: ${_formatDate(_startsOn)}'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('schedule-ends-on'),
                      onPressed: () => _pickDate(isEnd: true),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(_endsOn == null
                          ? l10n.scheduleEndsOn
                          : '${l10n.scheduleEndsOn}: ${_formatDate(_endsOn!)}'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('schedule-time'),
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(_time == null
                          ? l10n.scheduleTimeField
                          : _time!.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('schedule-duration-field'),
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.scheduleDurationField,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final minutes = int.tryParse(value.trim());
                    return minutes == null || minutes <= 0
                        ? l10n.inventoryInvalidNumber
                        : null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.scheduleTargetsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      key: const Key('schedule-target-farm'),
                      label: Text(l10n.scheduleTargetFarm),
                      selected: _targetMode == _TargetMode.farm,
                      onSelected: (_) =>
                          setState(() => _targetMode = _TargetMode.farm),
                    ),
                    ChoiceChip(
                      key: const Key('schedule-target-sections'),
                      label: Text(l10n.scheduleTargetSections),
                      selected: _targetMode == _TargetMode.sections,
                      onSelected: (_) =>
                          setState(() => _targetMode = _TargetMode.sections),
                    ),
                    ChoiceChip(
                      key: const Key('schedule-target-zones'),
                      label: Text(l10n.scheduleTargetZones),
                      selected: _targetMode == _TargetMode.zones,
                      onSelected: (_) =>
                          setState(() => _targetMode = _TargetMode.zones),
                    ),
                  ],
                ),
                if (_targetMode == _TargetMode.sections &&
                    hierarchy != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hierarchy.sections
                        .map(
                          (section) => FilterChip(
                            key: Key('schedule-section-${section.code}'),
                            label: Text(section.code),
                            selected: _sectionIds.contains(section.id),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _sectionIds.add(section.id);
                              } else {
                                _sectionIds.remove(section.id);
                              }
                            }),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (_targetMode == _TargetMode.zones &&
                    hierarchy != null) ...<Widget>[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      children: hierarchy.zones
                          .map(
                            (zone) => CheckboxListTile(
                              key: Key('schedule-zone-${zone.code}'),
                              dense: true,
                              title: Text(zone.code),
                              value: _zoneIds.contains(zone.id),
                              onChanged: (selected) => setState(() {
                                if (selected ?? false) {
                                  _zoneIds.add(zone.id);
                                } else {
                                  _zoneIds.remove(zone.id);
                                }
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_type.carriesProduct) ...<Widget>[
            const SizedBox(height: 10),
            WahatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(l10n.scheduleProductTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('schedule-product-field'),
                    value: _productItemId,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: l10n.scheduleProductField),
                    items: _matchingProducts
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              '${item.name} · ${formatQuantity(item.quantity)} '
                              '${item.unit.localizedLabel(l10n)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _productItemId = value),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          key: const Key('schedule-rate-field'),
                          controller: _rate,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.scheduleRateField,
                            suffixText:
                                product?.unit.localizedLabel(l10n) ?? '',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (_productItemId == null) return null;
                            final rate = double.tryParse((value ?? '').trim());
                            return rate == null || rate <= 0
                                ? l10n.inventoryInvalidNumber
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<RateBasis>(
                          key: const Key('schedule-basis-field'),
                          value: _basis,
                          decoration: InputDecoration(
                            labelText: l10n.scheduleBasisField,
                          ),
                          items: RateBasis.values
                              .map(
                                (basis) => DropdownMenuItem<RateBasis>(
                                  value: basis,
                                  child: Text(basis.localizedLabel(l10n)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) =>
                              setState(() => _basis = value ?? _basis),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ApplicationMethod>(
                    key: const Key('schedule-method-field'),
                    value: _method,
                    isExpanded: true,
                    decoration:
                        InputDecoration(labelText: l10n.scheduleMethodField),
                    items: ApplicationMethod.values
                        .map(
                          (method) => DropdownMenuItem<ApplicationMethod>(
                            value: method,
                            child: Text(method.localizedLabel(l10n)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _method = value),
                  ),
                  if (preview != null && product != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      l10n.schedulePerOccurrence(
                        formatQuantity(preview),
                        product.unit.localizedLabel(l10n),
                      ),
                      key: const Key('schedule-preview-quantity'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (preview > 0)
                      Text(
                        l10n.scheduleCoverage(
                          (product.quantity / preview).floor(),
                        ),
                        key: const Key('schedule-coverage'),
                        style: TextStyle(
                          color: product.quantity >= preview
                              ? AppColors.green
                              : AppColors.issue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (product.quantity < preview)
                      Text(
                        l10n.scheduleInsufficient,
                        key: const Key('schedule-insufficient'),
                        style: const TextStyle(color: AppColors.issue),
                      ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.scheduleAssigneesTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                if (members.isEmpty)
                  Text(l10n.noOperationalMembers)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members
                        .map(
                          (member) => FilterChip(
                            key: Key('schedule-assignee-${member.profileId}'),
                            label: Text(member.fullName),
                            selected: _assigneeIds.contains(member.profileId),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _assigneeIds.add(member.profileId);
                              } else {
                                _assigneeIds.remove(member.profileId);
                              }
                            }),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          if (controller.message != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              controller.message!.call(l10n),
              key: const Key('schedule-form-message'),
              style: const TextStyle(
                color: AppColors.issue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('schedule-create-button'),
            onPressed: controller.isBusy ? null : () => _submit(controller),
            icon: controller.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_repeat_outlined),
            label: Text(
              controller.isBusy ? l10n.scheduleSaving : l10n.scheduleCreate,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_endsOn ?? _startsOn) : _startsOn,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endsOn = selected;
      } else {
        _startsOn = selected;
      }
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (selected == null || !mounted) return;
    setState(() => _time = selected);
  }

  Future<void> _submit(SchedulesController controller) async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_recurrence == PlanScheduleType.weekly && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleWeekdaysRequired)),
      );
      return;
    }
    final operational = OperationalContextScope.maybeOf(context);
    final farmId = operational?.selectedMembership.farm.id;
    if (farmId == null) return;

    final targets = switch (_targetMode) {
      _TargetMode.farm => const <PlanTarget>[PlanTarget()],
      _TargetMode.sections => _sectionIds
          .map((id) => PlanTarget(sectionId: id))
          .toList(growable: false),
      _TargetMode.zones => _zoneIds
          .map((id) => PlanTarget(irrigationZoneId: id))
          .toList(growable: false),
    };
    final product = _selectedProduct;
    final draft = OperationPlanDraft(
      farmId: farmId,
      type: _type,
      title: _title.text,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      scheduleType: _recurrence,
      startsOn: _startsOn,
      endsOn: _endsOn,
      scheduledStartTime: _time == null
          ? null
          : '${_time!.hour.toString().padLeft(2, '0')}:'
              '${_time!.minute.toString().padLeft(2, '0')}:00',
      plannedDurationMinutes: int.tryParse(_duration.text.trim()),
      daysOfWeek: _recurrence == PlanScheduleType.weekly
          ? (_weekdays.toList()..sort())
          : null,
      targets: targets,
      assigneeProfileIds: _assigneeIds.toList(growable: false),
      inventoryItemId: _productItemId,
      applicationMethod: _productItemId == null ? null : _method,
      applicationRate:
          _productItemId == null ? null : double.tryParse(_rate.text.trim()),
      rateBasis: _productItemId == null ? null : _basis,
      rateUnit: _productItemId == null ? null : product?.unit,
    );
    final id = await controller.createPlan(draft);
    if (!mounted) return;
    if (id != null) context.go('/more/schedules/$id');
  }
}

String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
