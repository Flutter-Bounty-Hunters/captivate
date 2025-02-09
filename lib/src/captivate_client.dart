import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:captivate/src/episode.dart';
import 'package:captivate/src/logging.dart';
import 'package:captivate/src/media.dart';
import 'package:captivate/src/show.dart';
import 'package:captivate/src/user.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
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

  Future<Media> uploadMediaWithDartIo({
    required String authToken,
    required String showId,
    required File mediaFile,
  }) async {
    CaptivateLogs.network.info("Upload media - show: $showId, media file: $mediaFile");

    if (!mediaFile.existsSync()) {
      throw Exception("Failed to upload media. File doesn't exist: ${mediaFile.path}");
    }

    // Create our own multi-part request to see what we're trying to send.
    final multipartRequest = MultipartFileUploadRequest(mediaFile)
      ..addHeader(HttpHeaders.authorizationHeader, "Bearer $authToken");

    final response = await multipartRequest.send('https://api.captivate.fm/shows/$showId/media');

    // // Collect file details.
    // CaptivateLogs.network.fine("Collecting media file data and metrics.");
    // final fileName = basename(mediaFile.path);
    // final mimeType = lookupMimeType(mediaFile.path);
    // final totalBytes = mediaFile.lengthSync();
    // int sentBytes = 0;
    //
    // if (mimeType == null) {
    //   throw Exception("Failed to upload media. Could not infer mime type for file: ${mediaFile.path}");
    // }
    // CaptivateLogs.network.finer(" - file name: $fileName");
    // CaptivateLogs.network.finer(" - mime type: $mimeType");
    // CaptivateLogs.network.finer(" - total bytes: $totalBytes");

    // Open connection to the server.
    // CaptivateLogs.network.fine("Opening POST connection to server.");
    // final request = await HttpClient().postUrl(
    //   Uri.parse('https://api.captivate.fm/shows/$showId/media'),
    // );
    //
    // multipartRequest.configureIoRequest(request);

    // // Set the headers.
    // CaptivateLogs.network.fine("Sending headers to the server.");
    // final multipartBoundary = "----MediaUploadBoundary(${DateTime.now().millisecondsSinceEpoch})";
    // // ^ Boundary includes a timestamp to ensure uniqueness of the boundary.
    //
    // final requestSizeCalculator = <int>[];
    // requestSizeCalculator
    //   ..addAll(utf8.encode("--$multipartBoundary\r\n"))
    //   ..addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'))
    //   ..addAll(utf8.encode('Content-Type: $mimeType\r\n'));
    // requestSizeCalculator.addAll(utf8.encode("\r\n"));
    // requestSizeCalculator.addAll(utf8.encode("--$multipartBoundary--\r\n"));
    //
    // request.headers
    //   ..set(HttpHeaders.contentTypeHeader, "multipart/form-data; boundary=$multipartBoundary")
    //   ..set(HttpHeaders.authorizationHeader, "Bearer $authToken")
    //   ..set(HttpHeaders.contentLengthHeader, "${totalBytes + requestSizeCalculator.length}");
    // print("${request.headers}");
    //
    // // Send media metadata.
    // CaptivateLogs.network.fine("Sending boundary and metadata for file part.");
    // final body = StringBuffer();
    // body
    //   ..write("--$multipartBoundary\r\n")
    //   ..write('Content-Disposition: form-data; name="file"; filename="$fileName"\r\n')
    //   ..write('Content-Type: $mimeType\r\n');
    // print(body.toString());
    // // request.write(body.toString());
    // request.add(utf8.encode(body.toString()));
    //
    // // Stream media data to server.
    // CaptivateLogs.network.fine("Uploading media file data.");
    // request.add(mediaFile.readAsBytesSync());
    // // final dataStream = mediaFile.openRead();
    // print("[data here]");
    // // await for (final chunk in dataStream) {
    // //   request.add(chunk);
    // //   await request.flush();
    // //   sentBytes += chunk.length;
    // //   CaptivateLogs.network.finer("Send progress (${(100 * sentBytes / totalBytes).round()}): $sentBytes/$totalBytes");
    // //   // TODO: report progress
    // // }
    //
    // // Close the file part of the request.
    // CaptivateLogs.network.fine("Sending the end boundary for the file part.");
    // print("\r\n");
    // // request.write("\r\n");
    // request.add(utf8.encode("\r\n"));
    // print("--$multipartBoundary--\r\n");
    // // request.write("--$multipartBoundary--\r\n");
    // request.add(utf8.encode("--$multipartBoundary--\r\n"));

    // Close the request to get the server response.
    // CaptivateLogs.network.fine("Closing the POST request and obtaining the response.");
    // final response = await request.close();

    if (200 <= response.statusCode && response.statusCode < 300) {
      CaptivateLogs.network.fine("Server response reported success.");

      // Parse the response data.
      final body = await response.transform(utf8.decoder).join();
      final bodyJson = jsonDecode(body);

      if (bodyJson["success"] != true) {
        _logApiError("upload media (${mediaFile.path})", bodyJson);
        throw Exception("Failed to upload media (${mediaFile.path}) - API error.");
      }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
      return Media.fromJson(bodyJson);
    } else {
      CaptivateLogs.network.warning("Failed to upload Media (${response.statusCode}): ${response.reasonPhrase}");
      CaptivateLogs.network.warning("Response headers:\n${response.headers}");
      CaptivateLogs.network.warning("Response body:\n${await response.transform(utf8.decoder).join()}");

      throw Exception("Failed to upload Media (${response.statusCode}): ${response.reasonPhrase}");
    }
  }

  Future<Media> uploadMediaDio({
    required String authToken,
    required String showId,
    required File mediaFile,
  }) async {
    CaptivateLogs.network.info("Upload media - show: $showId, media file: $mediaFile");

    final client = dio.Dio();
    final response = await client.post(
      'https://api.captivate.fm/shows/$showId/media',
      options: dio.Options(
        headers: {
          "Authorization": "Bearer $authToken",
        },
      ),
      data: dio.FormData.fromMap({
        'file': dio.MultipartFile.fromFileSync(
          mediaFile.path,
          filename: basename(mediaFile.path),
        ),
      }),
      onSendProgress: (int sent, int total) {
        print('Send Progress (${(100 * sent / total).round()}): $sent/$total');
      },
      onReceiveProgress: (int sent, int total) {
        print('Receive Progress (${(100 * sent / total).round()}): $sent/$total');
      },
    );

    print("Upload complete.");
    if (response.statusCode == 200) {
      print("Status code is good.");
      final data = response.data;
      print("Response data type: ${data.runtimeType}");
      print("Response data:\n$data");
      late final Map<String, dynamic> bodyJson;
      if (data is Map<String, dynamic>) {
        bodyJson = data;
      } else if (data is String) {
        bodyJson = jsonDecode(data);
      } else if (data is List<int>) {
        bodyJson = jsonDecode(utf8.decode(data));
      } else {
        CaptivateLogs.network.warning("Failed to parse response to Media upload. Unknown response data type: $data");
        throw Exception("Failed to parse response to Media upload. Unknown response data type: $data");
      }

      if (bodyJson["success"] != true) {
        _logApiError("upload media (${mediaFile.path})", bodyJson);
        throw Exception("Failed to upload media (${mediaFile.path}) - API reported 'success' as 'false'.");
      }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
      return Media.fromJson(bodyJson);
    } else {
      CaptivateLogs.network.warning("Failed to upload Media (${response.statusCode}): ${response.statusMessage}");
      // TODO: Log DIO network error.
      throw Exception("Failed to upload Media (${response.statusCode}): ${response.statusMessage}");
    }
  }

  Future<Media> uploadMediaCustomHttpRequest({
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

    print("HTTP package request:");
    print("URL: ${request.url}");
    print("Content length: ${request.contentLength}");
    print("Headers:\n${request.headers}");

    // Execute the request.
    StreamedResponse response = await request.send();

    if (200 <= response.statusCode && response.statusCode < 300) {
      final body = await response.stream.bytesToString();
      final bodyJson = jsonDecode(body);

      if (bodyJson["success"] != true) {
        _logApiError("upload media (${mediaFile.path})", bodyJson);
        throw Exception("Failed to upload media (${mediaFile.path}) - API error.");
      }

      CaptivateLogs.network.fine("Success:\n${const JsonEncoder.withIndent(" ").convert(bodyJson)}");
      return Media.fromJson(bodyJson);
    } else {
      CaptivateLogs.network.fine(
          "Failed to upload media (${mediaFile.path}) - HTTP error (${response.statusCode}): ${response.reasonPhrase}");
      throw Exception(
          "Failed to upload media (${mediaFile.path}) - HTTP error (${response.statusCode}): ${response.reasonPhrase}");
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

    print("HTTP package request:");
    print("URL: ${request.url}");
    print("Content length: ${request.contentLength}");
    print("Headers:\n${request.headers}");

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

class MultipartRequestWithProgress extends MultipartRequest {
  MultipartRequestWithProgress(
    super.method,
    super.url,
    this._onProgress,
  );

  final void Function(double progress) _onProgress;

  @override
  ByteStream finalize() {
    final sourceByteStream = super.finalize();
    // final streamWithProgress = ByteStreamReadProgressMonitor(
    //   sourceByteStream,
    //   contentLength,
    //   _onProgress,
    // );
    // return ByteStream(streamWithProgress);

    final int totalBytes = contentLength;
    int sentBytes = 0;

    return ByteStream(
      sourceByteStream.map((bytes) {
        sentBytes += bytes.length;
        _onProgress(sentBytes / totalBytes);

        return bytes;
      }),
    );

    // final StreamTransformer<List<int>, List<int>> progressTransformer = StreamTransformer.fromHandlers(
    //   handleData: (List<int> data, EventSink<List<int>> sink) {
    //     const int chunkSize = 1024;
    //     final int iterations = data.length ~/ chunkSize;
    //     final chunkReader = ChunkReader(data, chunkSize);
    //
    //     if (iterations > 1) {
    //       while (chunkReader.hasNextChunk()) {
    //         final chunk = chunkReader.readNextChunk();
    //         if (chunk.isEmpty) break;
    //
    //         sentBytes += chunk.length;
    //         _onProgress(sentBytes / totalBytes);
    //         sink.add(chunk);
    //       }
    //     } else {
    //       sentBytes += data.length;
    //       _onProgress(sentBytes / totalBytes);
    //       sink.add(data);
    //     }
    //   },
    //   handleError: (Object error, StackTrace stack, EventSink<List<int>> sink) {
    //     sink.addError(error, stack);
    //     sink.close();
    //   },
    //   handleDone: (EventSink<List<int>> sink) {
    //     sink.close();
    //   },
    // );
    //
    // return ByteStream(
    //   sourceByteStream.transform(progressTransformer),
    // );
  }
}

class ChunkReader {
  final List<int> data;
  final int chunkSize;
  int currentIndex = 0;

  ChunkReader(this.data, this.chunkSize);

  bool hasNextChunk() {
    return currentIndex < data.length;
  }

  List<int> readNextChunk() {
    if (currentIndex >= data.length) {
      return [];
    }

    final end = (currentIndex + chunkSize) > data.length ? data.length : currentIndex + chunkSize;
    final chunk = data.sublist(currentIndex, end);
    currentIndex = end;
    return chunk;
  }
}

class ByteStreamReadProgressMonitor extends Stream<List<int>> {
  ByteStreamReadProgressMonitor(this._source, this._totalByteCount, this._onProgress);

  final Stream<List<int>> _source;
  final int _totalByteCount;
  int _bytesRead = 0;
  final void Function(double progress) _onProgress;

  @override
  Future<int> get length => Future.value(_totalByteCount);

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _bytesRead = 0;

    return _source.listen(
      (chunk) {
        _bytesRead += chunk.length;
        _onProgress(_bytesRead / _totalByteCount);

        if (onData != null) {
          onData(chunk);
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class UploadProgressWithResult<EntityType> {
  UploadProgressWithResult(this._uploadStream, this._response, this._parser) {
    _uploadStream.addListener(_onUploadChange);
    _response.then(_onUploadComplete).catchError(_onError);
  }

  void dispose() {
    _uploadStream.dispose();
  }

  final HttpFileUploadStream _uploadStream;
  final Future<StreamedResponse> _response;
  final EntityParser<EntityType> _parser;

  void _onUploadChange() {
    _progress.add(_uploadStream.progress);
  }

  void _onUploadComplete(StreamedResponse response) async {
    _isDone = true;
    if (200 < response.statusCode || response.statusCode >= 300) {
      _wasSuccessful = false;
      _error = "HTTP Error (${response.statusCode}): ${response.reasonPhrase}";
      _onComplete.complete();
      return;
    }

    try {
      _responseEntity = await _parser(response);
    } catch (exception) {
      _wasSuccessful = false;
      _error = exception;
    }

    _onComplete.complete();
  }

  void _onError(Object error) {
    _isDone = true;
    _wasSuccessful = false;
    _error = error;

    _onComplete.complete();
  }

  Stream<double> get progress => _progress.stream;
  final _progress = StreamController<double>();

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

class MultipartFileUploadRequest {
  MultipartFileUploadRequest(this._file);

  final File _file;

  void addHeader(String key, String value) {
    _headers[key] = value;
  }

  final _headers = <String, String>{};

  void configureIoRequest(HttpClientRequest request) {
    if (!_isFinalized) {
      finalize();
    }

    // Set headers.
    for (final entry in _headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    // Write encoded data to the request.
    for (final piece in _encodedRequestPieces) {
      request.add(piece);
    }
  }

  Stream<List<int>> createAsStream() async* {
    if (!_isFinalized) {
      // Collect all pieces, encode them, and set the request content length.
      finalize();
    }

    final piecesAsStreams = [
      _encodePlainTextToStream(_filePartOpening),
      _encodePlainTextToStream(_newline),
      for (final metadata in _fileMetadata) ...[
        _encodePlainTextToStream(metadata),
        _encodePlainTextToStream(_newline),
      ],
      _encodePlainTextToStream(_newline),
      _file.openRead(),
      _encodePlainTextToStream(_newline),
      _encodePlainTextToStream(_filePartClosing),
    ];

    for (final stream in piecesAsStreams) {
      yield* stream;
    }
  }

  ByteStream _encodePlainTextToStream(String content) => ByteStream.fromBytes(utf8.encode(content));

  Future<HttpClientResponse> send(String url) async {
    if (!_isFinalized) {
      // Collect all pieces, encode them, and set the request content length.
      finalize();
    }

    // Time the code.
    final stopwatch = Stopwatch();
    stopwatch.start();

    // Configure destination for request.
    final request = await HttpClient().postUrl(Uri.parse(url));
    print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Request created.");

    // Set headers.
    for (final entry in _headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Headers set.");

    // Write encoded data to the request.
    print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Adding request data pieces.");
    print("-----");
    for (int i = 0; i < _encodedRequestPieces.length; i += 1) {
      final rawPiece = _rawRequestPieces[i];
      final encodedPiece = _encodedRequestPieces[i];

      print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Adding piece:");
      if (rawPiece is String) {
        print(" - String piece: '$rawPiece'");
        request.add(encodedPiece);
        print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Done adding encoded String.");
        continue;
      }

      // This data isn't a String, it's byte data. We expect that this is the file data.
      print(" - Data piece. Length: ${encodedPiece.length} bytes.");
      request.add(encodedPiece);
      print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Done adding byte data.");
    }
    print("-----");

    print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Closing request.");
    final response = await request.close();
    print("(${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(3)}) Request is now closed.");

    return response;
  }

  bool _isFinalized = false;
  void finalize() {
    if (_isFinalized) {
      throw Exception("Can't finalize MultipartFileUploadRequest because it's already finalized.");
    }
    _isFinalized = true;

    _assembleRequestPieces();
    _encodeRequestPieces();

    // Forcibly set to a multipart request and set the request content length.
    _headers[HttpHeaders.contentTypeHeader] = "multipart/form-data; boundary=$_filePartBoundary";
    _headers[HttpHeaders.contentLengthHeader] = "${_calculateRequestByteLength()}";

    print("Multi-part file upload request:");
    for (final entry in _headers.entries) {
      print("${entry.key}: ${entry.value}");
    }
    print("");
    final debugLines = StringBuffer();
    for (final piece in _rawRequestPieces) {
      if (piece is! String) {
        debugLines.write("[data]");
        continue;
      }
      debugLines.write(piece);
    }
    print(debugLines.toString());
    print('>>>>>>>>>>>>>>>>>>>');
  }

  late final List<Object> _rawRequestPieces;
  void _assembleRequestPieces() {
    _rawRequestPieces = [
      _filePartOpening,
      _newline,
      for (final metadata in _fileMetadata) ...[
        metadata,
        _newline,
      ],
      _newline,
      _file.readAsBytesSync(),
      _newline,
      _filePartClosing,
    ];
  }

  late final List<List<int>> _encodedRequestPieces;
  void _encodeRequestPieces() {
    _encodedRequestPieces = _rawRequestPieces
        .map((piece) => piece is String ? utf8.encode(piece) : piece as List<int>)
        .toList(growable: false);
  }

  int _calculateRequestByteLength() {
    return _encodedRequestPieces.fold(0, (prev, piece) => prev + piece.length);
  }

  String get _filePartOpening {
    return "--$_filePartBoundary";
  }

  List<String> get _fileMetadata {
    return [
      'Content-Disposition: form-data; name="file"; filename="${basename(_file.path)}"',
      "Content-Type: ${lookupMimeType(_file.path)}",
    ];
  }

  String get _filePartClosing {
    return "--$_filePartBoundary--";
  }

  String get _filePartBoundary => "file";

  String get _newline => "\r\n";
}
