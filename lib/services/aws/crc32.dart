import 'dart:typed_data';

/// CRC32 (ISO 3309 / ITU-T V.42) used by AWS Event Stream framing.
class Crc32 {
  static final _table = _buildTable();

  static List<int> _buildTable() {
    final t = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var c = i;
      for (var j = 0; j < 8; j++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      }
      t[i] = c;
    }
    return t;
  }

  static int compute(Uint8List data, [int crc = 0]) {
    crc = crc ^ 0xFFFFFFFF;
    for (var i = 0; i < data.length; i++) {
      crc = _table[(crc ^ data[i]) & 0xFF] ^ (crc >>> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
