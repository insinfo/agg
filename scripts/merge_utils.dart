import 'dart:convert';
import 'dart:io';

void main() {
 
  final libDir = Directory(r'C:\MyDartProjects\agg\agg-sharp\agg');
  //final libDir = Directory(r'C:\MyDartProjects\agg\agg-sharp\Typography');
  
  
  final outputFile = File(r'C:\MyDartProjects\agg\scripts\agg_mesclado.cs.txt');

  if (outputFile.existsSync()) {
    outputFile.deleteSync();
  }

  final outputSink = outputFile.openWrite(mode: FileMode.append);

  final files = libDir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.cs')) {
      final content = file.readAsStringSync(encoding: Utf8Codec(allowMalformed: true));
      outputSink.write('// Merged from ${file.path}\n');
      outputSink.write(content);
      outputSink.write('\n\n');
    }
  }

  outputSink.close();
  print('Merged all .dart files from lib/ to $outputFile');
}
