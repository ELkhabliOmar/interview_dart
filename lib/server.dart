
/// This file should not need modify (except if you find a bug.)

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Class to run an HTTP server on port 8080.
/// Two routes are available:
/// - POST /run_protocol: To load and run a protocol
/// - GET /result_event: To return the results of each trial as Server-Sent Events
class Server {
  // parameters used

  int trialsLoop = 0;
  String paramColor = "";

  /// Listen to incoming requests and execute the desired operation.
  /// Limitation: Runs only in one thread.
  Future<void> listen() async {
    resetParam();
    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      8080,
    );

    print('Server is running on http://${server.address.host}:${server.port}');
    await for (var request in server) {
      if (request.method == 'POST' && request.uri.path == '/run_protocol') {
        try {
          logRequest(request);
          await runProtocolRequest(request);
        } catch (e) {
          print("Server: Error while parsing /run_protocol $e");
          invalidJson(request);
        }
        
      } else if (request.method == 'GET' && request.uri.path == '/result_event') {
        try {
          executeResultEvent(request.response);
        } catch (e) {
          invalidJson(request);
        }
        logRequest(request);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
        logRequest(request);
      }
    }
  }

  /// Simple logger to display the result of the request
  void logRequest(HttpRequest request) {
    print("Server : ${DateTime.now()} - POST ${request.requestedUri.path} ${request.response.statusCode}");
  }

  /// Check if the request is valid and respond after setting up the parameters.
  Future<void> runProtocolRequest(HttpRequest request) async {
    final requestBodyBytes = await request.fold<List<int>>([], (buffer, data) => buffer + data);
    final requestBody = utf8.decode(requestBodyBytes);
    final jsonData = jsonDecode(requestBody);

    if (jsonData.containsKey("name") &&
        jsonData.containsKey("description") &&
        jsonData.containsKey("trials") &&
        jsonData.containsKey("color")) {
      print("Server: Protocol ${jsonData["name"]} will be played for ${jsonData["trials"]} trials with a color ${jsonData["color"]}");

      trialsLoop = jsonData["trials"];
      paramColor = jsonData["color"];

      request.response
        ..statusCode = HttpStatus.ok
        ..write({"data": "Protocol will be played"})
        ..close();
    } else {
      invalidJson(request);
    }
  }

  /// Response for invalid JSON.
  void invalidJson(HttpRequest request) {
    print("Server: Invalid request");

    request.response
      ..statusCode = HttpStatus.badRequest
      ..write('Bad Request: Invalid JSON')
      ..close();
  }

  /// Run an event loop with the result data.
  /// A protocol should be loaded before calling this route,
  /// otherwise it just closes the connection without any data.
  /// Note: The mocked process executes tasks in the background (delay between event messages)
  /// and the trial results could be in a wrong order since they are sent as soon as they are finished.
  Future<void> executeResultEvent(HttpResponse response) async {
    response.headers
      ..contentType = ContentType('text', 'event-stream')
      ..set('transfer-encoding', 'chunked')
      ..set('connection', 'keep-alive')
      ..set('cache-control', 'no-cache');
    final socket = await response.detachSocket();

    if (trialsLoop <= 0) {
      resetParam();
      await socket.close();
      return;
    }

   
    List result = [];
    for (var i = 0; i < trialsLoop; i++) {
         Map data = {
        "trial": i,
        "param": {"color": paramColor},
        "Result": {
          "Latency_left_ms": Random().nextInt(100),
          "Latency_right_ms": Random().nextInt(100)
        }
      };
      result.add(data);
    }

    result.shuffle();

    for (var i = 0; i < trialsLoop; i++) {
      int delayMs = Random().nextInt(900);
      await Future.delayed(Duration(milliseconds: delayMs));
      final dataString = jsonEncode(result[i]);
      final data = utf8.encode(' data: $dataString \n');
      socket.add(utf8.encode(data.length.toRadixString(16)));
      socket.add([13, 10]);
      socket.add(data);
      socket.add([13, 10]);
      await socket.flush();
    }
    socket.add([48, 13, 10, 13, 10]);

    resetParam();

    await socket.close();
  }

  // Reset parameters
  void resetParam() {
    trialsLoop = 0;
    paramColor = "";
  }
}

