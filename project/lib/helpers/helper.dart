import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Helper {
  static void showToast(BuildContext context, String message) {
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
      )
    );
  }
}