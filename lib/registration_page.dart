import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegistrationPage extends StatelessWidget {
  final VoidCallback? onSignInClicked; // Callback for when the sign in button is clicked

  RegistrationPage({this.onSignInClicked});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
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
                // Call the signUp method with the retrieved email and password
                AuthService().signUp(email, password).then((user) {
                  if (user != null) {
                    onSignInClicked?.call(); // Trigger callback if provided
                  }
                });
              } else {
                // Display an error message if email or password is empty
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter email and password')),
                );
              }
            },
            child: Text("Register"),
          ),
          TextButton(
            onPressed: onSignInClicked, // Use the callback here
            child: Text("Already have an account? Sign in here"),
          ),
        ],
      ),
    );
  }
}
