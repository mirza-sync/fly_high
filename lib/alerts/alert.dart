import 'package:flutter/material.dart';

class Alert {
  String device;
  String event;

  Alert(this.device, this.event);
}

class AlertPage extends StatefulWidget {
  AlertPage() : super();
  @override
  _AlertPageState createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  List<Alert> al = [];

  @override
  void initState() {
    super.initState();
    al.add(Alert("sp-nano-1", "Fall"));
    al.add(Alert("sp-nano-1", "Fall"));
    al.add(Alert("sp-xavier-1", "Idle"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Alerts"),
      ),
      body: _alertList(),
    );
  }

  Widget _alertList() {
    return ListView.separated(
      itemCount: al.length,
      separatorBuilder: (BuildContext context, int index) => Divider(
        thickness: 1.0,
      ),
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, i) {
        return _alertComponent(al[i]);
      },
    );
  }

  Widget _alertComponent(Alert al) {
    return ListTile(
      leading: Icon(
        Icons.people,
        size: 30.0,
        // color: Colors.blue,
      ),
      title: Text(al.device),
      subtitle: Text(al.event),
    );
  }
}
