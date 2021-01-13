import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';

class ConnWifi extends StatefulWidget {
  final BluetoothDevice server;
  final Map<String, dynamic> wifiCredentials;
  const ConnWifi({this.server, this.wifiCredentials});

  @override
  _ConnWifiState createState() => _ConnWifiState();
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

class _ConnWifiState extends State<ConnWifi> {
  WiFiInfo wifiInfo;
  BluetoothConnection connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnecting = false;

  void initState() {
    super.initState();
    print(widget.wifiCredentials);

    // Get current bluetooth connection
    if (!isConnected) {
      try {
        BluetoothConnection.toAddress(widget.server.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            isConnecting = false;
            isDisconnecting = false;
          });

          getConnectedWifi();
          connection.input.listen(onWifiReceived).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
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
        title: Text('Discover WiFi'),
      ),
      body: Center(
        child: Column(
          children: [
            wifiInfo == null
            ? Text("Retrieving wifi info...")
            : Text('Connected to: ${wifiInfo.name}'),
          ],
        ),
      ),
    );
  }

  void getConnectedWifi() {
    try {
      connection.output.add(utf8.encode("{\"command\": \"wifi_info\"}"));
    } catch (e) {
      // Ignore error, but notify state
      setState(() {});
    }
  }

  void onWifiReceived(response) {
    try {
      var res = ascii.decode(response);
      print('Connected to WiFi: ' + res);
      WiFiInfo connectedWifi = WiFiInfo.fromJson(json.decode(res)['data']);
      setState(() {
        wifiInfo = connectedWifi;
      });
    } catch (e) {
      // Ignore error, but notify state
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
    super.dispose();
  }
}
