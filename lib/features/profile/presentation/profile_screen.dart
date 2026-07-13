import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/supabase/auth_repository.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final operational = OperationalContextScope.maybeOf(context);
    final membership = operational?.selectedMembership;
    final name = operational?.profile.fullName ?? 'Farm member';
    final services = AppServicesScope.maybeOf(context);
    return PaperBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: <Widget>[
          const Eyebrow('Account and sync'),
          const SizedBox(height: 6),
          Text('More', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 18),
          WahatCard(
            child: Column(
              children: <Widget>[
                Semantics(
                  label: 'Signed in as $name',
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  membership == null
                      ? 'Role resolves from active farm membership'
                      : '${membership.role.label} · ${membership.farm.name}',
                ),
                const Divider(height: 32),
                _SyncStatusTile(connectivity: services?.connectivity),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('logout-button'),
                  onPressed: () => AuthRepository(
                    Supabase.instance.client,
                    onSignOut: services?.clearPrivateData,
                  ).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusTile extends StatelessWidget {
  const _SyncStatusTile({required this.connectivity});

  final ConnectivityController? connectivity;

  @override
  Widget build(BuildContext context) {
    final controller = connectivity;
    if (controller == null) {
      return const _SyncStatusRow(
        online: true,
        subtitle: 'Operational reads refresh from Supabase',
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _SyncStatusRow(
        online: controller.isOnline,
        subtitle: controller.isOnline
            ? 'Online · operational reads refresh from Supabase'
            : 'Offline · showing cached farm and task data',
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({required this.online, required this.subtitle});

  final bool online;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Semantics(
        label: online ? 'Sync status online' : 'Sync status offline',
        child: ListTile(
          key: const Key('sync-status-tile'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: online ? AppColors.green : AppColors.issue,
          ),
          title: Text(online ? 'Online' : 'Offline'),
          subtitle: Text(subtitle),
        ),
      );
}
