import 'package:flutter/material.dart';

import '../config/pref.dart';
import 'auth/login_page.dart';
import 'home/home_page.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Session().getUserToken(),
      builder: (_, snapshot) {
        String? token = snapshot.data;
        if (token == null || token == "") {
          return const LoginPage();
        } else {
          return const HomePage();
        }
      },
    );

    // return const HomePage();
  }

}