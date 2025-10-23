import'dart:async';
import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
/*import 'package:in_app_update/in_app_update.dart';*/
import 'package:shared_preferences/shared_preferences.dart';
import 'Constants.dart';
import 'Login.dart';

class SplashScreen extends StatefulWidget
{
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  late SharedPreferences prefs;

  Future<void> _initSharedPreferences() async {
  prefs = await SharedPreferences.getInstance();

  String? username = prefs.getString('username_remember');
  String? password = prefs.getString('password_remember');

  /*prefs.setInt('lastActive', DateTime.now().millisecondsSinceEpoch);*/

  print(DateTime.now().millisecondsSinceEpoch);
  /*String? company = prefs.getString('company_name');
  String? serial_no = prefs.getString('serial_no');*/

  Timer(Duration(seconds: 2), ()
  {
    if(Platform.isAndroid)
    {
      /*try
      {
        InAppUpdate.checkForUpdate().then((updateInfo)
        {
          if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {

            if (updateInfo.immediateUpdateAllowed) {
              // Perform immediate update
              InAppUpdate.performImmediateUpdate().then((appUpdateResult) {
                if (appUpdateResult == AppUpdateResult.success)
                {
                  if(username == null && password == null)
                  {
                    Navigator.pushReplacement
                      (
                      context,
                      MaterialPageRoute(builder: (context) => Login(username : '',password: '')),
                    );
                  }
                  else
                  {
                    Navigator.pushReplacement
                      (
                      context,
                      MaterialPageRoute(builder: (context) => Login(username : username!,password: password!)),
                    );
                  }
                }
                else
                {
                  SystemNavigator.pop();
                }
              });
            }
            else if (updateInfo.flexibleUpdateAllowed)
            {
              //Perform flexible update
              InAppUpdate.startFlexibleUpdate().then((appUpdateResult)
              {
                if (appUpdateResult == AppUpdateResult.success)
                {
                  //App Update successful
                  InAppUpdate.completeFlexibleUpdate();
                }
                else
                {
                  SystemNavigator.pop();
                }
              });
            }
          }
          else
          {
            if(username == null && password == null)
            {
              Navigator.pushReplacement
              (
                context,
                MaterialPageRoute(builder: (context) => Login(username : '',password: '')),
              );
            }
            else
            {
              Navigator.pushReplacement
                (
                context,
                MaterialPageRoute(builder: (context) => Login(username : username!,password: password!)),
              );
            }
          }
        });
      }
      catch (e)
      {
        if(username == null && password == null)
        {
          Navigator.pushReplacement
            (
            context,
            MaterialPageRoute(builder: (context) => Login(username : '',password: '')),
          );
        }

        else
        {
          Navigator.pushReplacement
            (
            context,
            MaterialPageRoute(builder: (context) => Login(username : username!,password: password!)),
          );
        }
      }*/

      if(username == null && password == null)
      {
        Navigator.pushReplacement
          (
          context,
          MaterialPageRoute(builder: (context) => Login(username : '',password: '')),
        );
      }

      else
      {
        Navigator.pushReplacement
        (
          context,
          MaterialPageRoute(builder: (context) => Login(username : username!,password: password!)),
        );
      }
    }
    else
    {
      if(username == null && password == null)
      {
        Navigator.pushReplacement
          (
          context,
          MaterialPageRoute(builder: (context) => Login(username : '',password: '')),
        );
      }
      else
      {
        Navigator.pushReplacement
          (
          context,
          MaterialPageRoute(builder: (context) => Login(username : username!,password: password!)),
        );
      }}
    });
}

  @override
  void initState()
  {
    super.initState();
    /*FirebaseMessaging.instance.getToken().then((value) {
      String? token = value;
      print(token);
    });*/
    _initSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:Stack(children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/fincorego_logo_png.png',
                width: 200,
                height: 200,
              ),
              SizedBox(height: 20),
              SpinKitWave(
                color: app_color,
                size: 40.0,
                itemCount: 5,
              )
            ])),

        Positioned(
          bottom: 20, // Adjust this value according to your preference
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "© 2023-2025 CSH LLC. All Rights Reserved.",
              style: GoogleFonts.poppins(
                color: Colors.black54, // You can adjust the color here
                fontSize: 12, // You can adjust the font size here
              ))))]));}}