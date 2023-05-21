// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:spotify_dart/ui/ui.dart';

void main(List<String> args) {
  runApp(
    MaterialApp(
      home: const UI(),
      theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color.fromRGBO(115, 171, 132, 1)),
    ),
  );
}
