import 'package:flutter/material.dart';

import 'bluetooth/bluetooth.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Bluetooth());
  }
}
