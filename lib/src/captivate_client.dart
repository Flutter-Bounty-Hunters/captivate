import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:captivate/src/episode.dart';
import 'package:captivate/src/logging.dart';
import 'package:captivate/src/media.dart';
import 'package:captivate/src/show.dart';
import 'package:captivate/src/user.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
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

  Future<UploadProgressWithResult<Media>> uploadMedia({
    required String authToken,
    required String showId,
    required File mediaFile,
  }) async {
    CaptivateLogs.network.info("Upload media - show: $showId, media file: $mediaFile");

    // Create a progress tracker, which wraps around a byte stream to the media file,
    // so that we can monitor the progress of the upload.
    //
    // We'll pass this progress tracker to the HTTP client, instead of the File.
    final progressTrackingUploadStream = HttpFileUploadStream(mediaFile);

    // Assemble a multi-part HTTP request to upload the media file.
    var request = MultipartRequest(
      'POST',
      Uri.parse('https://api.captivate.fm/shows/$showId/media'),
    );
    request.files.add(
      MultipartFile(
        'file',
        progressTrackingUploadStream.uploadByteStream,
        progressTrackingUploadStream.totalByteCount,
        filename: basename(mediaFile.path),
      ),
    );
    request.headers.addAll({
      "Authorization": "Bearer $authToken",
      "Content-Type": "multipart/form-data",
    });

    // Execute the request.
    Future<StreamedResponse> futureResponse = request.send();

    // Wrap up the progress stream and the HTTP response into a result for the caller.
    final result = UploadProgressWithResult(progressTrackingUploadStream, futureResponse, (response) async {
      // Parse the response data.
      final body = await response.stream.bytesToString();
      final bodyJson = jsonDecode(body);

      if (bodyJson["success"] != true) {
        _logApiError("upload media (${mediaFile.path})", bodyJson);
        throw Exception("Failed to upload media (${mediaFile.path}) - API error.");
      }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
      return Media.fromJson(bodyJson);
    });

    result.onComplete.then((_) {
      if (result.wasSuccessful != true) {
        CaptivateLogs.network.fine("Failed to upload media (${mediaFile.path}) - network error: ${result.error}");
      }
    });

    return result;
  }
}

class UploadProgressWithResult<EntityType> with Listenable {
  UploadProgressWithResult(this._uploadStream, this._response, this._parser) {
    _uploadStream.addListener(notifyListeners);
    _response.then(_onUploadComplete).catchError(_onError);
  }

  @override
  void dispose() {
    _uploadStream.dispose();
    super.dispose();
  }

  final HttpFileUploadStream _uploadStream;
  final Future<StreamedResponse> _response;
  final EntityParser<EntityType> _parser;

  void _onUploadComplete(StreamedResponse response) async {
    _isDone = true;
    if (200 < response.statusCode || response.statusCode >= 300) {
      _wasSuccessful = false;
      _error = "HTTP Error (${response.statusCode}): ${response.reasonPhrase}";
      _onComplete.complete();
      notifyListeners();
      return;
    }

    try {
      _responseEntity = await _parser(response);
    } catch (exception) {
      _wasSuccessful = false;
      _error = exception;
    }

    _onComplete.complete();
    notifyListeners();
  }

  void _onError(Object error) {
    _isDone = true;
    _wasSuccessful = false;
    _error = error;

    _onComplete.complete();
    notifyListeners();
  }

  double get progress => _uploadStream.progress;

  Future<void> get onComplete => _onComplete.future;
  final _onComplete = Completer();

  bool get isDone => _isDone;
  var _isDone = false;

  bool? get wasSuccessful => _wasSuccessful;
  bool? _wasSuccessful;

  EntityType? get responseEntity => _responseEntity;
  EntityType? _responseEntity;

  Object? get error => _error;
  Object? _error;
}

typedef EntityParser<EntityType> = FutureOr<EntityType?> Function(StreamedResponse);

class HttpFileUploadStream<ResponseType> with Listenable {
  HttpFileUploadStream(this._file) {
    totalByteCount = _file.lengthSync();

    // Wrap the file access in our own byte stream so we can track the upload progress.
    final fileStream = _file.openRead();
    uploadByteStream = ByteStream(
      fileStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            // Update our upload byte tracking.
            _uploadedByteCount += data.length;

            // Send the data to the server.
            sink.add(data);

            // Notify our listeners about the progress update.
            notifyListeners();
          },
        ),
      ),
    );
  }

  final File _file;

  late final ByteStream uploadByteStream;

  double get progress => uploadedByteCount / totalByteCount;

  int get uploadedByteCount => _uploadedByteCount;
  int _uploadedByteCount = 0;

  late final int totalByteCount;
}

mixin class Listenable {
  void dispose() {
    _listeners.clear();
  }

  final _listeners = <VoidCallback>{};

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @protected
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

typedef VoidCallback = void Function();

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
