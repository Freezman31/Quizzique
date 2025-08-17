import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/utils.dart';
import 'package:quizzique/views/create/listpage.dart';

class LoginPage extends StatefulWidget {
  static const String route = '/login';
  final Client client;
  const LoginPage({super.key, required this.client});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool signingIn = true;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Spacer(),
          Expanded(
            flex: signingIn ? 4 : 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.topLeft,
              child: Text(
                signingIn ? 'Welcome back!' : 'Create your account!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!signingIn)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  autocorrect: false,
                  keyboardType: TextInputType.name,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.newUsername,
                  ],
                  inputFormatters: [],
                  maxLength: 32,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.words,
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                inputFormatters: [],
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                controller: emailController,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                autocorrect: false,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                controller: passwordController,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ),
          if (!signingIn)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  autocorrect: false,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  controller: confirmPasswordController,
                ),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: mq.size.height * 0.1,
              width: mq.size.width * 0.26,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () async {
                  if (passwordController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      (signingIn ? false : usernameController.text.isEmpty) ||
                      (signingIn
                          ? false
                          : confirmPasswordController.text.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  if (passwordController.text.length < 8 ||
                      passwordController.text.length > 256) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password length must be between 8 and 256 characters',
                        ),
                      ),
                    );
                    return;
                  }
                  if (!isEmailValid(emailController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid email address')),
                    );
                    return;
                  }
                  if (signingIn) {
                    try {
                      await login(
                        email: emailController.text,
                        password: passwordController.text,
                        client: widget.client,
                      );
                      Navigator.of(context).pushNamed(ListPage.route);
                    } on Exception catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  } else {
                    if (passwordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }
                    try {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Creating account...'),
                            content: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.2,
                              height: MediaQuery.of(context).size.height * 0.1,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: const CircularProgressIndicator(),
                              ),
                            ),
                          );
                        },
                      );
                      await createAccount(
                        username: usernameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                        client: widget.client,
                        context: context,
                      );
                      Navigator.of(context).pop();
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Account created'),
                          content: const Text(
                            'Your account has been created successfully. You can now log in.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      setState(() {
                        signingIn = true;
                        usernameController.clear();
                        emailController.clear();
                        passwordController.clear();
                        confirmPasswordController.clear();
                      });
                    } on Exception catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Submit!'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  signingIn = !signingIn;
                });
              },
              child: Text(
                signingIn
                    ? 'Don\'t have an account? Sign up now!'
                    : 'Already have an account? Log in now!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
