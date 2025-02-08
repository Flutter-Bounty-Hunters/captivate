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
}
