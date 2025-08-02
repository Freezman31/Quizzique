import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/views/play/playpage.dart';

class CustomizationPage extends StatefulWidget {
  static const String route = '/play/customization';
  final Client client;
  const CustomizationPage({super.key, required this.client});

  @override
  State<CustomizationPage> createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  String _username = '';
  late final TextEditingController _usernameController;
  int code = -1;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (code == -1) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('code')) {
        code = args['code'];
      } else if (Uri.base.queryParameters['code'] != null) {
        code = int.tryParse(Uri.base.queryParameters['code'] ?? '') ?? -1;
      }
    }
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Customization Page')),
      body: Center(
        child: SizedBox(
          width: min(mq.size.width * .8, 600),
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Enter your username',
                  border: OutlineInputBorder(),
                  hintText: 'Username',
                ),
                maxLength: 100,
                controller: _usernameController,
                onChanged: (value) {
                  setState(() {
                    _username = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  addPlayer(
                    client: widget.client,
                    gameCode: code,
                    username: _username,
                  );
                  Navigator.of(context).pushNamed(
                    PlayPage.route,
                    arguments: {'username': _username, 'code': code},
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
