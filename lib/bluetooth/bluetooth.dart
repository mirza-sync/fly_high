import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'discoverDevices.dart';
import 'SelectBondedDevicePage.dart';
import 'discoverWifi.dart';
import 'connectedWifi.dart';
import '../alerts/alert.dart';

class Bluetooth extends StatefulWidget {
  @override
  _Bluetooth createState() => new _Bluetooth();
}

class _Bluetooth extends State<Bluetooth> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  // String _address = "...";
  // String _name = "...";

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // // Update the address field
      // FlutterBluetoothSerial.instance.address.then((address) {
      //   setState(() {
      //     _address = address;
      //   });
      // });
    });

    // FlutterBluetoothSerial.instance.name.then((name) {
    //   setState(() {
    //     _name = name;
    //   });
    // });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kohler Mobile App'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            // ListTile(title: const Text('General')),
            // SwitchListTile(
            //   title: const Text('Enable Bluetooth'),
            //   value: _bluetoothState.isEnabled,
            //   onChanged: (bool value) {
            //     // Do the request and update with the true value then
            //     future() async {
            //       // async lambda seems to not working
            //       if (value)
            //         await FlutterBluetoothSerial.instance.requestEnable();
            //       else
            //         await FlutterBluetoothSerial.instance.requestDisable();
            //     }

            //     future().then((_) {
            //       setState(() {});
            //     });
            //   },
            // ),
            // ListTile(
            //   title: const Text('Bluetooth status'),
            //   subtitle: Text(_bluetoothState.toString()),
            //   trailing: RaisedButton(
            //     child: const Text('Settings'),
            //     onPressed: () {
            //       FlutterBluetoothSerial.instance.openSettings();
            //     },
            //   ),
            // ),
            // ListTile(
            //   title: const Text('Local adapter address'),
            //   subtitle: Text(_address),
            // ),
            // ListTile(
            //   title: const Text('Local adapter name'),
            //   subtitle: Text(_name),
            //   onLongPress: null,
            // ),
            ListTile(
              title: RaisedButton(
                  child: const Text('Configure devices'),
                  onPressed: () async {
                    final BluetoothDevice selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DiscoverDevices();
                        },
                      ),
                    );

                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address);
                      _discoverWifi(context, selectedDevice);
                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
            ),
            Divider(),
            ListTile(
              title: RaisedButton(
                child: const Text('Check Bluetooth device\'s WiFi'),
                onPressed: () async {
                  final BluetoothDevice selectedDevice =
                      await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    // _discoverWifi(context, selectedDevice);
                    _connectWifi(context, selectedDevice, {'data': 'item'});
                  } else {
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),
            Divider(),
            ListTile(
              title: RaisedButton(
                child: const Text('View Alert'),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AlertPage()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _discoverWifi(
      BuildContext context, BluetoothDevice device) async {
    var data = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return DiscoverWifi(device: device);
        },
      ),
    );
    print("The map2 : " + data.toString());
    return data;
  }

  void _connectWifi(BuildContext context, BluetoothDevice server,
      Map<String, dynamic> wifiCreds) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: CircularProgressIndicator(),
        );
      },
    );
    // Future.delayed(const Duration(seconds: 3), () => _connectWifi(context, server, wifiCreds));
    new Future.delayed(new Duration(seconds: 1), () {
      Navigator.pop(context); //pop dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return ConnWifi(server: server, wifiCredentials: wifiCreds);
          },
        ),
      );
    });
  }
}
