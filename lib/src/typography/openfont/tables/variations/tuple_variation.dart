// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../utils.dart';

class TupleVariationHeader {
  int variationDataSize = 0;
  int tupleIndex = 0;
  TupleRecord? peakTuple;
  TupleRecord? intermediateStartTuple;
  TupleRecord? intermediateEndTuple;

  void readContent(ByteOrderSwappingBinaryReader reader, int axisCount) {
    variationDataSize = reader.readUInt16();
    tupleIndex = reader.readUInt16();

    int format = tupleIndex; // The high 4 bits are flags
    // int indexToSharedTuple = tupleIndex & 0x0FFF;

    if ((format & TupleIndexFormat.EMBEDDED_PEAK_TUPLE) != 0) {
      peakTuple = TupleRecord(axisCount);
      peakTuple!.readContent(reader);
    }

    if ((format & TupleIndexFormat.INTERMEDIATE_REGION) != 0) {
      intermediateStartTuple = TupleRecord(axisCount);
      intermediateStartTuple!.readContent(reader);
      intermediateEndTuple = TupleRecord(axisCount);
      intermediateEndTuple!.readContent(reader);
    }
  }
}

class TupleIndexFormat {
  static const int EMBEDDED_PEAK_TUPLE = 0x8000;
  static const int INTERMEDIATE_REGION = 0x4000;
  static const int PRIVATE_POINT_NUMBERS = 0x2000;
  static const int Reserved = 0x1000;
  static const int TUPLE_INDEX_MASK = 0x0FFF;
}

class TupleRecord {
  final int axisCount;
  late List<double> coords;

  TupleRecord(this.axisCount) {
    coords = List<double>.filled(axisCount, 0.0);
  }

  void readContent(ByteOrderSwappingBinaryReader reader) {
    for (int i = 0; i < axisCount; i++) {
      coords[i] = Utils.readF2Dot14(reader);
    }
  }
}

class PackedPointNumbers {
  static List<int>? readPointNumbers(ByteOrderSwappingBinaryReader reader) {
    int b0 = reader.readByte();
    int count = 0;

    if (b0 == 0) {
      // All points
      return null;
    } else if ((b0 & 0x80) == 0) {
      count = b0;
    } else {
      int b1 = reader.readByte();
      count = ((b0 & 0x7F) << 8) | b1;
    }

    List<int> points = [];
    int lastPoint = 0;
    int pointsRead = 0;

    while (pointsRead < count) {
      int control = reader.readByte();
      int runCount = (control & 0x7F) + 1;
      bool is16Bit = (control & 0x80) != 0;

      for (int i = 0; i < runCount; i++) {
        int val = 0;
        if (is16Bit) {
          val = reader.readUInt16();
        } else {
          val = reader.readByte();
        }
        lastPoint += val;
        points.add(lastPoint);
      }
      pointsRead += runCount;
    }

    return points;
  }
}

class PackedDeltas {
  static List<int> readDeltas(ByteOrderSwappingBinaryReader reader, int count) {
    List<int> deltas = [];
    int deltasRead = 0;

    while (deltasRead < count) {
      int control = reader.readByte();
      int runCount = (control & 0x3F) + 1;
      
      // 0x80: DELTAS_ARE_ZERO
      if ((control & 0x80) != 0) {
        for (int i = 0; i < runCount; i++) {
          deltas.add(0);
        }
      } else {
        // 0x40: DELTAS_ARE_WORDS (16-bit)
        bool is16Bit = (control & 0x40) != 0;
        for (int i = 0; i < runCount; i++) {
          if (is16Bit) {
            deltas.add(reader.readInt16());
          } else {
            deltas.add(reader.readSByte());
          }
        }
      }
      deltasRead += runCount;
    }
    return deltas;
  }
}
