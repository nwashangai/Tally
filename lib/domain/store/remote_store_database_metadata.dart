import 'store_id.dart';

/// Metadata describing a remote store database file in serverless object storage.
class RemoteStoreDatabaseMetadata {
  final StoreId storeId;
  final int revision;
  final int fileSize;
  final String checksum;
  final DateTime uploadedAt;
  final String uploadedBy;

  const RemoteStoreDatabaseMetadata({
    required this.storeId,
    required this.revision,
    required this.fileSize,
    required this.checksum,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, Object?> toJson() => {
        'storeId': storeId.value,
        'revision': revision,
        'fileSize': fileSize,
        'checksum': checksum,
        'uploadedAt': uploadedAt.toIso8601String(),
        'uploadedBy': uploadedBy,
      };

  factory RemoteStoreDatabaseMetadata.fromJson(Map<String, Object?> json) {
    return RemoteStoreDatabaseMetadata(
      storeId: StoreId(json['storeId']! as String),
      revision: (json['revision'] as num).toInt(),
      fileSize: (json['fileSize'] as num).toInt(),
      checksum: json['checksum']! as String,
      uploadedAt: DateTime.parse(json['uploadedAt']! as String),
      uploadedBy: json['uploadedBy']! as String,
    );
  }
}
