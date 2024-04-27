import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';  // Ensure this file exists with the login functionality
import 'registration_page.dart';  // Ensure this file exists with the registration functionality
import 'homepage.dart';
import 'profile_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artfolio',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(
          onRegisterClicked: () {
            Navigator.pushNamed(context, '/register');
          },
          onLoginSuccess: () {
            Navigator.pushReplacementNamed(context, '/profile'); // Navigate to home and replace the current page
          },
        ),
        '/register': (context) => RegistrationPage(
          onSignInClicked: () {
            Navigator.pop(context); // Go back to the login page
          },
        ),
        '/home': (context) => HomePage(),
         // Define your homepage widget
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}