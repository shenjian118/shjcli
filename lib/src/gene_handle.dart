import 'dart:async';
import 'dart:convert';
import 'common.dart';
import 'generators/sfmodule_bis.dart';

final List<Generator> generators = [
  SfModuleGenerator(),
]..sort();

Generator getGenerator(String id) =>
    generators.firstWhere((g) => g.id == id, orElse: () => null);

/// An abstract class which both defines a template generator and can generate a
/// user project based on this template.
abstract class Generator implements Comparable<Generator> {
  final String id;
  final String label;
  final String description;
  final List<String> categories;

  final List<TemplateFile> files = [];
  TemplateFile _entrypoint;

  Generator(this.id, this.label, this.description,
      {this.categories = const []});

  /// The entrypoint of the application; the main file for the project, which an
  /// IDE might open after creating the project.
  TemplateFile get entrypoint => _entrypoint;

  /// Add a new template file.
  TemplateFile addTemplateFile(TemplateFile file) {
    files.add(file);
    return file;
  }

  /// Return the template file wih the given [path].
  TemplateFile getFile(String path) =>
      files.firstWhere((file) => file.path == path, orElse: () => null);

  /// Set the main entrypoint of this template. This is the 'most important'
  /// file of this template. An IDE might use this information to open this file
  /// after the user's project is generated.
  void setEntrypoint(TemplateFile entrypoint) {
    if (_entrypoint != null) throw StateError('entrypoint already set');
    if (entrypoint == null) throw StateError('entrypoint is null');
    _entrypoint = entrypoint;
  }

  Future generate(
    String projectName,
    GeneratorTarget target, {
    Map<String, String> additionalVars,
  }) {
    final vars = {
      'projectName': projectName,
      'description': description,
      'year': DateTime.now().year.toString(),
      'author': '<your name>',
      if (additionalVars != null) ...additionalVars,
    };

    return Future.forEach(files, (TemplateFile file) {
      final resultFile = file.runSubstitution(vars);
      final filePath = resultFile.path;
      return target.createFile(filePath, resultFile.content);
    });
  }

  int numFiles() => files.length;

  @override
  int compareTo(Generator other) =>
      id.toLowerCase().compareTo(other.id.toLowerCase());

  /// Return some user facing instructions about how to finish installation of
  /// the template.
  String getInstallInstructions() => '';

  @override
  String toString() => '[$id: $description]';
}

/// A target for a [Generator]. This class knows how to create files given a
/// path for the file (relative to the particular [GeneratorTarget] instance),
/// and the binary content for the file.
abstract class GeneratorTarget {
  /// Create a file at the given path with the given contents.
  Future createFile(String path, List<int> contents);
}

/// This class represents a file in a generator template. The contents could
/// either be binary or text. If text, the contents may contain mustache
/// variables that can be substituted (`__myVar__`).
class TemplateFile {
  final String path;
  final String content;

  List<int> _binaryData;

  TemplateFile(this.path, this.content);

  TemplateFile.fromBinary(this.path, this._binaryData) : content = null;

  FileContents runSubstitution(Map<String, String> parameters) {
    if (path == 'pubspec.yaml' && parameters['author'] == '<your name>') {
      parameters = Map.from(parameters);
      parameters['author'] = 'Your Name';
    }

    final newPath = substituteVars(path, parameters);
    final newContents = _createContent(parameters);

    return FileContents(newPath, newContents);
  }

  bool get isBinary => _binaryData != null;

  List<int> _createContent(Map<String, String> vars) {
    if (isBinary) {
      return _binaryData;
    } else {
      return utf8.encode(substituteVars(content, vars));
    }
  }
}

class FileContents {
  final String path;
  final List<int> content;

  FileContents(this.path, this.content);
}
