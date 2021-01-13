import 'package:graphql_flutter/graphql_flutter.dart';

final String getAlertsQuery = """
    query (\$id: String!) {
      alert(id: \$id) {
        id
        event
        timestamp
      }
    }
""";

final String alertListQuery = """
    query (\$token: String!) {
      alerts(token: \$token) {
        id
        event
        timestamp
        userDevices {
          name
        }
      }
    }
""";
