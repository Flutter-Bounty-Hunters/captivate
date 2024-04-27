import 'dart:convert';
import 'dart:io';

import 'package:captivate/src/episode.dart';
import 'package:captivate/src/show.dart';
import 'package:captivate/src/user.dart';
import 'package:http/http.dart';

class CaptivateClient {
  Future<UserPayload?> authenticate({
    required String username,
    required String apiToken,
  }) async {
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
      return UserPayload.fromJson(json);
    } else {
      print(response.reasonPhrase);
      return null;
    }
  }

  Future<ShowPayload?> getShow(String authToken, String showId) async {
    final response = await get(
      Uri.parse('https://api.captivate.fm/shows/$showId/'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      print(JsonEncoder.withIndent("  ").convert(json));

      return ShowPayload.fromJson(json);
    } else {
      print(response.reasonPhrase);
      return null;
    }
  }

  Future<EpisodePayload?> getEpisode(String authToken, String episodeId) async {
    final response = await get(
      Uri.parse('https://api.captivate.fm/episodes/$episodeId'),
      headers: {
        "Authorization": "Bearer $authToken",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      print(const JsonEncoder.withIndent("  ").convert(json));

      return EpisodePayload.fromJson(json);
    } else {
      print(response.reasonPhrase);
      return null;
    }
  }

  Future<void> createEpisode(String authToken, Episode episode) async {
    var request = MultipartRequest(
      'POST',
      Uri.parse('https://api.captivate.fm/episodes'),
    )..headers.addAll({
        "Authorization": "Bearer $authToken",
      });

    request.fields.addAll(episode.toFormFields());

    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      print("Success:");
      print(body);
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> updateEpisode(String authToken, String episodeId, Episode updatedEpisode) async {
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

    print("URL:");
    print(request.url);
    print("");

    print("Fields:");
    for (final field in request.fields.entries) {
      print(" - ${field.key}: ${field.value}");
    }
    print("");

    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Success:");
      final body = await response.stream.bytesToString();
      print(body);
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> uploadMedia({
    required String authToken,
    required String showId,
    required File mediaFile,
  }) async {
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
      print("Success:");
      print(body);
    } else {
      print(response.reasonPhrase);
    }
  }
}
