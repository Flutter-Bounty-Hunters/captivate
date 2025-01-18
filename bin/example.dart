import 'dart:io';

import 'package:captivate/captivate.dart';

Future<void> main() async {
  print("Running example.");
  final captivateUsername = Platform.environment["captivate_username"];
  if (captivateUsername == null) {
    print("Missing environment variable for Captivate username.");
    exit(-1);
  }
  final captivateApiToken = Platform.environment["captivate_token"];
  if (captivateApiToken == null) {
    print("Missing environment variable for Captivate API token.");
    exit(-1);
  }

  final client = CaptivateClient();

  print("Authenticating...");
  final userPayload = await client.authenticate(
    username: captivateUsername,
    apiToken: captivateApiToken,
  );
  final authToken = userPayload!.user.token;
  print("Auth token: $authToken");
  print("");

  // print("Getting show...");
  // final payload = await client.getShow(authToken, _flutterSpacesId);
  // print("Show: ${payload!.show.summary}");
  // print("");

  // print("Getting episode...");
  // final payload = await client.getEpisode(authToken, "86ff7b31-8b94-4a49-8401-67ed459ea922");
  // print("Episode: ${payload!.episode.title}");
  // print(" - status: ${payload.episode.status}");
  // print("");

  // print("Creating a new episode...");
  // await client.createEpisode(
  //   authToken,
  //   Episode(
  //     showId: _flutterSpacesId,
  //     status: "Draft",
  //     date: "2024-04-24 12:00:00",
  //     title: "A Flutter developer's view of the history of web browsers",
  //     mediaId: "4c5cb2a1-3dfe-4c1f-86d5-04a92b70aba5",
  //   ),
  // );

  // print("Uploading audio to Captivate...");
  // await client.uploadMedia(
  //   authToken: authToken,
  //   showId: _flutterSpacesId,
  //   mediaFile: File(
  //     "/Volumes/G-RAID/SuperDeclarative/Productions/Flutter-Spaces/shows/flutter-spaces_2024-04-24_history-of-web-browsers_cut.mp3",
  //   ),
  // );

  // WARNING: Update episode seems to update the whole episode. It doesn't update individual
  // fields.
  print("Associating uploaded media with episode...");
  await client.updateEpisode(
    authToken,
    "dfb56f42-879e-47f0-b0e1-5ea286f404ee",
    Episode(
      showId: _flutterSpacesId,
      status: "Published",
      date: "2024-04-24 12:00:00",
      title: "A Flutter developer's view of the history of web browsers",
      // Note: Shownotes are required to publish.
      showNotes:
          "Flutter Spaces - April 24, 2024 - We discuss the history of web browsers from hypertext document viewers to a portable operating system.",
      mediaId: "4c5cb2a1-3dfe-4c1f-86d5-04a92b70aba5",
    ),
  );

  print("");
  print("Done with example!");
}

const _flutterSpacesId = "3743ba71-859c-4164-99ff-999b525ccf48";

// Uploading audio to episode...
// Success:
// {
//   "success":true,
//   "media": {
//     "id":"4c5cb2a1-3dfe-4c1f-86d5-04a92b70aba5",
//     "media_name":"flutter-spaces_2024-04-24_history-of-web-browsers_cut",
// "media_size":136361807,
// "media_url":"https://podcasts.captivate.fm/media/4c5cb2a1-3dfe-4c1f-86d5-04a92b70aba5/flutter-spaces-2024-04-24-history-of-web-browsers-cut.mp3",
// "shows_id":"3743ba71-859c-4164-99ff-999b525ccf48",
// "users_id":"f26aae97-5a30-403e-9176-d6194016976d",
// "created_at":"2024-04-25 06:04:40",
// "updated_at":"2024-04-25 06:04:40",
// "media_bit_rate":128000,
// "media_duration":8522.592,
// "media_id3_size":143,
// "media_type":"audio/mpeg",
// "type":"audio",
// "object_storage_location":"media",
// "integrated_lufs":null,
// "non_cdn_url":"https://media-hosting.s3.stackpathstorage.com/media/4c5cb2a1-3dfe-4c1f-86d5-04a92b70aba5/flutter-spaces-2024-04-24-history-of-web-browsers-cut.mp3",
// },
// }
