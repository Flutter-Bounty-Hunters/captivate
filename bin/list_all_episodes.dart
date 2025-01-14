import 'dart:io';

import 'package:captivate/captivate.dart';

Future<void> main() async {
  print("Running example.");

  const showId = "3743ba71-859c-4164-99ff-999b525ccf48";

  // REQUIRED: Environment variable called "captivate_username"
  final captivateUsername = Platform.environment["captivate_username"];

  // REQUIRED: Environment variable called "captivate_token"
  final captivateApiToken = Platform.environment["captivate_token"];

  if (captivateUsername == null) {
    print("Missing environment variable for Captivate username.");
    exit(-1);
  }

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

  print("Getting show...");
  final show = await client.getShow(authToken, showId);
  print("Show: ${show!.show.summary}");
  print("");

  print("Getting episode list...");
  final episodes = await client.getEpisodes(authToken, showId);
  print("Episodes (${episodes!.count}):");
  for (final episode in episodes.episodes) {
    print(" - ${episode.title}");
  }
  print("");

  print("--------------");
  print("Done with example!");
}
