import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:flutter/material.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({this.mapFuture, super.key});

  final Future<ProjectedFarmMap>? mapFuture;

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  late final Future<ProjectedFarmMap> _map;
  final _transformation = TransformationController();
  String? _section;
  FarmTree? _selectedTree;
  bool _trees = true;
  bool _irrigation = true;
  bool _utilities = true;

  @override
  void initState() {
    super.initState();
    _map = widget.mapFuture ??
        const MapAssetRepository().load().then(ProjectedFarmMap.new);
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: FutureBuilder<ProjectedFarmMap>(
          future: _map,
          builder:
              (BuildContext context, AsyncSnapshot<ProjectedFarmMap> snapshot) {
            if (snapshot.hasError) return _MapError(error: snapshot.error!);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final map = snapshot.data!;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final wide = constraints.maxWidth >= AppBreakpoints.tablet;
                final canvas = _MapPanel(
                  map: map,
                  transformation: _transformation,
                  section: _section,
                  selectedTree: _selectedTree,
                  showTrees: _trees,
                  showIrrigation: _irrigation,
                  showUtilities: _utilities,
                  onTapTree: (tree) => _selectTree(tree),
                );
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 20 : 10,
                    12,
                    wide ? 20 : 10,
                    90,
                  ),
                  child: Column(
                    children: <Widget>[
                      _MapHeader(
                        map: map,
                        section: _section,
                        trees: _trees,
                        irrigation: _irrigation,
                        utilities: _utilities,
                        onReset: () => _fit(map, null, constraints.biggest),
                        onZoom: _zoom,
                        onTrees: (value) => setState(() => _trees = value),
                        onIrrigation: (value) =>
                            setState(() => _irrigation = value),
                        onUtilities: (value) =>
                            setState(() => _utilities = value),
                      ),
                      const SizedBox(height: 8),
                      _SectionFilter(
                        sections: map.data.sections,
                        selected: _section,
                        onSelected: (section) {
                          setState(() {
                            _section = section;
                            _selectedTree = null;
                          });
                          _fit(map, section, constraints.biggest);
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: wide
                            ? Row(
                                children: <Widget>[
                                  Expanded(child: canvas),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 280,
                                    child: _MapSummary(
                                      map: map,
                                      selected: _selectedTree,
                                    ),
                                  ),
                                ],
                              )
                            : canvas,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );

  void _selectTree(FarmTree tree) {
    setState(() {
      _selectedTree = tree;
      _section = tree.section;
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TreeSheet(tree: tree),
    );
  }

  void _zoom(double factor) {
    final matrix = _transformation.value.clone();
    final scale = matrix.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.3, 8.0) / scale;
    _transformation.value = matrix..scale(next);
  }

  void _fit(ProjectedFarmMap map, String? section, Size viewport) {
    final rect = section == null
        ? Offset.zero & MapProjection.canvasSize
        : map.sections.firstWhere((item) => item.section.id == section).bounds;
    final available = Size(viewport.width, viewport.height - 150);
    final scale = (available.width / rect.width).clamp(0.1, 8.0) <
            (available.height / rect.height).clamp(0.1, 8.0)
        ? available.width / rect.width
        : available.height / rect.height;
    _transformation.value = Matrix4.identity()
      ..translate(
        (available.width - rect.width * scale) / 2 - rect.left * scale,
        (available.height - rect.height * scale) / 2 - rect.top * scale,
      )
      ..scale(scale);
  }
}

class _MapPanel extends StatefulWidget {
  const _MapPanel({
    required this.map,
    required this.transformation,
    required this.section,
    required this.selectedTree,
    required this.showTrees,
    required this.showIrrigation,
    required this.showUtilities,
    required this.onTapTree,
  });
  final ProjectedFarmMap map;
  final TransformationController transformation;
  final String? section;
  final FarmTree? selectedTree;
  final bool showTrees;
  final bool showIrrigation;
  final bool showUtilities;
  final ValueChanged<FarmTree> onTapTree;

  @override
  State<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<_MapPanel> {
  bool _fitted = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (!_fitted) {
            _fitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final scale = (constraints.maxWidth /
                          MapProjection.canvasSize.width) <
                      (constraints.maxHeight / MapProjection.canvasSize.height)
                  ? constraints.maxWidth / MapProjection.canvasSize.width
                  : constraints.maxHeight / MapProjection.canvasSize.height;
              widget.transformation.value = Matrix4.identity()
                ..translate(
                  (constraints.maxWidth -
                          MapProjection.canvasSize.width * scale) /
                      2,
                  (constraints.maxHeight -
                          MapProjection.canvasSize.height * scale) /
                      2,
                )
                ..scale(scale);
            });
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: AppColors.sand,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.showTrees
                    ? (details) {
                        final inverse = Matrix4.inverted(
                          widget.transformation.value,
                        );
                        final point = MatrixUtils.transformPoint(
                          inverse,
                          details.localPosition,
                        );
                        final scale =
                            widget.transformation.value.getMaxScaleOnAxis();
                        final nearest = widget.map.treeIndex.nearest(
                          point,
                          tolerance: 44 / scale,
                          section: widget.section,
                        );
                        if (nearest != null) widget.onTapTree(nearest.tree);
                      }
                    : null,
                child: InteractiveViewer(
                  constrained: false,
                  minScale: 0.1,
                  maxScale: 8,
                  transformationController: widget.transformation,
                  boundaryMargin: const EdgeInsets.all(220),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: MapProjection.canvasSize,
                      painter: FarmMapPainter(
                        map: widget.map,
                        selectedSection: widget.section,
                        selectedTreeId: widget.selectedTree?.id,
                        showTrees: widget.showTrees,
                        showIrrigation: widget.showIrrigation,
                        showUtilities: widget.showUtilities,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.map,
    required this.section,
    required this.trees,
    required this.irrigation,
    required this.utilities,
    required this.onReset,
    required this.onZoom,
    required this.onTrees,
    required this.onIrrigation,
    required this.onUtilities,
  });
  final ProjectedFarmMap map;
  final String? section;
  final bool trees;
  final bool irrigation;
  final bool utilities;
  final VoidCallback onReset;
  final ValueChanged<double> onZoom;
  final ValueChanged<bool> onTrees;
  final ValueChanged<bool> onIrrigation;
  final ValueChanged<bool> onUtilities;

  @override
  Widget build(BuildContext context) {
    final selected = section == null
        ? null
        : map.data.sections.firstWhere((item) => item.id == section);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Eyebrow('Coordinate-accurate 2D map'),
              Text(
                selected == null
                    ? 'Al Wahat farm overview'
                    : '${selected.name} · ${selected.treeCount == 0 ? 'Unplanted' : selected.treeCount}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        _Control(
          icon: Icons.add,
          tooltip: 'Zoom in',
          onTap: () => onZoom(1.25),
        ),
        _Control(
          icon: Icons.remove,
          tooltip: 'Zoom out',
          onTap: () => onZoom(0.8),
        ),
        _Control(
          icon: Icons.center_focus_strong,
          tooltip: 'Reset map',
          onTap: onReset,
        ),
        PopupMenuButton<String>(
          tooltip: 'Map layers',
          icon: const Icon(Icons.layers_outlined),
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            CheckedPopupMenuItem(
              value: 'trees',
              checked: trees,
              child: const Text('Trees'),
            ),
            CheckedPopupMenuItem(
              value: 'irrigation',
              checked: irrigation,
              child: const Text('Irrigation network'),
            ),
            CheckedPopupMenuItem(
              value: 'utilities',
              checked: utilities,
              child: const Text('Buildings & utilities'),
            ),
          ],
          onSelected: (value) {
            if (value == 'trees') onTrees(!trees);
            if (value == 'irrigation') onIrrigation(!irrigation);
            if (value == 'utilities') onUtilities(!utilities);
          },
        ),
      ],
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon),
      );
}

