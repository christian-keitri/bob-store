import 'dart:convert';

import 'package:amazon_clone_tutorial/common/widgets/bottom_bar.dart';
import 'package:amazon_clone_tutorial/constants/error_handling.dart';
import 'package:amazon_clone_tutorial/constants/global_variables.dart';
import 'package:amazon_clone_tutorial/models/user.dart';
import 'package:amazon_clone_tutorial/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Sign up the user
  Future<void> signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    try {
      User user = User(
        id: '',
        name: name,
        email: email,
        password: password,
        address: '',
        type: '',
        token: '',
        cart: [],
      );

      final res = await http.post(
        Uri.parse('$uri/api/signup'),
        body: user.toJson(),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (context.mounted) {
        httpErrorHandle(
          response: res,
          context: context,
          onSuccess: () {
            scaffoldMessenger?.showSnackBar(
              const SnackBar(
                content: Text(
                  'Account created! Login with the same credentials!',
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Sign in the user
  Future<void> signInUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    try {
      final res = await http.post(
        Uri.parse('$uri/api/signin'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (context.mounted) {
        httpErrorHandle(
          response: res,
          context: context,
          onSuccess: () async {
            final prefs = await SharedPreferences.getInstance();
            userProvider.setUser(res.body);
            await prefs.setString(
              'x-auth-token',
              jsonDecode(res.body)['token'],
            );

            if (context.mounted) {
              navigator.pushNamedAndRemoveUntil(
                BottomBar.routeName,
                (route) => false,
              );
            }
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // Get user data
  Future<void> getUserData(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      if (token == null || token.isEmpty) {
        await prefs.setString('x-auth-token', '');
        token = '';
      }

      final tokenRes = await http.post(
        Uri.parse('$uri/tokenIsValid'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (!context.mounted) return;

      final isValid = jsonDecode(tokenRes.body);

      if (isValid == true) {
        final userRes = await http.get(
          Uri.parse('$uri/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'x-auth-token': token,
          },
        );

        if (context.mounted) {
          userProvider.setUser(userRes.body);
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger?.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
