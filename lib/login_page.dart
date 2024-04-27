import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback? onRegisterClicked;
  final VoidCallback? onLoginSuccess; // Callback for when login is successful

  LoginPage({this.onRegisterClicked, this.onLoginSuccess});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Column(
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () async {
              // Retrieve email and password from text fields
              String email = emailController.text;
              String password = passwordController.text;

              // Check if email and password are not empty
              if (email.isNotEmpty && password.isNotEmpty) {
                // Call the signIn method with the retrieved email and password
                AuthService().signIn(email, password).then((user) {
                  if (user != null) {
                    onLoginSuccess?.call(); // Trigger callback if provided
                  }
                });
              } else {
                // Display an error message if email or password is empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter email and password')),
                );
              }
            },
            child: Text("Login"),
          ),
          TextButton(
            onPressed: onRegisterClicked, // Use the callback here
            child: Text("Don't have an account? Register here"),
          ),
        ],
      ),
    );
  }
}
