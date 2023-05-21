// Project imports:
import 'package:spotify_dart/id3/frame.dart';
import 'package:spotify_dart/id3/frame_buffer.dart';

class Tag {
  final _buffer = FrameBuffer();

  // TODO: boilerplate and make this hidden
  var frames = <Frame>[];

  /// get tag bytes
  List<int> get bytes {
    _buffer.clear();

    // generate header
    generateHeader();

    // generate frames
    for (var frame in frames) {
      _buffer.addBytes(frame.bytes);
    }

    return _buffer.bytes;
  }

  /// generate ID3 header
  void generateHeader() {
    // 1. ID3v2/file identifier
    //    "ID3"
    _buffer.addText('ID3');

    // 2. ID3v2 version
    //    $03 00           (version 3.2)
    _buffer.addBytes([0x03, 0x02]);

    // 3. ID3v2 flags
    //    %abc00000       (we set abc to 000 to keep it simple)
    _buffer.addBytes([0x00]);

    // 4. ID3v2 size
    //    %0xxxxxxx       (4 bytes, leading bit is zero inserted)
    var length = 0;

    print(frames.length);

    for (var frame in frames) {
      length += frame.length;
    }

    _buffer.addBytes(FrameBufferUtils.getEncodedSize(length));
  }
}
