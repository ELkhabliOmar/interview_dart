import 'package:interview_dart/interview_dart.dart';
import 'package:test/test.dart';

import 'package:test/test.dart';

void main() {
  test('ExecuteCommand : "command" should keep running', () async {
    final result_keepRunning = await executeCommand(['commands']);
    expect(result_keepRunning, isTrue);
  });

  test('ExecuteCommand : "command" should print available commands', () async {
    List expectedCommands = ["commands", "stop"];
    await expectLater(
      () => executeCommand(['commands']),
      prints("CLI - Available commands : ${expectedCommands}\n"),
    );
  });

  test('ExecuteCommand : "stop" should return False', () async {
    final result = await executeCommand(['stop']);
    expect(result, isFalse);
  });

  test(
      'executeCommand should print "CLI - Command not found" for unknown command',
      () async {
    await expectLater(
      () => executeCommand(['unknown']),
      prints("CLI - Command not found\n"),
    );
  });
}
