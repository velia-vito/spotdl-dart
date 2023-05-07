import 'dart:convert';
import 'dart:typed_data';

class FrameBuffer {
  final BytesBuilder _buffer = BytesBuilder();

  int get length => _buffer.length;

  List<int> get bytes => _buffer.toBytes();

  FrameBuffer();

  /// add the given text as ISO-8859-1 encoded bytes
  void addANSIFrameHeader(String text) {
    _buffer.add(latin1.encode(text));
  }

  void clear() {
    _buffer.clear();
  }

  /// add the given text as UTF-16LE encoded bytes
  void addUTF8FrameText(String text) {
    // !dart internally uses UTF-16LE for strings
    _buffer.add(utf8.encode(text));

    // unicode null byte as terminator
    _buffer.add([0x00]);
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
    List<int> bytes = utf8.encode(input); // Encode the input string as UTF-8 bytes

    List<int> encoded = [];
    encoded.addAll([0xFE, 0xFF]); // BOM bytes in big-endian format

    for (int i = 0; i < bytes.length; i += 2) {
      if (i + 1 < bytes.length) {
        encoded.addAll([bytes[i + 1], bytes[i]]); // Swap the byte order (big-endian)
      } else {
        encoded.addAll([0, bytes[i]]); // Pad with zero byte if the length is odd
      }
    }

    return encoded;
  }

  /// convert to leading zeroed size bytes
  ///
  /// ### Note
  /// - format: `0x00 0x00 0x00 0x00`
  static List<int> getEncodedSize(int size) {
    // insert zero after every 7 characters from the right
    var bitStringReversed = FrameBufferUtils.toBinary(size).split('').reversed;
    var bitStringFinal = '';

    for (var bit in bitStringReversed) {
      bitStringFinal += bit;

      if (bitStringFinal.length % 8 == 7) {
        bitStringFinal += '0';
      }
    }

    var encodedSize = FrameBufferUtils.fromBinary(bitStringFinal.split('').reversed.join(''));

    return FrameBufferUtils.toByteSet(encodedSize);
  }
}
