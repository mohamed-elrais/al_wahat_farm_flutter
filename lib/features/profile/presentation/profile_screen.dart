import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/core/supabase/auth_repository.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/storage_status.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final operational = OperationalContextScope.maybeOf(context);
    final membership = operational?.selectedMembership;
    final name = operational?.profile.fullName ?? l10n.moreFarmMember;
    final services = AppServicesScope.maybeOf(context);
    return PaperBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: <Widget>[
          Eyebrow(l10n.moreEyebrow),
          const SizedBox(height: 6),
          Text(l10n.moreTitle,
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 18),
          const StorageWarningBanner(),
          WahatCard(
            child: Column(
              children: <Widget>[
                Semantics(
                  label: l10n.moreSignedInAs(name),
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
                      ? l10n.moreRoleResolves
                      : '${membership.role.localizedLabel(l10n)} · ${membership.farm.name}',
                ),
                const Divider(height: 32),
                if (services != null) ...<Widget>[
                  _LanguageSelector(controller: services.locale),
                  const Divider(height: 32),
                ],
                if (membership?.role.canManageSchedules ?? false) ...<Widget>[
                  ListTile(
                    key: const Key('schedules-entry-tile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat_outlined,
                        color: AppColors.green),
                    title: Text(l10n.schedulesTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/more/schedules'),
                  ),
                ],
                if (membership?.role.isOperational ?? false) ...<Widget>[
                  ListTile(
                    key: const Key('inventory-entry-tile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.green),
                    title: Text(l10n.inventoryTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/more/inventory'),
                  ),
                  const Divider(height: 24),
                ],
                _SyncStatusTile(connectivity: services?.connectivity),
                const _SyncCenter(),
                const StorageStatusTile(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('logout-button'),
                  onPressed: () => AuthRepository(
                    Supabase.instance.client,
                    onSignOut: services?.clearPrivateData,
                  ).signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = controller.locale?.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.translate, color: AppColors.green),
            const SizedBox(width: 12),
            Text(l10n.languageLabel,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: <Widget>[
            _LanguageChip(
              keyValue: 'language-system',
              label: l10n.languageSystem,
              selected: current == null,
              onSelected: () => controller.setLocale(null),
            ),
            _LanguageChip(
              keyValue: 'language-en',
              label: l10n.languageEnglish,
              selected: current == 'en',
              onSelected: () => controller.setLocale(const Locale('en')),
            ),
            _LanguageChip(
              keyValue: 'language-ar',
              label: l10n.languageArabic,
              selected: current == 'ar',
              onSelected: () => controller.setLocale(const Locale('ar')),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.keyValue,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String keyValue;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        key: Key(keyValue),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      );
}

class _SyncCenter extends StatelessWidget {
  const _SyncCenter();

  @override
  Widget build(BuildContext context) {
    final engine = SyncScope.maybeOf(context);
    if (engine == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final pending = engine.pendingCount;
    final failed = engine.failedCount;
    final syncing = engine.isSyncing;

    final (IconData icon, Color color, String text) = syncing
        ? (Icons.sync, AppColors.green, l10n.syncSyncing)
        : failed > 0
            ? (
                Icons.error_outline,
                AppColors.issue,
                l10n.syncStatusFailed(failed)
              )
            : pending > 0
                ? (
                    Icons.cloud_upload_outlined,
                    AppColors.orange,
                    l10n.syncStatusPending(pending)
                  )
                : (
                    Icons.cloud_done_outlined,
                    AppColors.green,
                    l10n.syncStatusAllSynced
                  );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 32),
        Semantics(
          label: text,
          child: ListTile(
            key: const Key('sync-center-tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: color),
            title: Text(l10n.syncTitle),
            subtitle: Text(text),
          ),
        ),
        if (pending > 0 || failed > 0 || syncing)
          Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('sync-now-button'),
                onPressed: syncing ? null : () => engine.sync(),
                icon: const Icon(Icons.sync, size: 18),
                label: Text(l10n.syncNow),
              ),
              if (failed > 0)
                OutlinedButton.icon(
                  key: const Key('sync-retry-failed-button'),
                  onPressed: syncing ? null : () => engine.retryFailed(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.syncRetryFailed),
                ),
              if (failed > 0)
                OutlinedButton.icon(
                  key: const Key('sync-review-failed-button'),
                  onPressed: () => context.go('/more/failed-ops'),
                  icon: const Icon(Icons.error_outline, size: 18),
                  label: Text(l10n.syncReviewFailed),
                ),
            ],
          ),
      ],
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
      return _SyncStatusRow(
        online: true,
        subtitle: context.l10n.syncDefaultSubtitle,
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _SyncStatusRow(
        online: controller.isOnline,
        subtitle: controller.isOnline
            ? context.l10n.syncOnlineSubtitle
            : context.l10n.syncOfflineSubtitle,
      ),
    );
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({required this.online, required this.subtitle});

  final bool online;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: online
          ? l10n.syncStatusOnlineSemantics
          : l10n.syncStatusOfflineSemantics,
      child: ListTile(
        key: const Key('sync-status-tile'),
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: online ? AppColors.green : AppColors.issue,
        ),
        title: Text(online ? l10n.syncOnline : l10n.syncOffline),
        subtitle: Text(subtitle),
      ),
    );
  }
}
