import 'dart:io';
import 'dart:typed_data';
import 'package:agg/src/agg/image/image_buffer.dart';

/// A simple PNG encoder.
class PngEncoder {
  /// Encodes an ImageBuffer to a PNG file.
  static void saveImage(ImageBuffer image, String filename) {
    final file = File(filename);
    final bytes = encode(image);
    file.writeAsBytesSync(bytes);
    print('Saved $filename');
  }

  /// Encodes an ImageBuffer to PNG bytes.
  static Uint8List encode(ImageBuffer image) {
    final width = image.width;
    final height = image.height;
    final buffer = BytesBuilder();

    // 1. Signature
    buffer.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    // 2. IHDR Chunk
    final ihdrData = BytesBuilder();
    ihdrData.add(_int32ToBytes(width));
    ihdrData.add(_int32ToBytes(height));
    ihdrData.addByte(8); // Bit depth: 8
    ihdrData.addByte(6); // Color type: 6 (Truecolor with alpha)
    ihdrData.addByte(0); // Compression method: 0 (deflate)
    ihdrData.addByte(0); // Filter method: 0 (adaptive filtering with 5 basic filter types)
    ihdrData.addByte(0); // Interlace method: 0 (no interlace)
    _writeChunk(buffer, 'IHDR', ihdrData.toBytes());

    // 3. IDAT Chunk (Image Data)
    // We use filter type 0 (None) for simplicity for now.
    // Each scanline is preceded by a filter type byte (0).
    final rawData = BytesBuilder();
    for (var y = 0; y < height; y++) {
      rawData.addByte(0); // Filter type 0 (None)
      for (var x = 0; x < width; x++) {
        final color = image.getPixel(x, y);
        rawData.addByte(color.red);
        rawData.addByte(color.green);
        rawData.addByte(color.blue);
        rawData.addByte(color.alpha);
      }
    }
    
    final compressedData = zlib.encode(rawData.toBytes());
    _writeChunk(buffer, 'IDAT', Uint8List.fromList(compressedData));

    // 4. IEND Chunk
    _writeChunk(buffer, 'IEND', Uint8List(0));

    return buffer.toBytes();
  }

  static void _writeChunk(BytesBuilder buffer, String type, Uint8List data) {
    buffer.add(_int32ToBytes(data.length));
    
    final typeBytes = type.codeUnits;
    buffer.add(typeBytes);
    buffer.add(data);
    
    final crc = _crc32(typeBytes, data);
    buffer.add(_int32ToBytes(crc));
  }

  static Uint8List _int32ToBytes(int value) {
    final bytes = Uint8List(4);
    final data = ByteData.view(bytes.buffer);
    data.setUint32(0, value, Endian.big);
    return bytes;
  }

  static final List<int> _crcTable = _makeCrcTable();

  static List<int> _makeCrcTable() {
    final table = List<int>.filled(256, 0);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xedb88320 ^ (c >> 1);
        } else {
          c = c >> 1;
        }
      }
      table[n] = c;
    }
    return table;
  }

  static int _crc32(List<int> type, Uint8List data) {
    var crc = 0xffffffff;
    for (var b in type) {
      crc = _crcTable[(crc ^ b) & 0xff] ^ (crc >> 8);
    }
    for (var b in data) {
      crc = _crcTable[(crc ^ b) & 0xff] ^ (crc >> 8);
    }
    return crc ^ 0xffffffff;
  }
}
