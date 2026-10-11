/// How the browser treats this app's offline storage (IndexedDB).
class StorageStatus {
  const StorageStatus({
    required this.persisted,
    this.usageBytes,
    this.quotaBytes,
  });

  /// True when the browser granted durable storage, so it will not evict the
  /// offline data under storage pressure.
  final bool persisted;
  final int? usageBytes;
  final int? quotaBytes;
}
