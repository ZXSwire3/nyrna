import 'dart:io';

import 'package:args/args.dart';

/// Message to be displayed if Nyrna is called with an unknown argument.
const _helpTextGreeting = '''
Nyrna - Suspend games and applications.


Run Nyrna without any arguments to launch the GUI.

Supported arguments:

''';

/// Parse command-line arguments.
class ArgumentParser {
  bool? minimize;
  bool toggleActiveWindow = false;
  bool verbose = false;
  String? suspendApp;
  String? unsuspendApp;
  String? appStatus;
  bool listSuspendedApps = false;
  bool listGuiProcesses = false;

  final void Function(int) _exitFunction;
  final void Function(Object?) _printLine;

  /// Singleton instance.
  static late ArgumentParser instance;

  ArgumentParser({
    void Function(int)? exitFunction,
    void Function(Object?)? printLine,
  }) : _exitFunction = exitFunction ?? exit,
       _printLine = printLine ?? stdout.writeln {
    instance = this;
  }

  final _parser = ArgParser(usageLineLength: 80);

  bool get hasCliAction =>
      toggleActiveWindow ||
      suspendApp != null ||
      unsuspendApp != null ||
      appStatus != null ||
      listSuspendedApps ||
      listGuiProcesses;

  bool get hasExtendedCliAction =>
      suspendApp != null ||
      unsuspendApp != null ||
      appStatus != null ||
      listSuspendedApps ||
      listGuiProcesses;

  /// Parse received arguments.
  void parseArgs(List<String> args) {
    _parser
      ..addFlag(
        'minimize',
        defaultsTo: true,
        callback: (bool value) {
          /// We only want to register when the user calls the negated version of
          /// this flag: `--no-minimize`. Otherwise the [minimize] value will be
          /// null and the UI-set preference can be checked.
          if (value == true) {
            return;
          } else {
            minimize = false;
          }
        },
        help: '''
Used with the `toggle` flag, `no-minimize` instructs Nyrna not to automatically minimize / restore the active window - it will be suspended / resumed only.''',
      )
      ..addFlag(
        'toggle',
        abbr: 't',
        negatable: false,
        callback: (bool value) => toggleActiveWindow = value,
        help:
            'Toggle the suspend / resume state for the active window. \n'
            '❗Please note this will immediately suspend the active window, and '
            'is intended to be used with a hotkey - be sure not to run this '
            'from a terminal and accidentally suspend your terminal! ❗',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        callback: (bool value) => verbose = value,
        help: 'Output verbose logs for troubleshooting and debugging.',
      )
      ..addOption(
        'suspend',
        valueHelp: 'app',
        callback: (value) => suspendApp = value,
        help:
            'Suspend GUI process(es) matching this executable or window title.',
      )
      ..addOption(
        'unsuspend',
        valueHelp: 'app',
        callback: (value) => unsuspendApp = value,
        help:
            'Resume GUI process(es) matching this executable or window title.',
      )
      ..addOption(
        'status',
        valueHelp: 'app',
        callback: (value) => appStatus = value,
        help:
            'Show suspend status of GUI process(es) matching this executable or window title.',
      )
      ..addFlag(
        'list-suspended',
        negatable: false,
        callback: (value) => listSuspendedApps = value,
        help: 'Show all actively suspended GUI processes.',
      )
      ..addFlag(
        'list-gui',
        negatable: false,
        callback: (value) => listGuiProcesses = value,
        help: 'Show all detected GUI processes.',
      );

    final helpText = '$_helpTextGreeting${_parser.usage}\n\n';

    try {
      final result = _parser.parse(args);

      final actionCount = [
        toggleActiveWindow,
        suspendApp != null,
        unsuspendApp != null,
        appStatus != null,
        listSuspendedApps,
        listGuiProcesses,
      ].where((e) => e).length;

      final noMinimizeWithoutToggle =
          result.wasParsed('minimize') && !toggleActiveWindow;

      if (actionCount > 1 || noMinimizeWithoutToggle) {
        _printLine(helpText);
        _exitFunction(0);
      }

      if (result.rest.isNotEmpty) {
        _printLine(helpText);
        _exitFunction(0);
      }
    } on ArgParserException {
      _printLine(helpText);
      _exitFunction(0);
    }
  }
}
