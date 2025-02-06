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
        _logApiError(bodyJson);
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

      // {
      //   "success": true,
      //   "episode": {
      //     "id": "6882f3b9-4e3f-4407-8dff-5fea09f5ce54",
      //     "shows_id": "3743ba71-859c-4164-99ff-999b525ccf48",
      //     "media_id": "",
      //     "title": "February 5, 2025",
      //     "itunes_title": "",
      //     "published_date": "2025-02-06T12:31:50.000Z",
      //     "guid": null,
      //     "status": "Draft",
      //     "episode_art": "",
      //     "shownotes": "",
      //     "summary": "",
      //     "episode_type": "full",
      //     "episode_season": null,
      //     "episode_number": null,
      //     "itunes_subtitle": "",
      //     "author": "Matthew Carroll",
      //     "link": "",
      //     "explicit": "clean",
      //     "itunes_block": "false",
      //     "google_block": "false",
      //     "google_description": "",
      //     "donation_link": "",
      //     "donation_text": "",
      //     "post_id": null,
      //     "website_title": "",
      //     "is_active": null,
      //     "failed_import": 0,
      //     "slug": "",
      //     "seo_title": "",
      //     "seo_description": "",
      //     "episode_private": null,
      //     "episode_expiration": null,
      //     "auto_tweeted": 0,
      //     "video_repurposed": null,
      //     "video_s3_key": null,
      //     "import_errors": null,
      //     "transcription_html": null,
      //     "transcription_file": null,
      //     "transcription_json": null,
      //     "transcription_text": null,
      //     "idea_title": null,
      //     "idea_summary": null,
      //     "idea_notes": null,
      //     "idea_created_at": null,
      //     "created_at": null,
      //     "updated_at": null,
      //     "deleted_by_user_id": null,
      //     "idea_production_notes": null,
      //     "early_access_end_date": null,
      //     "captivate_episode_type": "standard",
      //     "exclusivity_date": null,
      //     "apple_episode_id": null,
      //     "subscriber_exclusive_media_id": null,
      //     "apple_episode_status": null,
      //     "youtube_video_id": "",
      //     "youtube_video_title": null,
      //     "total_imported_legacy_analytics": null,
      //     "episodes_id": "6882f3b9-4e3f-4407-8dff-5fea09f5ce54",
      //     "episodes_isActive": 1,
      //     "episodes_showId": "3743ba71-859c-4164-99ff-999b525ccf48",
      //     "users_id": null,
      //     "media_name": null,
      //     "media_size": null,
      //     "media_bit_rate": null,
      //     "media_id3_size": null,
      //     "media_type": null,
      //     "media_url": null,
      //     "media_duration": null,
      //     "previously_assigned_episode": null,
      //     "type": null,
      //     "stackpath_rule_id": null,
      //     "original_media_id": null,
      //     "media_slot_type_id": null,
      //     "amie_job_id": null,
      //     "amie_status": null,
      //     "amie_failure_count": null,
      //     "shownotes_addendum_title": null,
      //     "shownotes_addendum": null,
      //     "short_link_id": null,
      //     "object_storage_location": null,
      //     "deleted_at": null,
      //     "apple_upload_status": null,
      //     "apple_container_id": null,
      //     "waveform_url": null,
      //     "chapters_url": null,
      //     "integrated_lufs": null,
      //     "imported_media_url": null,
      //     "media_isActive": null
      //   },
      //   "submittedToAmie": false,
      //   "record": {
      //     "id": "6882f3b9-4e3f-4407-8dff-5fea09f5ce54",
      //     "shows_id": "3743ba71-859c-4164-99ff-999b525ccf48",
      //     "media_id": "",
      //     "title": "February 5, 2025",
      //     "itunes_title": "",
      //     "published_date": "2025-02-06T12:31:50.000Z",
      //     "guid": null,
      //     "status": "Draft",
      //     "episode_art": "",
      //     "shownotes": "",
      //     "summary": "",
      //     "episode_type": "full",
      //     "episode_season": null,
      //     "episode_number": null,
      //     "itunes_subtitle": "",
      //     "author": "Matthew Carroll",
      //     "link": "",
      //     "explicit": "clean",
      //     "itunes_block": "false",
      //     "google_block": "false",
      //     "google_description": "",
      //     "donation_link": "",
      //     "donation_text": "",
      //     "post_id": null,
      //     "website_title": "",
      //     "is_active": null,
      //     "failed_import": 0,
      //     "slug": "",
      //     "seo_title": "",
      //     "seo_description": "",
      //     "episode_private": null,
      //     "episode_expiration": null,
      //     "auto_tweeted": 0,
      //     "video_repurposed": null,
      //     "video_s3_key": null,
      //     "import_errors": null,
      //     "transcription_html": null,
      //     "transcription_file": null,
      //     "transcription_json": null,
      //     "transcription_text": null,
      //     "idea_title": null,
      //     "idea_summary": null,
      //     "idea_notes": null,
      //     "idea_created_at": null,
      //     "created_at": null,
      //     "updated_at": null,
      //     "deleted_by_user_id": null,
      //     "idea_production_notes": null,
      //     "early_access_end_date": null,
      //     "captivate_episode_type": "standard",
      //     "exclusivity_date": null,
      //     "apple_episode_id": null,
      //     "subscriber_exclusive_media_id": null,
      //     "apple_episode_status": null,
      //     "youtube_video_id": "",
      //     "youtube_video_title": null,
      //     "total_imported_legacy_analytics": null,
      //     "episodes_id": "6882f3b9-4e3f-4407-8dff-5fea09f5ce54",
      //     "episodes_isActive": 1,
      //     "episodes_showId": "3743ba71-859c-4164-99ff-999b525ccf48",
      //     "users_id": null,
      //     "media_name": null,
      //     "media_size": null,
      //     "media_bit_rate": null,
      //     "media_id3_size": null,
      //     "media_type": null,
      //     "media_url": null,
      //     "media_duration": null,
      //     "previously_assigned_episode": null,
      //     "type": null,
      //     "stackpath_rule_id": null,
      //     "original_media_id": null,
      //     "media_slot_type_id": null,
      //     "amie_job_id": null,
      //     "amie_status": null,
      //     "amie_failure_count": null,
      //     "shownotes_addendum_title": null,
      //     "shownotes_addendum": null,
      //     "short_link_id": null,
      //     "object_storage_location": null,
      //     "deleted_at": null,
      //     "apple_upload_status": null,
      //     "apple_container_id": null,
      //     "waveform_url": null,
      //     "chapters_url": null,
      //     "integrated_lufs": null,
      //     "imported_media_url": null,
      //     "media_isActive": null
      //   }
      // }

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
      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(body)}");
    } else {
      _logNetworkError(response);
    }
  }
}

void _logApiError(Map<String, dynamic> responseBody) {
  CaptivateLogs.network.warning("Failed to create episode.");
  final errors = responseBody["errors"] as List<dynamic>;
  for (final error in errors) {
    CaptivateLogs.network.warning("Error: '$error'");
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
