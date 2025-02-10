import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:captivate/src/episode.dart';
import 'package:captivate/src/logging.dart';
import 'package:captivate/src/media.dart';
import 'package:captivate/src/show.dart';
import 'package:captivate/src/user.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class CaptivateClient {
  Future<UserPayload?> authenticate({
    required String username,
    required String apiToken,
  }) async {
    CaptivateLogs.network.info("Authenticate - username: $username");

    var request = MultipartRequest('POST', Uri.parse('https://api.captivate.fm/authenticate/token'));
    request.fields.addAll(
      {
        'username': username,
        'token': apiToken,
      },
    );

    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return UserPayload.fromJson(json);
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<ShowPayload?> getShow(String authToken, String showId) async {
    CaptivateLogs.network.info("Get show: $showId");

    final response = await get(
      Uri.parse('https://api.captivate.fm/shows/$showId/'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return ShowPayload.fromJson(json);
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<EpisodesPayload?> getEpisodes(String authToken, String showId) async {
    CaptivateLogs.network.info("Get episodes - show: $showId");

    final response = await get(
      Uri.parse('https://api.captivate.fm/shows/$showId/episodes'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return EpisodesPayload.fromJson(json);
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<EpisodePayload?> getEpisode(String authToken, String episodeId) async {
    CaptivateLogs.network.info("Get episode - episode: $episodeId");

    final response = await get(
      Uri.parse('https://api.captivate.fm/episodes/$episodeId'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return EpisodePayload.fromJson(json);
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<Episode> createEpisode(String authToken, Episode episode) async {
    CaptivateLogs.network.info("Create episode - episode: ${episode.title}");

    var request = MultipartRequest(
      'POST',
      Uri.parse('https://api.captivate.fm/episodes'),
    )
      ..headers.addAll({
        "Authorization": "Bearer $authToken",
      })
      ..fields.addAll(episode.toFormFields());

    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final bodyJson = jsonDecode(body);

      if (bodyJson["success"] != true) {
        _logApiError("create episode", bodyJson);
        throw Exception("Failed to create episode - API error.");
      }

      // The docs say the return structure is:
      // {
      //     "success": true,
      //     "errors": [],
      //     "errfor": {},
      //     "record": {
      //         "id": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
      //         ....
      //     }
      // }
      //
      // Empirically, upon success, the actual structure is:
      // {
      //   "success": true,
      //   "episode": {...},
      //   "submittedToAmie": <bool>,
      //   "record": {...}
      // }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
      return Episode.fromJson(bodyJson["episode"]);
    } else {
      _logNetworkError(response);
      throw Exception("Failed to create episode - network error.");
    }
  }

  Future<void> updateEpisode(String authToken, String episodeId, Episode updatedEpisode) async {
    CaptivateLogs.network.info("Update episode - episode: $episodeId");

    var request = MultipartRequest(
      'PUT',
      Uri.parse('https://api.captivate.fm/episodes/$episodeId'),
    )
      ..headers.addAll({
        "Authorization": "Bearer $authToken",
      })
      ..fields.addAll(
        updatedEpisode.toFormFields(),
      );

    CaptivateLogs.network.finer("Multi-part request configuration:");
    CaptivateLogs.network.finer(" - url: ${request.url}");
    CaptivateLogs.network.finer(" - fields:");
    for (final field in request.fields.entries) {
      CaptivateLogs.network.finer("   - ${field.key}: ${field.value}");
    }
    CaptivateLogs.network.finer("");

    // Send the multi-part request to the server.
    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(body)}");
    } else {
      _logNetworkError(response);
    }
  }

  Future<Media?> getMedia({
    required String authToken,
    required String mediaId,
  }) async {
    CaptivateLogs.network.info("Get media: $mediaId");

    final response = await get(
      Uri.parse('https://api.captivate.fm/media/$mediaId'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return MediaPayload.fromJson(json).media;
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<MediaListPayload?> getMediaByShow({
    required String authToken,
    required String showId,
    int offset = 0,
    String order = "created_at",
    String sort = "DESC",
  }) async {
    CaptivateLogs.network.info("Get all media for show: $showId");

    final response = await get(
      Uri.parse('https://api.captivate.fm/shows/$showId/media?offset=$offset&order=$order&sort=$sort'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return MediaListPayload.fromJson(json);
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<MediaListPayload?> searchMediaWithinShow({
    required String authToken,
    required String showId,
    required String query,
    int offset = 0,
    String order = "created_at",
    String sort = "DESC",
  }) async {
    CaptivateLogs.network.info("Search all media for show ($showId): '$query'");

    final response = await get(
      Uri.parse(
          'https://api.captivate.fm/shows/$showId/media/search?search=$query&offset=$offset&order=$order&sort=$sort'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      CaptivateLogs.network.fine(const JsonEncoder.withIndent("  ").convert(json));

      return MediaListPayload.fromJson(json);
    } else {
      _logNetworkError(response);
      return null;
    }
  }

  Future<Media> uploadMedia({
    required String authToken,
    required String showId,
    required File mediaFile,
    required void Function(double progress) onProgress,
  }) async {
    CaptivateLogs.network.info("Upload media - show: $showId, media file: $mediaFile");

    // Assemble a multi-part HTTP request to upload the media file.
    var request = MultipartRequestWithProgress(
      'POST',
      Uri.parse('https://api.captivate.fm/shows/$showId/media'),
      onProgress,
    );
    request.files.add(
      MultipartFile(
        'file',
        mediaFile.openRead(),
        mediaFile.lengthSync(),
        filename: basename(mediaFile.path),
      ),
    );
    request.headers.addAll({
      "Authorization": "Bearer $authToken",
      "Content-Type": "multipart/form-data",
    });

    // Execute the request.
    StreamedResponse response = await request.send();

    if (200 <= response.statusCode && response.statusCode < 300) {
      CaptivateLogs.network.info("Done uploading media file.");
      final body = await response.stream.bytesToString();
      final bodyJson = jsonDecode(body);

      if (bodyJson["success"] != true) {
        _logApiError("upload media (${mediaFile.path})", bodyJson);
        throw Exception("Failed to upload media (${mediaFile.path}) - API error.");
      }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
      return Media.fromJson(bodyJson);
    } else {
      CaptivateLogs.network.warning(
          "Failed to upload media (${mediaFile.path}) - HTTP error (${response.statusCode}): ${response.reasonPhrase}");
      throw Exception(
          "Failed to upload media (${mediaFile.path}) - HTTP error (${response.statusCode}): ${response.reasonPhrase}");
    }
  }
}

class MultipartRequestWithProgress extends MultipartRequest {
  MultipartRequestWithProgress(
    super.method,
    super.url,
    this._onProgress,
  );

  final void Function(double progress) _onProgress;

  @override
  ByteStream finalize() {
    CaptivateLogs.network.finer("Finalizing multipart request and attaching a progress tracker to the byte stream.");
    final sourceByteStream = super.finalize();
    CaptivateLogs.network.finer("Source stream: ${sourceByteStream.runtimeType} (${sourceByteStream.hashCode}).");
    final int totalBytes = contentLength;
    int sentBytes = 0;

    final streamWithProgress = ByteStream(
      sourceByteStream.map((bytes) {
        sentBytes += bytes.length;
        _onProgress(sentBytes / totalBytes);

        return bytes;
      }),
    );
    CaptivateLogs.network
        .finer("Stream with progress: ${streamWithProgress.runtimeType} (${streamWithProgress.hashCode}).");

    return streamWithProgress;
  }
}

void _logApiError(String goal, Map<String, dynamic> responseBody) {
  CaptivateLogs.network.warning("Failed to '$goal'.");

  if (responseBody["errors"] is List<dynamic>) {
    final errors = responseBody["errors"] as List<dynamic>;
    for (final error in errors) {
      CaptivateLogs.network.warning("Error: '$error'");
    }
  }
}

void _logNetworkError(BaseResponse response) {
  if (!CaptivateLogs.isLogActive(CaptivateLogs.network)) {
    return;
  }

  final request = response.request;

  CaptivateLogs.network.warning([
    "Network request failed!",
    if (request != null) ...[
      "Request:",
      "${request.headers["method"] != null ? "(${request.headers["method"]}) " : ""}$request",
      "",
    ],
    "Response:",
    "${response.statusCode} - ${response.reasonPhrase}",
  ].join("\n"));
}
