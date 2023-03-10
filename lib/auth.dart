import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

typedef OAuthSignIn = void Function();

final FirebaseAuth _auth = FirebaseAuth.instance;

const withSilentVerificationSMSMFA = true;

class ScaffoldSnackbar {
  ScaffoldSnackbar(this._context);
  factory ScaffoldSnackbar.of(BuildContext context) {
    return ScaffoldSnackbar(context);
  }

  final BuildContext _context;
  void show(String message) {
    ScaffoldMessenger.of(_context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

enum AuthMode { login, register }

extension on AuthMode {
  String get label => this == AuthMode.login ? 'Login' : 'Register';
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String error = '';
  String verificationId = '';

  AuthMode mode = AuthMode.login;

  bool isLoading = false;

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  late Map<Buttons, OAuthSignIn> authButtons;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      mode.label,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w600),
                    ),
                    SafeArea(
                      child: Form(
                        key: formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Visibility(
                                visible: error.isNotEmpty,
                                child: MaterialBanner(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  content: SelectableText(error),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          error = '';
                                        });
                                      },
                                      child: const Text(
                                        'dismiss',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  ],
                                  contentTextStyle:
                                      const TextStyle(color: Colors.white),
                                  padding: const EdgeInsets.all(10),
                                ),
                              ),
                              Column(
                                children: [
                                  TextFormField(
                                    controller: emailController,
                                    decoration: const InputDecoration(
                                      hintText: 'Email',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value != null && value.isNotEmpty
                                            ? null
                                            : 'Required',
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Password',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) =>
                                        value != null && value.isNotEmpty
                                            ? null
                                            : 'Required',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _handleMultiFactorException(
                                            _emailAndPassword,
                                          ),
                                  child: isLoading
                                      ? const CircularProgressIndicator
                                          .adaptive()
                                      : Text(mode.label),
                                ),
                              ),
                              const SizedBox(height: 20),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  children: [
                                    TextSpan(
                                      text: mode == AuthMode.login
                                          ? 'Register'
                                          : 'Login',
                                      style:
                                          const TextStyle(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          setState(() {
                                            mode = mode == AuthMode.login
                                                ? AuthMode.register
                                                : AuthMode.login;
                                          });
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMultiFactorException(
    Future<void> Function() authFunction,
  ) async {
    setIsLoading();
    try {
      await authFunction();
    } on FirebaseAuthMultiFactorException catch (e) {
      setState(() {
        error = '${e.message}';
      });
      final firstHint = e.resolver.hints.first;
      if (firstHint is! PhoneMultiFactorInfo) {
        return;
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    } catch (e) {
      setState(() {
        error = '$e';
      });
    } finally {
      setIsLoading();
    }
  }

  Future<void> _emailAndPassword() async {
    if (formKey.currentState?.validate() ?? false) {
      if (mode == AuthMode.login) {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } else if (mode == AuthMode.register) {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      }
    }
  }
}
