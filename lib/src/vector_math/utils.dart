import 'dart:typed_data';

class Utils {
  Utils();
  // FNV-1a (64-bit) non-cryptographic hash function.
  // Adapted from: http://github.com/jakedouglas/fnv-java
  //https://github.com/pawandubey/fnv-hash/blob/master/lib/fnv.rb
  static int computeHash(List<int> bytes, [hash = 0xcbf29ce484222325]) {
    const int fnv64Prime = 1099511628211;
    for (var i = 0; i < bytes.length; i++) {
      hash = hash ^ bytes[i];
      hash *= fnv64Prime;
    }
    return hash;
  }

  //FNVHash
  //https://github.com/adam-singer/dart-hash-server/blob/master/src/HashLib/fnvhash.dart
  static int computeHash2(String str) {
    int fnv_prime = 0x811C9DC5;
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash *= fnv_prime;
      hash ^= str.codeUnitAt(i); //charCodeAt
    }
    return hash;
  }

  static int getLongHashCodeFrom(double data, [hash = 0xcbf29ce484222325]) {
    var byteData = ByteData(8);
    byteData.setFloat64(0, data);
    var bytes = byteData.buffer.asUint8List();
    return Utils.computeHash(bytes, hash);
  }
}
