import 'dart:io';

import '../argument_parser/argument_parser.dart';
import '../native_platform/native_platform.dart';

class CliActionRunner {
  final NativePlatform _nativePlatform;
  final ProcessRepository _processRepository;
  final void Function(Object?) _printLine;

  const CliActionRunner({
    required NativePlatform nativePlatform,
    required ProcessRepository processRepository,
    void Function(Object?)? printLine,
  }) : _nativePlatform = nativePlatform,
       _processRepository = processRepository,
       _printLine = printLine ?? stdout.writeln;

  Future<int> run(ArgumentParser args) async {
    if (args.suspendApp != null) {
      return _suspend(args.suspendApp!);
    }
    if (args.unsuspendApp != null) {
      return _unsuspend(args.unsuspendApp!);
    }
    if (args.appStatus != null) {
      return _status(args.appStatus!);
    }
    if (args.listSuspendedApps) {
      return _listSuspended();
    }
    if (args.listGuiProcesses) {
      return _listGuiProcesses();
    }

    return 0;
  }

  Future<int> _suspend(String query) async {
    final matches = await _matchingProcesses(query);
    if (matches.isEmpty) {
      _printLine('No matching GUI processes found for "$query".');
      return 1;
    }

    var failed = false;

    for (final process in matches) {
      final status = await _processRepository.getProcessStatus(process.pid);
      if (status == ProcessStatus.suspended) {
        _printLine(
          '${process.pid}\t${process.executable}\talready_suspended\t${process.title}',
        );
        continue;
      }

      final success = await _processRepository.suspend(process.pid);
      if (!success) failed = true;
      final state = success ? 'suspended' : 'suspend_failed';
      _printLine('${process.pid}\t${process.executable}\t$state\t${process.title}');
    }

    return failed ? 1 : 0;
  }

  Future<int> _unsuspend(String query) async {
    final matches = await _matchingProcesses(query);
    if (matches.isEmpty) {
      _printLine('No matching GUI processes found for "$query".');
      return 1;
    }

    var failed = false;

    for (final process in matches) {
      final status = await _processRepository.getProcessStatus(process.pid);
      if (status == ProcessStatus.normal) {
        _printLine(
          '${process.pid}\t${process.executable}\talready_running\t${process.title}',
        );
        continue;
      }

      final success = await _processRepository.resume(process.pid);
      if (!success) failed = true;
      final state = success ? 'running' : 'unsuspend_failed';
      _printLine('${process.pid}\t${process.executable}\t$state\t${process.title}');
    }

    return failed ? 1 : 0;
  }

  Future<int> _status(String query) async {
    final matches = await _matchingProcesses(query);
    if (matches.isEmpty) {
      _printLine('No matching GUI processes found for "$query".');
      return 1;
    }

    for (final process in matches) {
      final status = await _processRepository.getProcessStatus(process.pid);
      _printLine(
        '${process.pid}\t${process.executable}\t${status.name}\t${process.title}',
      );
    }

    return 0;
  }

  Future<int> _listSuspended() async {
    final all = await _allGuiProcesses();
    final suspended = <_GuiProcess>[];

    for (final process in all) {
      final status = await _processRepository.getProcessStatus(process.pid);
      if (status == ProcessStatus.suspended) {
        suspended.add(process);
      }
    }

    if (suspended.isEmpty) {
      _printLine('No suspended GUI processes found.');
      return 0;
    }

    for (final process in suspended) {
      _printLine(
        '${process.pid}\t${process.executable}\t${ProcessStatus.suspended.name}\t${process.title}',
      );
    }

    return 0;
  }

  Future<int> _listGuiProcesses() async {
    final all = await _allGuiProcesses();
    if (all.isEmpty) {
      _printLine('No GUI processes found.');
      return 0;
    }

    for (final process in all) {
      final status = await _processRepository.getProcessStatus(process.pid);
      _printLine(
        '${process.pid}\t${process.executable}\t${status.name}\t${process.title}',
      );
    }

    return 0;
  }

  Future<List<_GuiProcess>> _matchingProcesses(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final all = await _allGuiProcesses();
    final matches = all.where((process) {
      final executable = process.executable.toLowerCase();
      final title = process.title.toLowerCase();
      return executable.contains(normalizedQuery) || title.contains(normalizedQuery);
    }).toList();
    return matches;
  }

  Future<List<_GuiProcess>> _allGuiProcesses() async {
    final windows = await _nativePlatform.windows(showHidden: true);
    final byPid = <int, _GuiProcess>{};

    for (final window in windows) {
      byPid.putIfAbsent(
        window.process.pid,
        () => _GuiProcess(
          pid: window.process.pid,
          executable: window.process.executable,
          title: window.title,
        ),
      );
    }

    final processes = byPid.values.toList()
      ..sort((a, b) {
        final executableComparison = a.executable.toLowerCase().compareTo(
          b.executable.toLowerCase(),
        );
        if (executableComparison != 0) return executableComparison;
        return a.pid.compareTo(b.pid);
      });

    return processes;
  }
}

class _GuiProcess {
  final int pid;
  final String executable;
  final String title;

  const _GuiProcess({
    required this.pid,
    required this.executable,
    required this.title,
  });
}
