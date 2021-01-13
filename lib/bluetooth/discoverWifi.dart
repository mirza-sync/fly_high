import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';

import 'configureWifi.dart';

class WiFiData {
  String ssid;
  int channel;
  double quality;
  String frequency;
  String encryption;

  WiFiData(
      this.ssid, this.channel, this.quality, this.frequency, this.encryption);

  factory WiFiData.fromJson(dynamic json) {
    return WiFiData(
        json['ssid'] as String,
        json['channel'] as int,
        json['quality'] as double,
        json['frequency'] as String,
        json['encryption'] as String);
  }
}

class DiscoverWifi extends StatefulWidget {
  final BluetoothDevice device;
  const DiscoverWifi({this.device});

  @override
  _DiscoverWifiState createState() => _DiscoverWifiState();
}

class _DiscoverWifiState extends State<DiscoverWifi> {
  List<WiFiData> wifiList = [];
  BluetoothConnection connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnecting = false;
  BluetoothDevice pairedDevice;
  bool isDiscovering;
  bool waitDisconnect = false;

  void initState() {
    super.initState();

    setState(() {
      isDiscovering = true;
    });

    if (!isConnected) {
      try {
        BluetoothConnection.toAddress(widget.device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            isConnecting = false;
            isDisconnecting = false;
          });

          requestAvailableWifi();
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
      } on PlatformException catch (err) {
        print("Cannot connet to device, $err");
      } catch (error) {
        print("Cannot connet to device, $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isDiscovering
            ? Text('Discovering WiFi')
            : Text('Configure ${widget.device.name}'),
        actions: <Widget>[
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: new EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "Select WiFi to connect",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8.0),
                itemCount: wifiList.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildRow(wifiList, index);
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<WiFiData> wifiList, int i) {
    return ListTile(
      leading: waitDisconnect
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54))
          : Icon(Icons.wifi),
      title: Text(
        wifiList[i].ssid,
      ),
      onTap: () async {
        setState(() => waitDisconnect = true);
        pairedDevice = widget.device;
        var ssid = wifiList[i].ssid;
        await connection.finish();
        // dispose();

        await Future.delayed(const Duration(seconds: 2),
            () => print("Waiting connection properly closed DONE"));
        setState(() => waitDisconnect = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              print("Forward to Wifi Form");
              return ConfigureWifi(btDevice: pairedDevice, wifiName: ssid);
            },
          ),
        );
      },
    );
  }

  void requestAvailableWifi() {
    try {
      connection.output.add(utf8.encode("{\"command\": \"wifi_scan\"}"));
    } catch (e) {
      setState(() {});
    }
  }

  void onWifiReceived(response) {
    try {
      var res = ascii.decode(response);
      print('Data incoming: ' + res);
      var jsonData = json.decode(res)['data'] as List;

      List<WiFiData> incomingWifi = jsonData
          .map((incomingWifi) => WiFiData.fromJson(incomingWifi))
          .toSet()
          .toList();

      // Remove duplicated WiFi
      for (int i = 0; i < incomingWifi.length; i++) {
        for (int j = i + 1; j < incomingWifi.length; j++) {
          if (incomingWifi[i].ssid == incomingWifi[j].ssid) {
            incomingWifi.remove(incomingWifi[j]);
            j--;
          }
        }
      }

      setState(() {
        wifiList.addAll(incomingWifi);
        isDiscovering = false;
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
