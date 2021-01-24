import 'dart:io' as io;
import 'package:shjcli/shjcli.dart';

void main(List<String> arguments) {
  final app = CliApp(CliLogger());
  try {
    app.process(arguments).catchError((Object e, StackTrace st) {
      if (e is ArgError) {
        io.exit(1);
      } else {
        print('未知异常 error: $e \n $st');
        io.exit(1);
      }
    }).whenComplete(() {
      io.exit(0);
    });
  } catch (e, st) {
    print('未知异常 error: $e \n $st');
    io.exit(1);
  }
}
