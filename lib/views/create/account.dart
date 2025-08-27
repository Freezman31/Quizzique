import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/utils.dart';

class AccountPage extends StatefulWidget {
  static const String route = '/account';

  final Client client;
  const AccountPage({super.key, required this.client});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  TextEditingController? _emailController;
  TextEditingController? _usernameController;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _newPasswordConfirmationController =
      TextEditingController();
  final TextEditingController _dialogPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController?.dispose();
    _usernameController?.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmationController.dispose();
    _dialogPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: FutureBuilder(
        future: Account(widget.client).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final User user = snapshot.data!;
            _emailController ??= TextEditingController(text: user.email);
            _usernameController ??= TextEditingController(text: user.name);
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.name,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 18.0),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    controller: _emailController,
                  ),
                  const SizedBox(height: 18.0),
                  ElevatedButton(
                    onPressed: () async {
                      if (!isEmailValid(_emailController!.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid email address.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_emailController!.text != user.email) {
                        final bool sure = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: Column(
                                children: [
                                  Text(
                                    'Your password is required to change your email address',
                                  ),
                                  const SizedBox(height: 16.0),
                                  TextField(
                                    keyboardType: TextInputType.visiblePassword,
                                    autocorrect: false,
                                    obscureText: true,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                    ),
                                    controller: _dialogPasswordController,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ],
                            );
                          },
                        );
                        if (!sure) return;
                        try {
                          await updateEmail(
                            client: widget.client,
                            email: _emailController!.text,
                            password: _dialogPasswordController.text,
                          );
                          _dialogPasswordController.clear();
                        } catch (e) {
                          if (e.toString() == 'Exception: Wrong password') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Wrong password. Please try again.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (e.toString() ==
                              'Exception: Email already in use') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Email already in use. Please try again.',
                                ),
                              ),
                            );
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                      try {
                        await updateUsername(
                          client: widget.client,
                          username: _usernameController!.text,
                        );
                      } catch (e) {
                        if (e.toString() ==
                            'Exception: Username already in use') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Username already in use. Please try again.',
                              ),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account updated successfully.'),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 27.0),
                  Flexible(
                    child: Text(
                      'Change your password',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 9.0),
                  TextField(
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    controller: _oldPasswordController,
                  ),
                  const SizedBox(height: 18.0),
                  TextField(
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    controller: _newPasswordController,
                  ),
                  const SizedBox(height: 18.0),
                  TextField(
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    controller: _newPasswordConfirmationController,
                  ),
                  const SizedBox(height: 18.0),
                  ElevatedButton(
                    onPressed: () async {
                      if (_oldPasswordController.text.length < 8 ||
                          _oldPasswordController.text.length > 256) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please check your old password.'),
                          ),
                        );
                        return;
                      }
                      if (_newPasswordController.text.length < 8 ||
                          _newPasswordController.text.length > 256) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The new password must be between 8 and 256 characters.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_newPasswordController.text ==
                          _oldPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'New password must be different from old password.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_newPasswordController.text !=
                          _newPasswordConfirmationController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New passwords do not match.'),
                          ),
                        );
                        return;
                      }
                      try {
                        await changePassword(
                          client: widget.client,
                          oldPassword: _oldPasswordController.text,
                          newPassword: _newPasswordController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully.'),
                          ),
                        );
                      } catch (e) {
                        if (e.toString() ==
                            'Exception: Old password is incorrect') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Old password is incorrect'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error changing password: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: const Text('Change Password'),
                    ),
                  ),
                  const SizedBox(height: 27.0),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
