import 'dart:io';

import 'package:spotify_dart/id3/frame.dart';
import 'package:spotify_dart/id3/tag.dart';

void main(List<String> args) async {
  var tag = Tag();
  tag.frames.add(Frame.textFrame('TIT2', 'TestTitle'));

  await prependBytesToFile('./Hiroyuki Sawano - Blumenkranz.mp3', tag.bytes);
  print(tag.bytes);
}

Future<void> prependBytesToFile(String filePath, List<int> bytes) async {
  // Read the existing contents of the file
  File file = File(filePath);
  List<int> existingBytes = await file.readAsBytes();

  // Create a new list with the bytes to prepend followed by the existing bytes
  List<int> newBytes = []
    ..addAll(bytes)
    ..addAll(existingBytes);

  // Write the new bytes back to the file
  await file.writeAsBytes(newBytes);
}
