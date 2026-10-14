import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart';
import 'package:flutter/material.dart';

/// Warns that offline work will not survive closing the app. Shown only when
/// the on-device database failed to open and the stores fell back to memory.
class StorageWarningBanner extends StatelessWidget {
  const StorageWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.maybeOf(context);
    if (services == null || services.persistentStorageAvailable) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        key: const Key('storage-warning-banner'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.issue),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded, color: AppColors.issue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.storageUnavailableWarning,
                style: const TextStyle(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Browser-only: whether the browser will keep the offline database, and how
/// much space it uses. Hidden on native, where [load] resolves to null.
class StorageStatusTile extends StatefulWidget {
  const StorageStatusTile({this.load = storageStatus, super.key});

  final Future<StorageStatus?> Function() load;

  @override
  State<StorageStatusTile> createState() => _StorageStatusTileState();
}

class _StorageStatusTileState extends State<StorageStatusTile> {
  late final Future<StorageStatus?> _status = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<StorageStatus?>(
        future: _status,
        builder: (context, snapshot) {
          final status = snapshot.data;
          if (status == null) return const SizedBox.shrink();
          final l10n = context.l10n;
          final usage = status.usageBytes;
          final quota = status.quotaBytes;
          final lines = <String>[
            if (status.persisted)
              l10n.storagePersistent
            else
              l10n.storageBestEffort,
            if (usage != null && quota != null)
              l10n.storageUsage(
                  formatStorageSize(usage), formatStorageSize(quota)),
          ];
          return ListTile(
            key: const Key('storage-status-tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              status.persisted ? Icons.lock_outline : Icons.storage_outlined,
              color: status.persisted ? AppColors.green : AppColors.orange,
            ),
            title: Text(l10n.storageTitle),
            subtitle: Text(lines.join('\n')),
          );
        },
      );
}

/// Sizes in MB, switching to GB from 1 GB up (iPhone Safari reports quotas
/// of tens of GB, which read badly as "39321.6 MB").
String formatStorageSize(int bytes) {
  const mb = 1024 * 1024;
  const gb = 1024 * mb;
  return bytes >= gb
      ? '${(bytes / gb).toStringAsFixed(1)} GB'
      : '${(bytes / mb).toStringAsFixed(1)} MB';
}
