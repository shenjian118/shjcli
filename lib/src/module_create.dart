import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:rename/file_repository.dart';
import 'package:shjcli/shjcli.dart';
import 'file_repository_extension.dart';

enum Platform {
  android,
  ios,
  macOS,
}

class ModuleCreate {
  bool get isAwesome => true;
  FileRepository fileRepository = FileRepository();

  Future create({String appName, String mode}) async {
    var args = <String>[];
    args.add('clone');
    if (mode == 'func') {
      args.add(funcGit);
    } else {
      args.add(modeGit);
    }
    args.add(appName);
    stdout.write(p.current);
    await Process.run('git', args,
            workingDirectory: p.current, runInShell: true)
        .then((result) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    });
    await changeAppName(
        appName: appName, platforms: [Platform.android, Platform.ios]);
  }

  void changeFilesImports(String appName, String oldAppName) {
    var dir = Directory(appName);
    // List directory contents, recursing into sub-directories,
    // but not following symbolic links.
    dir
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
      if (entity.path.endsWith('dart') || entity.path.endsWith('.yaml')) {
        fileRepository.changeImportName(appName, entity.path, oldAppName);
      }
    });
  }

  Future<String> getPubSpecName(String path) async {
    return fileRepository.getCurrentPubSpecName(path);
  }

  // change rename.changeAppName
  Future changeAppName({String appName, Iterable<Platform> platforms}) async {
    var oldName = await fileRepository.getCurrentPubSpecName(appName);
    if (platforms.isEmpty || platforms.contains(Platform.ios)) {
      await fileRepository.myChangeIosAppName(appName);
    }
    if (platforms.isEmpty || platforms.contains(Platform.macOS)) {
      await fileRepository.myChangeMacOsAppName(appName);
    }
    if (platforms.isEmpty || platforms.contains(Platform.android)) {
      await fileRepository.myChangeAndroidAppName(appName);
    }
    changeFilesImports(appName, oldName);
  }
}
