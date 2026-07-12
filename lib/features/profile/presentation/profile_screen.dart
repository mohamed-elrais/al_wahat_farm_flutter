import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
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
    final membership = operational == null || operational.memberships.isEmpty
        ? null
        : operational.memberships.first;
    final name = operational?.profile.fullName ?? 'Farm member';
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
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  membership == null
                      ? 'Role resolves from active farm membership'
                      : '${membership.role.label} · ${membership.farm.name}',
                ),
                const Divider(height: 32),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.sync, color: AppColors.green),
                  title: Text('Sync status'),
                  subtitle: Text(
                    'Online · operational reads refresh from Supabase',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      AuthRepository(Supabase.instance.client).signOut(),
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
