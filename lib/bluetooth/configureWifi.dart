import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConfigureWifi extends StatefulWidget {
  final BluetoothDevice btDevice;
  final String wifiName;
  const ConfigureWifi({this.btDevice, this.wifiName});

  @override
  _ConfigureWifiState createState() => _ConfigureWifiState();
}

class WiFiInfo {
  String name;
  String uuid;
  String connType;
  String device;
  String gateway;
  String ipAddress1;
  String ipDns1;

  WiFiInfo(this.name, this.uuid, this.connType, this.device, this.gateway,
      this.ipAddress1, this.ipDns1);

  factory WiFiInfo.fromJson(dynamic json) {
    return WiFiInfo(
        json['name'] as String,
        json['uuid'] as String,
        json['conn_type'] as String,
        json['device'] as String,
        json['ipv4.gateway'] as String,
        json['ipv4.address.1'] as String,
        json['ipv4.dns.1'] as String);
  }
}

class _ConfigureWifiState extends State<ConfigureWifi> {
  WiFiInfo wifiInfo;
  BluetoothConnection connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnecting = false;
  bool getCurrentWifi = true;
  bool wifiConnecting = false;
  StreamSubscription<Uint8List> x;

  final _formKey = GlobalKey<FormState>();
  final myController = TextEditingController();

  void initState() {
    super.initState();

    // Get current bluetooth connection
    if (!isConnected) {
      try {
        BluetoothConnection.toAddress(widget.btDevice.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;

          setState(() {
            isConnecting = false;
            isDisconnecting = false;
          });

          connection.input.listen(_onDataReceived).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });

          // Get currently connected WiFi
          getConnectedWifi();
        });
      } catch (error) {
        print(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configure ${widget.btDevice.name}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        "Connect to ${widget.wifiName}",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: wifiConnecting
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black87),
                            )
                          : Icon(Icons.wifi),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextFormField(
                        controller: myController,
                        decoration: InputDecoration(labelText: 'Password'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: RaisedButton(
                        child: Text("Save"),
                        onPressed: () async {
                          // if (_formKey.currentState.validate()) {
                          //   _formKey.currentState.save();
                          // }
                          var ssid = widget.wifiName;
                          var password = myController.text;
                          connectToWifi(ssid, password);
                        },
                      ),
                    ),
                    ListTile(
                      title: getCurrentWifi
                          ? Text("Currently  connected to : Please wait...",
                              style: TextStyle(
                                fontSize: 16.0,
                              ))
                          : wifiInfo.uuid != null
                              ? Text(
                                  "Currently  connected to : ${wifiInfo.name}",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ))
                              : Text("Currently not connected to any WiFi",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  )),
                      trailing: Icon(Icons.info_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List response) {
    // Decode response to string
    var res = ascii.decode(response);
    // Check the string
    // Do different processing based on the response
    if (res.contains("updated")) {
      print('WiFi updated to : ' + res);
      setState(() {
        wifiConnecting = false;
      });
      // Forward back to homepage
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      print('Currently connected to WiFi: ' + res);
      // Process only the ['data'] part of the json
      WiFiInfo connectedWifi = WiFiInfo.fromJson(json.decode(res)['data']);
      setState(() {
        getCurrentWifi = false;
        wifiInfo = connectedWifi;
      });
      print("wifiInfo : ${wifiInfo.name}");
    }
  }

  void getConnectedWifi() {
    try {
      connection.output.add(utf8.encode("{\"command\": \"wifi_info\"}"));
    } catch (e) {
      print("Failed to send wifi_info command. Error: $e");
      // I don't know why need to do empty set state, I just follow the example
      // // Ignore error, but notify state
      setState(() {});
    }
  }

  void connectToWifi(String ssid, String password) async {
    var creds =
        "{\"command\": \"wifi_update\", \"ssid\": \"$ssid\", \"password\": \"$password\"}";
    try {
      connection.output.add(utf8.encode(creds));
      setState(() {
        wifiConnecting = true;
      });
    } catch (e) {
      print("Failed to send wifi_update command. Error: $e");
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    myController.dispose();
    super.dispose();
  }
}
