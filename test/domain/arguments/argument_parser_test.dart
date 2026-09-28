import 'package:flutter_test/flutter_test.dart';
import 'package:nyrna/argument_parser/argument_parser.dart';

void main() {
  group('ArgumentParser:', () {
    var argParser = ArgumentParser();

    setUp(() => argParser = ArgumentParser());

    test('toggle defaults to false', () {
      final args = <String>[];
      argParser.parseArgs(args);
      expect(argParser.toggleActiveWindow, false);
    });

    test('--toggle works', () {
      final args = ['--toggle'];
      argParser.parseArgs(args);
      expect(argParser.toggleActiveWindow, true);
    });

    test('-t works', () {
      final args = ['-t'];
      argParser.parseArgs(args);
      expect(argParser.toggleActiveWindow, true);
    });

    test('verbose defaults to false', () {
      final args = <String>[];
      argParser.parseArgs(args);
      expect(argParser.verbose, false);
    });

    test('--verbose works', () {
      final args = ['--verbose'];
      argParser.parseArgs(args);
      expect(argParser.verbose, true);
    });

    test('-v works', () {
      final args = ['-v'];
      argParser.parseArgs(args);
      expect(argParser.verbose, true);
    });

    test('--suspend works', () {
      final args = ['--suspend', 'mpv'];
      argParser.parseArgs(args);
      expect(argParser.suspendApp, 'mpv');
    });

    test('--unsuspend works', () {
      final args = ['--unsuspend', 'mpv'];
      argParser.parseArgs(args);
      expect(argParser.unsuspendApp, 'mpv');
    });

    test('--status works', () {
      final args = ['--status', 'mpv'];
      argParser.parseArgs(args);
      expect(argParser.appStatus, 'mpv');
    });

    test('--list-suspended works', () {
      final args = ['--list-suspended'];
      argParser.parseArgs(args);
      expect(argParser.listSuspendedApps, true);
    });

    test('--list-gui works', () {
      final args = ['--list-gui'];
      argParser.parseArgs(args);
      expect(argParser.listGuiProcesses, true);
    });
  });
}
