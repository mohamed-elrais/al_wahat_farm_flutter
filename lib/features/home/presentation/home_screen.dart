import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            final intro = _Intro(onScan: () => context.go('/scan'));
            const operations = _OperationsPanel();
            return SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 110),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(width: 300, child: intro),
                            const SizedBox(width: 18),
                            const Expanded(child: _FarmOverview()),
                            const SizedBox(width: 18),
                            const SizedBox(width: 330, child: operations),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            intro,
                            const SizedBox(height: 18),
                            const _FarmOverview(),
                            const SizedBox(height: 18),
                            operations,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Eyebrow('Sunday · 12 July'),
          const SizedBox(height: 7),
          Text(
            'Your farm.\nTree by tree.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 14),
          Container(
            width: 65,
            height: 3,
            color: AppColors.orange,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          const Text(
            'Field operations grounded in every mapped tree and irrigation zone.',
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFC55C31), Color(0xFFDA7542)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x339A4923),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(18),
              child: const SizedBox(
                height: 70,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 30),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Scan Tree QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _FarmOverview extends StatelessWidget {
  const _FarmOverview();

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Eyebrow('Live map data'),
            const SizedBox(height: 8),
            Text(
              'Al Wahat farm overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _Metric(
                  value: '1,567',
                  label: 'Mapped trees',
                  icon: Icons.park_outlined,
                ),
                _Metric(
                  value: '12',
                  label: 'Sections',
                  icon: Icons.grid_view_outlined,
                ),
                _Metric(
                  value: '122',
                  label: 'Irrigation zones',
                  icon: Icons.water_drop_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open coordinate map'),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppColors.green),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel();

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Today’s tasks',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Tasks load after your farm membership is resolved.'),
            const SizedBox(height: 16),
            const _TaskPreview(
              title: 'Irrigation check',
              meta: 'Section A · Zone 01',
            ),
            const _TaskPreview(
              title: 'Tree inspection',
              meta: 'Section C · Trees 101–136',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/tasks'),
              child: const Text('View all tasks'),
            ),
          ],
        ),
      );
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.title, required this.meta});
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          foregroundColor: AppColors.green,
          child: Icon(Icons.water_drop_outlined),
        ),
        title: Text(title),
        subtitle: Text(meta),
      );
}
