import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:interview_dart/server.dart';

/// The main start 2 isolates :
///    - main one that handle the Command Line Interface (CLI). This one should be modified by the candidate.
///    - serverIsolate that create an handle a fake server to reponse to the call.

Map<String, dynamic> protocols = {};
List<Map<String, dynamic>> results = [];

void main(List<String> arguments) async {
  startServerIsolate();

  // Wait to let the server isolate initialize properly
  await Future.delayed(Duration(milliseconds: 100));

  bool running = true;

  while (running) {
    print("\r\n>> Enter your command :");
    String? userInput = stdin.readLineSync();
    if (userInput == null) continue;
    List<String> commands = userInput.split(' ');
    running = await executeCommand(commands);
    await Future.delayed(Duration(milliseconds: 10));
  }
}

void startServerIsolate() {
  // Create a new isolate and start the server within it
  Isolate.spawn(serverEntryPoint, null);
}

Future<void> serverEntryPoint(_) async {
  Server server = Server();
  await server.listen();
}

Future<bool> executeCommand(List<String> arguments) async {
  bool keepRunning = true;
  List<String> availableCommands = [
    "load",
    "protocols",
    "run_protocol",
    "results",
    "all_results",
    "commands",
    "stop"
  ];

  switch (arguments[0]) {
    case 'commands':
      print("CLI - Available commands : $availableCommands");
      break;
    case 'load':
      if (arguments.length >= 2) {
        await loadProtocols(arguments[1]);
      } else {
        print("CLI - Invalid arguments for load");
      }
      break;
    case 'protocols':
      if (arguments.length >= 2) {
        if (arguments[1] == 'ls') {
          listProtocols();
        } else {
          displayProtocol(arguments[1]);
        }
      } else {
        print("CLI - Invalid arguments for protocols");
      }
      break;
    case 'run_protocol':
      if (arguments.length >= 2) {
        await runProtocol(arguments[1]);
      } else {
        print("CLI - Invalid arguments for run_protocol");
      }
      break;
    case 'results':
      await getResults();
      break;
    case 'all_results':
      displayAllResults();
      break;
    case 'stop':
      print('CLI - Program will stop');
      keepRunning = false;
      break;
    default:
      print('CLI - Command not found');
  }

  return keepRunning;
}

Future<void> loadProtocols(String path) async {
  try {
    String content = await File(path).readAsString();
    var jsonData = jsonDecode(content);
    if (jsonData is List) {
      for (var item in jsonData) {
        if (item is Map<String, dynamic>) {
          protocols[item['name']] = item;
        }
      }
    } else if (jsonData is Map<String, dynamic>) {
      protocols = jsonData;
    } else {
      print("CLI - Invalid JSON format");
      return;
    }
    print("CLI - Loading ok");
  } catch (e) {
    print("CLI - Error loading protocols: $e");
  }
}

void listProtocols() {
  if (protocols.isEmpty) {
    print("CLI - No protocols loaded");
    return;
  }

  print("CLI - Loaded protocols:");
  protocols.forEach((key, value) {
    print("  - $key");
  });
}

void displayProtocol(String name) {
  if (protocols.containsKey(name)) {
    print("CLI - Protocol parameters for $name:");
    print(protocols[name]);
  } else {
    print("CLI - Protocol not found");
  }
}

Future<void> runProtocol(String name) async {
  if (!protocols.containsKey(name)) {
    print("CLI - Protocol not found");
    return;
  }

  stdout.write(">> How many trials do you want? (Recommended ${protocols[name]['trials']}): ");
  String? trialsInput = stdin.readLineSync();
  int trials = int.tryParse(trialsInput ?? '') ?? protocols[name]['trials'];

  stdout.write(">> What is the color of the target? (Recommended ${protocols[name]['color']}): ");
  String? colorInput = stdin.readLineSync();
  String color = colorInput?.isNotEmpty == true ? colorInput : protocols[name]['color'];

  print(">> You chose $trials trials and color $color.");

  var response = await http.post(
    Uri.parse('http://localhost:8080/run_protocol'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'description': protocols[name]['description'],
      'trials': trials,
      'color': color
    }),
  );

  if (response.statusCode == 200) {
    print("CLI - Command sent to the server");
  } else {
    print("CLI - Failed to send command to the server");
  }
}

Future<void> getResults() async {
  var client = http.Client();
  try {
    var request = await client.send(http.Request('GET', Uri.parse('http://localhost:8080/result_event')));
    var stream = request.stream.transform(utf8.decoder);

    await for (var data in stream) {
      print("log - Received raw data: $data");  // Print raw data
      try {
        // Split results since events sent by the server might be concatenated
        var events = data.split('\n');
        for (var event in events) {
          if (event.isNotEmpty) {
            var result = jsonDecode(event.replaceFirst('data: ', ''));
            results.add(result);
          }
        }
      } catch (e) {
        print("log - Error decoding data: $e");
      }
    }
    print("CLI - Result saved.");
  } catch (e) {
    print("CLI - Error receiving results: $e");
  } finally {
    client.close();
  }
}


void displayAllResults() {
  if (results.isEmpty) {
    print("CLI - No results to display");
    return;
  }

  Map<String, List<num>> aggregateResults = {};
  for (var result in results) {
    String protocol = result['param']['color'];
    if (!aggregateResults.containsKey(protocol)) {
      aggregateResults[protocol] = [0, 0, 0];
    }
    aggregateResults[protocol]![0] += result['Result']['Latency_left_ms'] as num;
    aggregateResults[protocol]![1] += result['Result']['Latency_right_ms'] as num;
    aggregateResults[protocol]![2] += 1;
  }

  print("CLI - All results:");
  aggregateResults.forEach((protocol, values) {
    print("  $protocol - average {Latency_left_ms :  ${values[0] / values[2]}, Latency_right_ms :  ${values[1] / values[2]}}");
  });
}
 
