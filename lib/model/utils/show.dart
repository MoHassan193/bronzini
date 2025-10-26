import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


class Show {
  static void mo(String msg,Color? color) {
    Fluttertoast.showToast(
        msg: msg,
        fontAsset: "assets/messiriFont/ElMessiri-Medium.ttf",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor:  color ?? Colors.teal,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }
}