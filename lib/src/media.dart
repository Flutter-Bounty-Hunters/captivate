class MediaListPayload {
  static MediaListPayload fromJson(Map<String, dynamic> json) {
    return MediaListPayload(
      limit: json["limit"],
      totalCount: json["totalCount"],
      mediaList: [
        for (final mediaJson in json["media"]) //
          Media.fromJson(mediaJson),
      ],
    );
  }

  const MediaListPayload({
    required this.limit,
    required this.totalCount,
    required this.mediaList,
  });

  final int limit;
  final int totalCount;
  final List<Media> mediaList;
}

class MediaPayload {
  static MediaPayload fromJson(Map<String, dynamic> json) {
    return MediaPayload(
      media: Media.fromJson(json["media"]),
    );
  }

  const MediaPayload({
    required this.media,
  });

  final Media media;
}

class Media {
  static Media fromJson(Map<String, dynamic> json) {
    return Media(
      id: json["id"],
      createdAt: json["created_at"],
      updatedAt: json["updated_at"],
      mediaName: json["media_name"],
      showsId: json["shows_id"],
      usersId: json["users_id"],
      type: json["type"],
      mediaType: json["media_type"],
      mediaSize: json["media_size"],
      mediaUrl: json["media_url"],
      mediaBitRate: _parseIntFromIntOrString(json["media_bit_rate"]),
      mediaDuration: _parseDoubleFromNumOrString(json["media_duration"]),
      mediaId3Size: json["media_id3_size"],
      objectStorageLocation: json["object_storage_location"],
      // TODO: "integrated_lufs" when we figure out what data type it is (we're getting `null` in json).
      nonCdnUrl: json["non_cdn_url"],
    );
  }

  static int? _parseIntFromIntOrString(Object? value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value);
    } else {
      return null;
    }
  }

  static double? _parseDoubleFromNumOrString(Object? value) {
    if (value is double) {
      return value;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    } else {
      return null;
    }
  }

  // {
//  "success": true,
//  "media": {
//   "id": "143aa6a4-d1e6-4420-bdd4-f448363689e3",
//   "media_name": "flutter-spaces-2025-01-22-hungrimind-ft-tadas-and-robert-cut-converted",
//   "media_size": 110297616,
//   "media_url": "https://podcasts.captivate.fm/media/143aa6a4-d1e6-4420-bdd4-f448363689e3/flutter-spaces-2025-01-22-hungrimind-ft-tadas-and-robert-cut-co.mp3",
//   "shows_id": "3743ba71-859c-4164-99ff-999b525ccf48",
//   "users_id": "f26aae97-5a30-403e-9176-d6194016976d",
//   "created_at": "2025-02-06 08:03:08",
//   "updated_at": "2025-02-06 08:03:08",
//   "media_bit_rate": 128000,
//   "media_duration": 6893.592,
//   "media_id3_size": 144,
//   "media_type": "audio/mpeg",
//   "type": "audio",
//   "object_storage_location": "media",
//   "integrated_lufs": null,
//   "non_cdn_url": "https://media-hosting.us-mia-1.linodeobjects.com/media/143aa6a4-d1e6-4420-bdd4-f448363689e3/flutter-spaces-2025-01-22-hungrimind-ft-tadas-and-robert-cut-co.mp3"
//  }
// }

  const Media({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.mediaName,
    this.showsId,
    this.usersId,
    this.type,
    this.mediaType,
    this.mediaSize,
    this.mediaUrl,
    this.mediaBitRate,
    this.mediaDuration,
    this.mediaId3Size,
    this.objectStorageLocation,
    this.nonCdnUrl,
  });

  final String? id;
  final String? createdAt; // e.g., "2025-02-06 08:03:08"
  final String? updatedAt; // e.g., "2025-02-06 08:03:08"
  final String? mediaName; // e.g., "flutter-spaces-2025-01-22-hungrimind-ft-tadas-and-robert-cut-converted"

  final String? showsId;
  final String? usersId;

  final String? type; // e.g., "audio
  final String? mediaType; // e.g., "audio/mpeg"
  final int? mediaSize;
  final String? mediaUrl;
  final int? mediaBitRate;
  final double? mediaDuration;
  final int? mediaId3Size;
  final String? objectStorageLocation;
  final String? nonCdnUrl;
}
