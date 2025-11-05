import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class CommenMethods
{
  checkConnectivity(BuildContext context) async
  {
    var connectionResult = await Connectivity().checkConnectivity();

    if(connectionResult != ConnectivityResult.mobile && connectionResult != ConnectivityResult.wifi)
    {
      if(!context.mounted)return;
      displaySnackBar("You are in offline, please check your connection ",context);
    }
  }
  displaySnackBar(String messageText,BuildContext context)
  {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}