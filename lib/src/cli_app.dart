import 'package:args/args.dart';
import 'package:shjcli/src/module_create.dart';
import 'cli_logger.dart';
import 'constants.dart';

class CliApp {
  final CliLogger logger;

  CliApp(this.logger) : assert(logger != null);

  Future process(List<String> args) async {
    final argParser = _createArgParser();
    ArgResults argResults;
    try {
      argResults = argParser.parse(args);
    } catch (e, st) {
      if (e is FormatException) {
        _out('Error: ${e.message}');
        return Future.error(ArgError(e.message));
      } else {
        _out('Error: ${e.message}');
        return Future.error(e, st);
      }
    }

    if (argResults[argsVersion]) {
      _out('$appName version: $packageVersion');
      return Future.value();
    }

    if (argResults[argsHelp] || args.isEmpty) {
      _usage(argParser);
      return Future.value();
    }

    if (argResults[argsModuleName] == null) {
      _out('Error: 必须给创建组件的命名');
      return Future.error(ArgError('Error: 必须给创建组件的命名'));
    } else {
      if (argResults.rest.isNotEmpty) {
        _out('Error: 参数错误，请使用 --help 查询使用帮助.\n');
        _usage(argParser);
        return Future.error(ArgError('无效参数'));
      }

      final moduleCreate = ModuleCreate();
      await moduleCreate.create(
        appName: argResults[argsModuleName],
        mode: argResults[argsMode],
      );
      return Future.value();
    }

    // if (argResults[argsMode] != null) {
    //   print('$argResults[argsMode]');
    // }

    // if (argResults.rest.isEmpty) {
    //   _out('未指定代码生成器.\n');
    //   _usage(argParser);
    //   return Future.error(ArgError('未指定代码生成器'));
    // }

    // final generatorName = argResults.rest.first;
  }

  ArgParser _createArgParser() => ArgParser()
    ..addFlag(argsHelp, abbr: 'h', negatable: false, help: 'Show help!')
    ..addFlag(argsVersion, abbr: 'v', negatable: false, help: '当前版本')
    ..addOption(argsModuleName, abbr: 'n', help: '组件名称，不能为空')
    ..addOption(argsMode,
        abbr: 'm',
        allowed: [argsModeFunc, argsModeBis],
        defaultsTo: argsModeBis,
        help: '创建的组件类型 \n$argsModeFunc - 纯功能组件 \n$argsModeBis - 带业务组件');

  void _out(String str) => logger.stdout(str);

  void _usage(ArgParser argParser) {
    _out('$appName 是为组件化而生的一个简单易用的命令行程序，自动为你生成相应的模板代码');
    _out('');
    _out('如何使用 $appName  点击: ，如果有问题请问我');
    _out(argParser.usage);
    _out('');
    _out('已有的代码生成器:');
  }
}

class ArgError implements Exception {
  final String message;
  ArgError(this.message);

  @override
  String toString() => message;
}
