import 'package:nyrna/argument_parser/argument_parser.dart';
import 'package:test/test.dart';

class _TestExit implements Exception {
  final int code;
  const _TestExit(this.code);
}

void main() {
  late ArgumentParser argParser;

  setUp(() {
    argParser = ArgumentParser();
  });

  group('ArgumentParser', () {
    test('singleton instance is accessible', () {
      expect(ArgumentParser.instance, isNotNull);
    });

    test('has expected values when given no arguments', () {
      expect(argParser.minimize, isNull);
      expect(argParser.toggleActiveWindow, isFalse);
      expect(argParser.verbose, isFalse);
      expect(argParser.suspendApp, isNull);
      expect(argParser.unsuspendApp, isNull);
      expect(argParser.appStatus, isNull);
      expect(argParser.listSuspendedApps, isFalse);
      expect(argParser.listGuiProcesses, isFalse);
    });

    test('parses arguments', () {
      argParser.parseArgs(['--no-minimize']);
      expect(argParser.minimize, isFalse);
    });

    test('parses multiple arguments', () {
      argParser.parseArgs(['--no-minimize', '--verbose']);
      expect(argParser.minimize, isFalse);
      expect(argParser.verbose, isTrue);
    });

    test('parses --toggle correctly', () {
      argParser.parseArgs(['--toggle']);
      expect(argParser.toggleActiveWindow, isTrue);
    });

    test('parses -t correctly', () {
      argParser.parseArgs(['-t']);
      expect(argParser.toggleActiveWindow, isTrue);
    });

    test('parses --suspend <app>', () {
      argParser.parseArgs(['--suspend', 'mpv']);
      expect(argParser.suspendApp, 'mpv');
      expect(argParser.hasExtendedCliAction, isTrue);
    });

    test('parses --unsuspend <app>', () {
      argParser.parseArgs(['--unsuspend', 'mpv']);
      expect(argParser.unsuspendApp, 'mpv');
      expect(argParser.hasExtendedCliAction, isTrue);
    });

    test('parses --status <app>', () {
      argParser.parseArgs(['--status', 'mpv']);
      expect(argParser.appStatus, 'mpv');
      expect(argParser.hasExtendedCliAction, isTrue);
    });

    test('parses --list-suspended', () {
      argParser.parseArgs(['--list-suspended']);
      expect(argParser.listSuspendedApps, isTrue);
      expect(argParser.hasExtendedCliAction, isTrue);
    });

    test('parses --list-gui', () {
      argParser.parseArgs(['--list-gui']);
      expect(argParser.listGuiProcesses, isTrue);
      expect(argParser.hasExtendedCliAction, isTrue);
    });

    test('rejects multiple actions', () {
      final parser = ArgumentParser(
        exitFunction: (code) => throw _TestExit(code),
        printLine: (_) {},
      );

      expect(
        () => parser.parseArgs(['--suspend', 'mpv', '--list-gui']),
        throwsA(
          isA<_TestExit>().having((e) => e.code, 'code', 0),
        ),
      );
    });
  });
}
