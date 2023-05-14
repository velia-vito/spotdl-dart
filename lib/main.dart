// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:spotify_dart/ui/simple.dart';

void main(List<String> args) {
  runApp(
    MaterialApp(
      home: Simple(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromRGBO(115, 171, 132, 1),
      ),
    ),
  );
}
