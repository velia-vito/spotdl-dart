// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

class FrameBuffer {
  final BytesBuilder _buffer = BytesBuilder();

  int get length => _buffer.length;

  List<int> get bytes => _buffer.toBytes();

  FrameBuffer();

  void addIdentifier(String text) {
    _buffer.add(latin1.encode(text));
  }

  /// add the given test as ISO-8859-1 encoded bytes
  void addText(String text) {
    _buffer.add(FrameBufferUtils.toUTF16BE(text));
  }

  void clear() {
    _buffer.clear();
  }

  /// add given bytes to the buffer
  void addBytes(List<int> bytes) {
    _buffer.add(bytes);
  }
}

class FrameBufferUtils {
  /// convert to binary string
  static String toBinary(int number) {
    return number.toRadixString(2);
  }

  /// covert from binary string
  static int fromBinary(String binary) {
    return int.parse(binary, radix: 2);
  }

  /// convert a number into a list of bytes
  ///
  /// ### Note
  /// - Returned bytes are little-endian in order
  static List<int> toByteSet(int value, [int byteCount = 4]) {
    List<int> bytes = [];

    // Extract the individual bytes using bitwise operations and shifts
    //
    // !By adding 7 to value.bitLength before dividing by 8, we ensure that we
    // round up to the nearest whole number of bytes. For example, let's say
    // value.bitLength is 33. If we divide 33 by 8 without adding 7, we would
    // get 4.125. However, we need 5 bytes to represent 33 bits, so we need to
    // round up to the next whole number.
    for (int i = 0; i < ((value.bitLength + 7) / 8).ceil(); i++) {
      int byte = (value >> (i * 8)) & 0xFF;
      bytes.add(byte);
    }

    // Pad the list with null bytes if necessary
    if (bytes.length < byteCount) {
      bytes.addAll(List.filled(byteCount - bytes.length, 0));
    }

    return bytes;
  }

  /// convert a string to UTF-16BE encoded bytes
  static List<int> toUTF16BE(String input) {
    List<int> encoded = [];

    // Add BOM bytes: 0xFE, 0xFF (big-endian BOM)
    encoded.add(0xFE);
    encoded.add(0xFF);

    // Encode each character as UTF-16 (big-endian)
    for (int charCode in input.runes) {
      encoded.add((charCode >> 8) & 0xFF);
      encoded.add(charCode & 0xFF);
    }

    return encoded;
  }

  /// convert to leading zeroed size bytes
  ///
  /// ### Note
  /// - format: `0x00 0x00 0x00 0x00`
  static List<int> getEncodedSize(int size) {
    List<int> bytes = [];

    bytes.add((size >> 21) & 0x7F); //0x7F is 01111111 (zeroing the last bit)
    bytes.add((size >> 14) & 0x7F);
    bytes.add((size >> 7) & 0x7F);
    bytes.add(size & 0x7F);

    return bytes;
  }
}
