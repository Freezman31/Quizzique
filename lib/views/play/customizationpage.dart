import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/avatars.dart';
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
  int avatarIndex = 0;
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8.0),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final size = MediaQuery.of(context).size;
                      return Dialog(
                        child: Container(
                          width: min(size.width * .8, size.height * .8),
                          height: min(size.height * .8, size.width * .8),
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                            itemCount: Avatar.values.length,
                            itemBuilder: (context, index) {
                              return ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    avatarIndex = index;
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Image(
                                  image: ResizeImage(
                                    AssetImage(
                                      avatarToFile(
                                        avatar: Avatar.values[index],
                                      ),
                                    ),
                                    height:
                                        (min(
                                                  size.width * .8,
                                                  size.height * .8,
                                                ) *
                                                .8 /
                                                3)
                                            .toInt(),
                                    width:
                                        (min(
                                                  size.width * .8,
                                                  size.height * .8,
                                                ) *
                                                .8 /
                                                3)
                                            .toInt(),
                                    policy: ResizeImagePolicy.fit,
                                    allowUpscaling: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Image(
                  image: AssetImage(
                    avatarToFile(avatar: Avatar.values[avatarIndex]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await addPlayer(
                    client: widget.client,
                    gameCode: code,
                    username: _username,
                    avatar: Avatar.values[avatarIndex],
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
