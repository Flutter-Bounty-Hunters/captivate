import 'dart:io';

import 'package:captivate/captivate.dart';

Future<void> main(List<String> arguments) async {
  CaptivateLogs.initLoggers({
    CaptivateLogs.network,
  }, Level.WARNING);

  print("Running media upload example.");
  const showId = "3743ba71-859c-4164-99ff-999b525ccf48";

  if (arguments.isEmpty) {
    print("Missing path to media file.");
    exit(-1);
  }

  final file = File(arguments.first);
  if (!file.existsSync()) {
    print("Couldn't find file: ${file.path}");
    exit(-1);
  }

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

  print("Uploading media...");
  await client.uploadMediaCustomHttpRequest(
    authToken: authToken,
    showId: showId,
    mediaFile: file,
    onProgress: (double progress) {
      print("Upload progress: $progress");
    },
  );

  // await client.uploadMediaWithDartIo(
  //   authToken: authToken,
  //   showId: showId,
  //   mediaFile: file,
  // );

  // Using HTTP package.
  // await client.uploadMedia(
  //   authToken: authToken,
  //   showId: showId,
  //   mediaFile: file,
  // );

  print("Done with media upload.");
}
