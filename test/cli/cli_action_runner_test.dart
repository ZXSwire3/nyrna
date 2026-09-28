import 'package:nyrna/argument_parser/argument_parser.dart';
import 'package:nyrna/cli/cli_action_runner.dart';
import 'package:nyrna/native_platform/native_platform.dart';
import 'package:test/test.dart';

class FakeNativePlatform implements NativePlatform {
  final List<Window> windowsToReturn;

  FakeNativePlatform(this.windowsToReturn);

  @override
  Window? activeWindow;

  @override
  SessionType? get sessionType => null;

  @override
  Future<void> checkActiveWindow() async {}

  @override
  Future<bool> checkDependencies() async => true;

  @override
  Future<int> currentDesktop() async => 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> minimizeWindow(String windowId) async => true;

  @override
  Future<bool> restoreWindow(String windowId) async => true;

  @override
  Future<List<Window>> windows({bool showHidden = false}) async => windowsToReturn;
}

class FakeProcessRepository extends ProcessRepository {
  final Map<int, ProcessStatus> statuses;
  final Set<int> suspended = {};
  final Set<int> resumed = {};

  FakeProcessRepository(this.statuses);

  @override
  Future<bool> exists(int pid) async => statuses.containsKey(pid);

  @override
  Future<Process> getProcess(int pid) async => Process(
    executable: 'test',
    pid: pid,
    status: statuses[pid] ?? ProcessStatus.unknown,
  );

  @override
  Future<ProcessStatus> getProcessStatus(int pid) async {
    return statuses[pid] ?? ProcessStatus.unknown;
  }

  @override
  Future<bool> resume(int pid) async {
    resumed.add(pid);
    statuses[pid] = ProcessStatus.normal;
    return true;
  }

  @override
  Future<bool> suspend(int pid) async {
    suspended.add(pid);
    statuses[pid] = ProcessStatus.suspended;
    return true;
  }
}

void main() {
  final windows = [
    const Window(
      id: '1',
      process: Process(
        executable: 'mpv',
        pid: 101,
        status: ProcessStatus.unknown,
      ),
      title: 'Video Player',
    ),
    const Window(
      id: '2',
      process: Process(
        executable: 'firefox',
        pid: 202,
        status: ProcessStatus.unknown,
      ),
      title: 'Documentation',
    ),
  ];

  late FakeNativePlatform nativePlatform;
  late FakeProcessRepository processRepository;
  late List<String> output;
  late CliActionRunner runner;

  setUp(() {
    nativePlatform = FakeNativePlatform(windows);
    processRepository = FakeProcessRepository({
      101: ProcessStatus.normal,
      202: ProcessStatus.suspended,
    });
    output = [];
    runner = CliActionRunner(
      nativePlatform: nativePlatform,
      processRepository: processRepository,
      printLine: (line) => output.add('$line'),
    );
  });

  test('list gui prints all gui processes', () async {
    final parser = ArgumentParser()..parseArgs(['--list-gui']);
    final code = await runner.run(parser);

    expect(code, 0);
    expect(output.length, 2);
    expect(output.first, contains('mpv'));
    expect(output.last, contains('firefox'));
  });

  test('list suspended only prints suspended gui processes', () async {
    final parser = ArgumentParser()..parseArgs(['--list-suspended']);
    final code = await runner.run(parser);

    expect(code, 0);
    expect(output.length, 1);
    expect(output.single, contains('firefox'));
    expect(output.single, contains('suspended'));
  });

  test('status returns non-zero when no process matches', () async {
    final parser = ArgumentParser()..parseArgs(['--status', 'notepad']);
    final code = await runner.run(parser);

    expect(code, 1);
    expect(output.single, contains('No matching GUI processes found'));
  });

  test('suspend suspends matching running process', () async {
    final parser = ArgumentParser()..parseArgs(['--suspend', 'mpv']);
    final code = await runner.run(parser);

    expect(code, 0);
    expect(processRepository.suspended, contains(101));
    expect(output.single, contains('suspended'));
  });

  test('unsuspend resumes matching suspended process', () async {
    final parser = ArgumentParser()..parseArgs(['--unsuspend', 'firefox']);
    final code = await runner.run(parser);

    expect(code, 0);
    expect(processRepository.resumed, contains(202));
    expect(output.single, contains('running'));
  });
}
