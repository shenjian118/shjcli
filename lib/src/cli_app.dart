import 'dart:async';
import 'dart:io' as io;
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:shjcli/shjcli.dart';

class CliApp {
  final List<Generator> generators;
  final CliLogger logger;
  // io.Directory _cwd;
  GeneratorTarget target;

  CliApp(this.generators, this.logger)
      : assert(generators != null && logger != null) {
    generators.sort();
  }

  // io.Directory get cwd => _cwd ?? io.Directory.current;

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
      if (argResults.rest.isEmpty) {
        _out('Error: 未指定代码生成器 --help 查询使用帮助.\n');
        _usage(argParser);
        return Future.error(ArgError('未指定代码生成器'));
      }

      if (argResults.rest.length >= 2) {
        _out('Error: 参数赋值错误 --help 查询使用帮助.\n');
        // _usage(argParser);
        return Future.error(ArgError('参数赋值错误'));
      }

      /// 生成器
      final generatorName = argResults.rest.first;
      final generator = _getGenerator(generatorName);

      if (generator == null) {
        _out("'$generatorName' is not a valid generator.\n");
        _usage(argParser);
        return Future.error(ArgError('参数赋值错误'));
      }

      /// 文件路径
      final projectDir = await io.Directory(argResults[argsModuleName])
          .create(recursive: true);

      final isExist = await projectDir.exists();
      if (!isExist) {
        _out('创建${argResults[argsModuleName]}文件目录时出错，请退出重新运行命令');
        return Future.error(ArgError('创建目录出错'));
      }

      // final parentDir = io.Directory.current;
      final parentPath = io.Directory.current.path;
      final currentPath = parentPath + '/${argResults[argsModuleName]}';
      io.Directory.current = currentPath;
      _out('当前路径：$currentPath');

      target ??= _DirectoryGeneratorTarget(logger, io.Directory.current);

      /// 开始生产
      _out('创建 $generatorName 模板 `${argResults[argsModuleName]}`:');

      await generator.generate(argResults[argsModuleName], target).then((_) {
        _out('共生产 ${generator.numFiles()} 文件.');

        var message = generator.getInstallInstructions();
        if (message != null && message.isNotEmpty) {
          message = message.trim();
          message = message.split('\n').map((line) => '--> $line').join('\n');
          _out('\n$message');
        }
      });
      return Future.value();
    }
  }

  ArgParser _createArgParser() => ArgParser()
    ..addFlag(argsHelp, abbr: 'h', negatable: false, help: 'Show help!')
    ..addFlag(argsVersion, abbr: 'v', negatable: false, help: '脚手架当前版本')
    ..addOption(argsModuleName, abbr: 'n', help: '创建的组件名称，不能为空');
  // ..addOption(argsMode,
  //     abbr: 'm',
  //     allowed: [argsModeFunc, argsModeBis],
  //     defaultsTo: argsModeBis,
  //     help: '创建的组件类型 \n$argsModeFunc - 纯功能组件 \n$argsModeBis - 带业务组件');

  void _out(String str) => logger.stdout(str);

  void _usage(ArgParser argParser) {
    _out('$appName 是为SFIBU Flutter工程组件化而生的一个简单易用的脚手架，自动为你生成相应的模板代码');
    _out('');
    _out(
        '使用前请查阅文档 http://confluence.sf-express.com/pages/viewpage.action?pageId=136158925');
    _out('');
    _out('有任何问题和建议，请丰声联系我(chenjian67@sfmail.sf-express.com)');
    _out('');
    _out('$appName usage:');
    _out(argParser.usage);
    _out('');
    _out('当前支持的模板生成器:');
    final len = generators.fold(0, (int length, g) => max(length, g.id.length));
    generators
        .map((g) => '  ${g.id.padRight(len)} - ${g.description}')
        .forEach(logger.stdout);
  }
}

Generator _getGenerator(String id) =>
    generators.firstWhere((g) => g.id == id, orElse: () => null);

class ArgError implements Exception {
  final String message;
  ArgError(this.message);

  @override
  String toString() => message;
}

class _DirectoryGeneratorTarget extends GeneratorTarget {
  final CliLogger logger;
  final io.Directory dir;

  _DirectoryGeneratorTarget(this.logger, this.dir) {
    dir.createSync();
  }

  @override
  Future createFile(String filePath, List<int> contents) {
    final file = io.File(path.join(dir.path, filePath));

    logger.stdout('  ${file.path}');

    return file
        .create(recursive: true)
        .then((_) => file.writeAsBytes(contents));
  }
}
