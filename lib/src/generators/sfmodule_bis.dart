import '../common.dart';
part 'sfmodule_bis.g.dart';

/// A generator for a hello world command-line application.
class SfModuleGenerator extends DefaultGenerator {
  SfModuleGenerator()
      : super('sfmodule-bis', 'Flutter module', 'A SF flutter module project.',
            categories: const ['dart']) {
    for (var file in decodeConcatenatedData(_data)) {
      addTemplateFile(file);
    }

    setEntrypoint(getFile('lib/main.dart'));
  }

  @override
  String getInstallInstructions() => '${super.getInstallInstructions()}\n'
      'run your app using `dart ${entrypoint.path}`.';
}
