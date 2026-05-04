import 'package:flutter/material.dart';

class AssignProgramScreen extends StatelessWidget {
  final String clientUid;
  const AssignProgramScreen({super.key, required this.clientUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Assign Program to $clientUid')));
  }
}
