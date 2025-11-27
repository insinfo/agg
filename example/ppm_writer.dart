import 'dart:io';
import 'package:agg/src/agg/image/image_buffer.dart';

void savePpm(ImageBuffer image, String filename) {
  final file = File(filename);
  final buffer = StringBuffer();
  
  buffer.writeln('P3');
  buffer.writeln('${image.width} ${image.height}');
  buffer.writeln('255');
  
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final color = image.getPixel(x, y);
      buffer.write('${color.red} ${color.green} ${color.blue} ');
    }
    buffer.writeln();
  }
  
  file.writeAsStringSync(buffer.toString());
  print('Saved $filename');
}
