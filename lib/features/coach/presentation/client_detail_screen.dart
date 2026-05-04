import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientUid;
  const ClientDetailScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Client Detail: $clientUid')));
  }
}
