import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
          children: <Widget>[
            const Eyebrow('Field operations'),
            const SizedBox(height: 6),
            Text('Today’s tasks',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 18),
            const WahatCard(
              child: Column(
                children: <Widget>[
                  Icon(Icons.cloud_sync_outlined, size: 38),
                  SizedBox(height: 12),
                  Text(
                    'Task repository is waiting for an authenticated farm context.',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