class _SectionFilter extends StatelessWidget {
  const _SectionFilter({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });
  final List<FarmSectionGeometry> sections;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final section = index == 0 ? null : sections[index - 1];
            final active = selected == section?.id;
            return ChoiceChip(
              key: Key('section-${section?.id ?? 'all'}'),
              selected: active,
              onSelected: (_) => onSelected(section?.id),
              label: Text(
                section == null
                    ? 'All 12 sections'
                    : '${section.name}  ${section.treeCount == 0 ? 'Empty' : section.treeCount}',
              ),
            );
          },
        ),
      );
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({required this.map, required this.selected});
  final ProjectedFarmMap map;
  final FarmTree? selected;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: selected == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 40,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select any tree',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text('${map.data.trees.length} tree points are available.'),
                ],
              )
            : _TreeDetails(tree: selected!),
      );
}

class _TreeSheet extends StatelessWidget {
  const _TreeSheet({required this.tree});
  final FarmTree tree;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.48,
        minChildSize: 0.28,
        maxChildSize: 0.82,
        expand: false,
        builder: (_, controller) => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: <Widget>[
              Center(
                  child:
                      Container(width: 44, height: 4, color: AppColors.line)),
              const SizedBox(height: 18),
              _TreeDetails(tree: tree),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.assignment_add),
                label: const Text('Attach a task'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.report_outlined),
                label: const Text('Report an issue'),
              ),
            ],
          ),
        ),
      );
}

class _TreeDetails extends StatelessWidget {
  const _TreeDetails({required this.tree});
  final FarmTree tree;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Eyebrow('Selected tree'),
          Text(tree.code, style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: <Widget>[
              _Detail(label: 'Section', value: tree.section),
              _Detail(
                  label: 'Row / tree', value: '${tree.row} / ${tree.number}'),
              _Detail(label: 'Health', value: tree.health),
              _Detail(label: 'Type', value: tree.type),
              _Detail(label: 'Zone', value: tree.zoneId),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF1EADC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                '${tree.latitude.toStringAsFixed(7)}, ${tree.longitude.toStringAsFixed(7)}',
              ),
            ),
          ),
        ],
      );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                letterSpacing: 0.8,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _MapError extends StatelessWidget {
  const _MapError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'The bundled farm geometry could not be loaded.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      );
}
