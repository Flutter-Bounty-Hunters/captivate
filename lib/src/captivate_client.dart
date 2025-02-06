import 'dart:convert';
import 'dart:io';

import 'package:captivate/src/episode.dart';
import 'package:captivate/src/logging.dart';
import 'package:captivate/src/show.dart';
import 'package:captivate/src/user.dart';
import 'package:http/http.dart';

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

  Future<void> uploadMedia({
    required String authToken,
    required String showId,
    required File mediaFile,
  }) async {
    CaptivateLogs.network.info("Upload media - show: $showId, media file: $mediaFile");
    var request = MultipartRequest(
      'POST',
      Uri.parse('https://api.captivate.fm/shows/$showId/media'),
    );
    request.files.add(
      await MultipartFile.fromPath('file', mediaFile.path),
    );
    request.headers.addAll({
      "Authorization": "Bearer $authToken",
      "Content-Type": "multipart/form-data",
    });

    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final bodyJson = jsonDecode(body);

      if (bodyJson["success"] != true) {
        _logApiError("upload media (${mediaFile.path})", bodyJson);
        throw Exception("Failed to upload media (${mediaFile.path}) - API error.");
      }

      // Response structure:
      // {
      //     "success": true,
      //     "media": {
      //         "id": "mmmmmmmm-mmmm-mmmm-mmmm-mmmmmmmmmmmm",
      //         .....
      //     }
      // }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
    } else {
      _logNetworkError(response);
      throw Exception("Failed to upload media (${mediaFile.path}) - network error.");
    }
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
