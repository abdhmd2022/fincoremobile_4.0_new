import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import 'Help.dart';
import 'SerialSelect.dart';
import 'constants.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class Login extends StatefulWidget
{
  final String username,password ;
  const Login(
      {
        required this.username,
        required this.password,
      }
      );
  @override
  _LoginPageState createState() => _LoginPageState(usernamee: username,passwordd: password);
}

class _LoginPageState extends State<Login>  with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _resetformKey = GlobalKey<FormState>();
  final _otpformKey = GlobalKey<FormState>();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Color _buttonColor = app_color;
  Color _resetbuttonColor = app_color;

  late SharedPreferences prefs_login;

  bool isValidId = false;
  String responseMessage = ''; // To store the server response.
  String socketId = ''; // To store the socket ID.

  bool isVisibleTimer = false;

  late IO.Socket socket;

  bool isOTPVerified = false,isAnotherDevice = false;

  dynamic socket_data;

  GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  bool _isLoading = false,_isLoadingResetPass = false;

  final String SHARED_PREFERENCES_NAME = "login_prefs";

  bool isDirectLogin = false, isOTPLogin = false;

  String? username_prefs,password_prefs ;

  String? deviceIdentifier = '';

  String generatedotp = '';

  dynamic jsonPayload, response_getusers,response_resetpass;

  bool isVisibleLoginForm= true,isVisibleResetPassForm = false,isVisibleOTPForm = false;

  late String usernamee = '',resetemail = '';
  late final Color backgroundColor; // declare backgroundColor as non-nullable
  bool _obscureText = true;
  late String serial_no,role_id,license_expiry,hostname,hostpass,hostuser,dbname;

  DateTime? lastBackPressedTime;

  late String passwordd = '';
  bool remember_me = true;
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _resetemailFocusNode = FocusNode();
  late TickerProvider tickerProvider;

  _LoginPageState(
   {
        required this.usernamee,
        required this.passwordd,
   }
   );

  void emitSaveId(final jsonPayload,final response) {
    if(isOTPVerified)
      {
        socket.emit('saveMyId', jsonPayload);

        socket.once('isIdSaved', (data)
        {
          if(data)
          {
            final responseData = json.decode(response.body);

            final myList = <Map<String, dynamic>>[];

            for (final data in responseData)
            {
              final newObj = <String, dynamic>{
                'serial_no': data['serial_no'],
                'role_id': data['role_id'],
                'license_expiry': data['license_expiry'],
                'website_url': data['website_url'],
                'token': data['token'],
              };
              myList.add(newObj);
            }
            String jsonString = jsonEncode(myList);

            if (remember_me) {
              prefs_login.setString('username_remember', usernamee);
              prefs_login.setString('password_remember', passwordd);
              prefs_login.setString('username', usernamee);
              prefs_login.setString('password', passwordd);
              prefs_login.remove('sync_pref');
              prefs_login.remove('serial_no');
            }
            else
            {
              prefs_login.remove('username_remember');
              prefs_login.remove('password_remember');
              prefs_login.setString('username', usernamee);
              prefs_login.setString('password', passwordd);
            }
            prefs_login.setString('login_list', jsonString);

            if(mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SerialSelect()),
              );}}
          else
          {
            _scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('An error occured.'),
              ));}});}}

  Future<void> _showConfirmationDialogAndExit(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button to close dialog
      builder: (BuildContext context) {
        return ScaleTransition
        (
          scale: CurvedAnimation(
            parent: AnimationController(
              duration: const Duration(milliseconds: 500),
              vsync: tickerProvider,
            )..forward(),
            curve: Curves.fastOutSlowIn,
          ),
          child: AlertDialog(
            title: Text('Exit Confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Do you really want to Exit?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'No',
                  style: TextStyle(
                    color: app_color, // Change the text color here
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop ();
                },
              ),

              TextButton(
                child: Text(
                  'Yes',
                  style: TextStyle(
                    color: app_color, // Change the text color here
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  exit(0);
                })]));});
  }

  void navigateToPDFView(BuildContext context) async {

  String pdfPath = 'assets/installation.pdf'; // Path to your PDF file in the assets folder
  ByteData data = await rootBundle.load(pdfPath);
  List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  // Save the PDF file to a temporary location
  final tempDir = await getTemporaryDirectory();
  final tempFilePath = '${tempDir.path}/installation_guide.pdf';
  await File(tempFilePath).writeAsBytes(bytes);


  final result = await OpenFile.open(tempFilePath);

  if (result.type == ResultType.noAppToOpen) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('PDF Viewer Not Found'),
          content: Text('No PDF viewer app is installed on your device.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  }

  Timer? _timer;
  int _start = 60; // 60 seconds countdown
  bool _isButtonEnabled = false; // Button enable state
  String _formattedTime = "01:00"; // Timer display

  void _startTimer() {

    _start = 60; // Reset countdown to 60 seconds
    _formattedTime = _formatDuration(_start); // Reset the formatted time
    _isButtonEnabled = false; // Disable button initially

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start > 0) {
        setState(() {
          _isButtonEnabled = false;
          isVisibleTimer = true;

          /*print('_start value $_start');*/
          _start--;
          _formattedTime = _formatDuration(_start);
        });
      } else {
        _stopTimer(); // Stop the timer when it reaches zero
        setState(() {
          _isButtonEnabled = true; // Enable the button
          isVisibleTimer = false;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel(); // Cancel the timer
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  /*Future<String> generateInstructions() async {

    final pdf = pw.Document();

    List<String> lines = [
      "1. For Registration, First you need to install Fincore Desktop Application where your Tally is installed. You can download Fincore Desktop Application from the following link http://mobile.chaturvedigroup.com/download/",
      "2. After download is done, install that application in your PC/Server",
      "3. Once installation is done, Open Tally in your PC/Server and select company which you want to add",
      "4. Once the above step is done, Open Fincore Desktop Application and click 'Register Here'",
      "5. Fill the required information and click 'Register'",
      "6. After successful activation, you can now set up the Fincore Desktop Application and add companies in it of which you want to see data in Fincore Mobile",
      "7. If you want to experience Fincore Mobile, you can login with the following credentials for demonstration purposes (email address: demouser@ca-eim.com, password: user1234)",
      "8. For any kind of help, you can contact our support team at saadan@ca-eim or visit our website http://tallyuae.ae"
    ];

    final heading = pw.Text(
      "Instructions",
      style: pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
      ),
    );

    final lineTexts = lines.map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 14))).toList();

    final content = <pw.Widget>[
      pw.Center(child: heading),
      pw.SizedBox(height: 20), // Add some spacing between heading and lines
    ];
    content.addAll(lineTexts);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final filePath = path.join(output.path, 'instructions.pdf');

    await File(filePath).writeAsBytes(await pdf.save());

    return filePath;
  }*/

  Future<void> _initSharedPreferences() async {
    prefs_login = await SharedPreferences.getInstance();

    username_prefs = usernamee;
    password_prefs = passwordd;

    print(usernamee);

    await prefs_login.remove('username');
    await prefs_login.remove('password');
    await prefs_login.remove('company_name');
    await prefs_login.remove('serial_no');
    await prefs_login.remove('datetype');
    await prefs_login.remove('token');

    tickerProvider = this;

    if(usernamee!="null" && usernamee.isNotEmpty && usernamee !=null)
    {
      _login();
    }
  }

  Future<void> _resetpass() async {
    setState(() {
      _showProcessingDialog();
    });

    String enteredemail = resetemailController.text;
    try
    {
      Map<String,String> headers = {
        'Authorization' : 'Bearer $authTokenBase',
        "Content-Type": "application/json"
      };

      var body = jsonEncode({
        'email': enteredemail,
      });

      response_resetpass = await http.post(
          Uri.parse('$BASE_URL_config/api/login/forgotPassword'),
          body: body,
          headers:headers
      );

      if (response_resetpass.statusCode == 200)
      {
        final token = jsonDecode(response_resetpass.body)['token'];
        final name = jsonDecode(response_resetpass.body)['name'];

        // Send password reset email
        await _sendPasswordResetEmail(enteredemail,token,name);

        // Show success message
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Password reset email sent successfully'),
          ),
        );

        setState(() {
          usernameController.text = resetemailController.text;
          resetemailController.clear();
          isVisibleResetPassForm = false;
          isVisibleLoginForm = true;
        });
      }
      else
      {
        final error = jsonDecode(response_resetpass.body)['error'];
        /*print(error);*/
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('$error'),
          ),
        );
      }
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
    finally
    {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(app_color), // Change the color here
              ),
              SizedBox(height: 16),
              Text('Sending Reset Email'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail(String emailAddress, String token,String name) async {

    final smtpServer = SmtpServer('smtp.zoho.com',
        username: 'contact@tallyuae.ae', // email id
        password: '355dD@3988', // password
        port: 587
    );

    final message = Message()
      ..from = Address('contact@tallyuae.ae','noreply') // Replace with your Outlook email
      ..recipients.add(emailAddress) // Use the email entered by the user

      ..subject = 'Password Reset Request'
      ..html = '''
         <div style="border: 1px solid #ccc; padding-left: 30px; padding-right: 30px; padding-top: 30px; padding-bottom: 30px; margin-left: 20px; margin-right: 20px; margin-top: 0px; text-align: center;">

          <a href="https://tallyuae.ae/">
              <img src="https://mobile.chaturvedigroup.com/fincore_logo/tally_1.png" alt="Image" style="width: 150px; height: auto; margin-bottom: 10px;">
          </a>
         <div style="text-align: center;"><p style="font-size: 16px; font-family: Arial, sans-serif; color: #30D5C8; font-weight: bold">Fincore Mobile Password Reset</p></div>
         
        <div style="text-align: start;"><p style="font-size: 14px; font-family: Arial, sans-serif; color: #333;">Dear $name,</p></div>
        <div style="text-align: start;"><p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">We’ve received your request to reset your password. Please click the link below to complete the reset.</p></div>
        <br>
        <div style="text-align: center;">
          <p>
            <a href="$BASE_URL_config/setPassword?token=$token" style="display: inline-block; background-color: #30D5C8; color: #fff; font-size: 16px; font-family: Arial, sans-serif; text-decoration: none; padding: 10px 20px; border-radius: 5px;">Reset Password</a>
          </p> 
        </div>        
        <br>
        <div style="text-align: start;"><p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">If you need additional assistance, or you did not make this change, please contact <a href="mailto:saadan@ca-eim.com">saadan@ca-eim.com</a></p></div>
        <br>
        <div style="text-align: start;"><p style="color: #999999; font-style: italic; font-size: 12px">This is system generated email. Do not reply.</p>
    </div>
        
        <div style="text-align: start;"><div style="text-align: start; border-top: 1px solid #ccc; padding-top: 10px;  "><p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2;">© 2024 Chaturvedi Software House LLC. All Rights Reserved</p>
        <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2; padding-top: 0px">513 Al Khaleej Center Bur Dubai, Dubai United Arab Emirates, +97143258361 </p></div>
      </div>
      ''';
    try {
      final sendReport = await send(message, smtpServer); // send mail

      /*_scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Message sent'),
        ),
      );*/

      /*print('Reset Email sent: ${sendReport.toString()}');*/
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      /*print('$e');*/
    }
  }

  /*Future<void> _sendPasswordResetEmail(String emailAddress, String token) async {
    final Email email = Email(
      body: '''
        <p>Dear Fincore Mobile user,</p>
        <p>We’ve received your request to reset your password. Please click the link below to complete the reset.</p>
        <p><a href="http://$BASE_URL_config/setPassword?token=$token">Reset My Password</a></p>
        <p>If you need additional assistance, or you did not make this change, please contact <a href="mailto:saadan@ca-eim.com">saadan@ca-eim.com</a>.</p>
        <p>© 2024 Chaturvedi Software House LLC. All Rights Reserved<br>
        513 Al Khaleej Center Bur Dubai, Dubai United Arab Emirates, +971-43258361 </p>
      ''',
      subject: 'Password Reset Request',
      recipients: [emailAddress],
      isHTML: true,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {
      print('Error sending email: $error');
    }
  }*/

  Future<void> _login() async {
    isDirectLogin = false;
    isOTPLogin = false;
    isOTPVerified = false;
    isAnotherDevice = false;

    String entered_username = usernameController.text;
    String entered_password = passwordController.text;

    if(username_prefs == null && password_prefs == null)
      {
        if(entered_username == 'demouser@ca-eim.com' && entered_password == 'user1234')
          {
            isOTPVerified = true;
            isAnotherDevice = true;

            _directlogin();
          }
        else
          {
            _otplogin(entered_username);
          }
      }
    else
      {
        if(entered_username == 'demouser@ca-eim.com' && entered_password == 'user1234')
        {
          isOTPVerified = true;
          isAnotherDevice = true;

          final jsonPayload = {
            'username': entered_username,
            'password': entered_password,
            'macId': deviceIdentifier,
          };

          socket.emit('deleteMyId', jsonPayload);


          _directlogin();
        }
        else
        {
          if(username_prefs!=entered_username)
          {
            _otplogin(entered_username);
          }
          else
          {
            _directlogin();
          }
        }}}

  Future<void> _directlogin() async {
    setState(() {
      _isLoading = true;
      isDirectLogin = true;
      isOTPLogin = false;
      response_getusers = null;
    });

    try
    {
      Map<String,String> headers = {
        'Authorization' : 'Bearer $authTokenBase',
        "Content-Type": "application/json"
      };

      var body = jsonEncode({
        'username': usernamee,
        'password': passwordd
      });

      response_getusers = await http.post(
          Uri.parse('$BASE_URL_config/api/login/getusers'),
          body: body,
          headers:headers
      );

      if (response_getusers.statusCode == 200)
      {
        String expectedBody = "Invalid Username or Password Please Try Again";

        String responsee = response_getusers.body;
        responsee = responsee.trim();

        if(responsee == expectedBody)
        {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(responsee),
            ),
          );
          _usernameFocusNode.unfocus();
          _passwordFocusNode.unfocus();
        }
        else
        {
          try
          {
            jsonPayload = {
              'username': usernamee,
              'password': passwordd,
              'macId': deviceIdentifier,
            };
            /*print('emitting');*/
            socket.emit('myId', jsonPayload);
          }
          catch(e)
    {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(e.toString()),
            ),
          );
    }}}
      else
      {
        final error = jsonDecode(response_getusers.body)['error'];
        /*print(error);*/
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('$error'),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _otplogin(String email) async {
    setState(() {
      _isLoading = true;
      isDirectLogin = false;
      isOTPLogin = true;
      response_getusers = null;
    });

    try
    {
      Map<String,String> headers = {
        'Authorization' : 'Bearer $authTokenBase',
        "Content-Type": "application/json"
      };

      var body = jsonEncode({
        'username': usernamee,
        'password': passwordd
      });

      response_getusers = await http.post(
          Uri.parse('$BASE_URL_config/api/login/getusers'),
          body: body,
          headers:headers
      );
      /*response_getusers = await http.post(
        Uri.parse('$BASE_URL_config/api/login/getusers'),
        body: {
          'username': usernamee,
          'password': passwordd,
        },
      );*/

      /*int code = response_getusers.statusCode;

      final body = response_getusers.body;

      print('response code : $code');

      print('body : $body');
*/

      if (response_getusers.statusCode == 200)
      {
        String expectedBody = "Invalid Username or Password Please Try Again";

        String responsee = response_getusers.body;
        responsee = responsee.trim();
        if(responsee == expectedBody)
        {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(responsee),
            ),
          );

          _usernameFocusNode.unfocus();
          _passwordFocusNode.unfocus();
        }
        else
        {
          try
          {
            // Create a JSON object containing username and password
            jsonPayload = {
              'username': usernamee,
              'password': passwordd,
              'macId': deviceIdentifier,
            };
            /*print('emitting');*/

            socket.emit('myId', jsonPayload);
          }
          catch(e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
        }
      }
      else
      {

        final error = jsonDecode(response_getusers.body)['error'];
        /*print(error);*/
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      setState(()
      {
        _isLoading = false;
      });
    }
  }

  final passwordController = TextEditingController();

  final usernameController = TextEditingController();

  final resetemailController = TextEditingController();

  bool isButtonDisabled = true,isResetPassButtonDisabled = true;

  final requiredLength = 4; // the required length of the password

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);
    resetemailController.addListener(_onResetEmailChanged);
    usernameController.text = usernamee;
    passwordController.text = passwordd;



    /*FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      *//*print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');*//*

      if (message.notification != null) {
        *//*print('Message also contained a notification: ${message.notification}');*//*
      }
    });*/

    // Initialize Socket.IO connection
    socket = IO.io('$BASE_URL_config', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth' : {
        'token' : '$authTokenBase'
      }
    });

    /*socket = IO.io('http://192.168.2.110:5999', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth' : {
        'token' : '$authTokenBase'
      }
    });*/

    /*socket = IO.io('http://192.168.2.80:5999', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth' : {
        'token' : '$authTokenBase'
      }
    });*/

    // Listen for the socket connection event and get the socket ID
    socket.on('connect', (_) {
      socketId = socket.id!;
    });

    socket.on('idConflict', (data) {
      // show dialog
      if(mounted)
        {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('User Already Logged In'),
                content: Text('This user is already logged in on another device. Do you want to continue here?'),
                actions: <Widget>[
                  TextButton(
                    child: Text('No',
                        style : TextStyle (
                            color: app_color
                        )),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      // Handle the "No" option (e.g., disconnect or navigate away)
                    },
                  ),
                  TextButton(
                    child: Text('Yes',
                    style : TextStyle (
                      color: app_color
                    )),
                    onPressed: () async {

                      String username = usernameController.text;

                      Navigator.of(context).pop();

                      String entered_username = usernameController.text;
                      String entered_password =passwordController.text;

                      /*print('username = $entered_username password = $entered_password');*/
                      if(entered_username == 'demouser@ca-eim.com' && entered_password == 'user1234')
                        {
                          /*sendOTP(username);*/

                          /*sendOTP('saadan@ca-eim.com');*/

                          /*_showOtpDialog(data,username);*/

                          isOTPVerified = true;
                          isAnotherDevice = true;

                          socket.emit('deleteMyId', data);

                        _directlogin();
                        }
                      else
                        {
                          sendOTP(username);

                          /*sendOTP('saadan@ca-eim.com');*/
                          socket_data = data;

                          setState(() {
                            isVisibleLoginForm = false;
                            isVisibleResetPassForm = false;
                            _isButtonEnabled = false;
                            isVisibleTimer = true;
                            _startTimer();
                            isVisibleOTPForm = true;
                            maskedEmail = username;

                          });

                          /*_showOtpDialog(data,username);*/    // old otp dialog

                       /* isOTPVerified = true;
                       isAnotherDevice = true;

                       socket.emit('deleteMyId', data);

                        _directlogin();*/
                        }})]);});}});

    socket.on('isValidId', (data) {

      /*print('isValidiD : $data');*/

      if((data && isDirectLogin && isOTPVerified == true && isAnotherDevice == true) || (data && isDirectLogin && isOTPVerified == false && isAnotherDevice == false))
        {
          isValidId = data;

          if(data)
          {
            isOTPVerified=true;
            emitSaveId(jsonPayload,response_getusers);
          }
          else
          {
            isOTPVerified=false;

            prefs_login.remove('username_remember');
            prefs_login.remove('password_remember');

            _scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('User is active on another device.'),
              ),
            );
          }
        }

      else if (data && isOTPLogin  && isOTPVerified == false)
        {
          isValidId = data;

          if(data)
          {
            /*setState(() {
              isOTPVerified = true;
              emitSaveId(jsonPayload, response_getusers);
            });*/

            /*sendOTP('saadan@ca-eim.com');*/

            sendOTP(usernamee);

            /*showDialog(
              context: context,
              builder: (BuildContext context) {
                final TextEditingController otpController = TextEditingController();
                final maskedEmail = usernamee;
                String currentText = "";
                return AlertDialog(
                  title: Text('OTP Verification'),
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'OTP was sent to:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Flexible(child: Text(maskedEmail)),
                      Padding(
                        padding: EdgeInsets.only(left: 5,right: 5,top: 16),
                        child: PinCodeTextField(
                          appContext: context,
                          pastedTextStyle: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.normal,
                          ),
                          length: 4, // Specify the length of OTP
                          onChanged: (value) {
                            currentText = value;
                          },
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.circle,
                            borderRadius: BorderRadius.circular(10),
                            fieldHeight: 50,
                            fieldWidth: 50,
                            activeFillColor: Colors.white,
                            inactiveFillColor: Colors.white,
                            activeColor: app_color,
                            inactiveColor: Colors.grey,
                            borderWidth: 1,
                            selectedColor: app_color
                          ),
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          onCompleted: (value) {
                            // OTP entry is complete

                          },
                          obscureText: true,
                          textStyle: TextStyle(
                          fontWeight: FontWeight.normal, // Set the font weight to normal
                          )))]),
                  actions: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                      ),
                      onPressed: () {
                        if (currentText.length == 4) {
                          final generatedOTP = generatedotp;
                          final enteredOTP = currentText;

                          if (enteredOTP == generatedOTP) {
                            isOTPVerified = true;
                            emitSaveId(jsonPayload, response_getusers);
                          } else {
                            isOTPVerified = false;

                            Fluttertoast.showToast(msg: 'Incorrect OTP');
                          }
                        } else {
                          isOTPVerified = false;

                          Fluttertoast.showToast(msg: 'Please enter a 4-digit OTP');
                        }
                      },
                      child: Text('Verify',
                          style: TextStyle(
                              color: Colors.white
                          )),
                    )]);});*/

            socket_data = data;

            setState(() {
              isVisibleLoginForm = false;
              isVisibleResetPassForm = false;
              _isButtonEnabled = false;
              isVisibleTimer = true;
              _startTimer();
              isVisibleOTPForm = true;
              maskedEmail = usernamee;
            });
          }
          else
          {
            isOTPVerified=false;
            prefs_login.remove('username_remember');
            prefs_login.remove('password_remember');

            _scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('User is active on another device.'),
              ),);}}
      else
      {
        prefs_login.remove('username_remember');
        prefs_login.remove('password_remember');

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('User is active on another device.'),
          ));}});
    try
    {
      socket.connect();
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ));}
    _initSharedPreferences();
  }

 /* String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length == 2) {
      final username = parts[0];
      final domain = parts[1];
      final maskedUsername = _maskPart(username);
      final maskedDomain = _maskPart(domain);
      return '$maskedUsername@$maskedDomain';
    }
    return email;
  }*/

 /* String _maskPart(String part) {
    if (part.length <= 2) {
      return part;
    }
    final firstCharacter = part[0];
    final lastCharacter = part[part.length - 1];
    final maskedPart = '*' * (part.length - 2);
    return '$firstCharacter$maskedPart$lastCharacter';
  }*/

  /*void _showOtpDialog(final data, final email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController otpController = TextEditingController();
        final maskedEmail = email;
        String currentText = "";
        return AlertDialog(
          title: Text('OTP Verification'),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'OTP was sent to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 5.0),
              Flexible(child: Text(maskedEmail)),
              Padding(
                padding: EdgeInsets.only(left: 5,right: 5,top: 16),
                child: PinCodeTextField(
                  appContext: context,
                  pastedTextStyle: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                  length: 4, // Specify the length of OTP
                  onChanged: (value) {
                    currentText = value;
                  },
                  pinTheme: PinTheme(
                      shape: PinCodeFieldShape.circle,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 50,
                      fieldWidth: 50,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      activeColor: app_color,
                      inactiveColor: Colors.grey,
                      borderWidth: 1,
                      selectedColor: app_color
                  ),
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  onCompleted: (value) {
                    // OTP entry is complete
                  },
                  obscureText: true,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
              ),
              onPressed: () {

                if (currentText.length == 4) {
                  final generatedOTP = generatedotp;
                  final enteredOTP = currentText;

                  if (enteredOTP == generatedOTP) {

                    isOTPVerified = true;
                    isAnotherDevice = true;

                    socket.emit('deleteMyId', data);

                    Navigator.of(context).pop(); // Close the dialog

                    _directlogin();
                  }
                  else {
                    isOTPVerified = false;
                    isAnotherDevice = false;
                    Fluttertoast.showToast(msg: 'Incorrect OTP');
                  }
                }
                else
                {
                  isOTPVerified = false;
                  isAnotherDevice = false;
                  Fluttertoast.showToast(msg: 'Please enter a 4-digit OTP');
                }
              },
              child: Text('Verify',
                  style: TextStyle(
                      color: Colors.white
                  )),
            )]);});
  }*/

  void sendOTP(String email) async {
    final random = Random();
    generatedotp = '${random.nextInt(10)}${random.nextInt(10)}${random.nextInt(10)}${random.nextInt(10)}'; // Generates a 4-digit random OTP

    print(generatedotp);
    final smtpServer = SmtpServer('smtp.zoho.com',
      username: 'contact@tallyuae.ae', // email id
      password: '355dD@3988', // password
      port: 587
    );

    final message = Message()
      ..from = Address('contact@tallyuae.ae','noreply') // Replace with your Outlook email
      ..recipients.add(email) // Use the email entered by the user
      ..subject = 'Your One-Time Passcode from Fincore Mobile'
      ..html =
            '''
                  <div style="border: 1px solid #ccc; padding-left: 30px; padding-right: 30px; padding-top: 30px; padding-bottom: 30px; margin-left: 20px; margin-right: 20px; margin-top: 0px; text-align: center;">
                 
                <a href="https://tallyuae.ae/">
                <img src="https://mobile.chaturvedigroup.com/fincore_logo/tally_1.png" alt="Image" style="width: 150px; height: auto; margin-bottom: 10px;">
            </a>
                <div style="text-align: center;"><p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">Your one-time passcode (OTP) to log into the Fincore Mobile app is</p></div>
                <br>
                <div style="text-align: center;">
                
                <p style="display: inline-block; background-color: #30D5C8; color: #fff; font-size: 16px; font-family: Arial, sans-serif; text-decoration: none; padding: 10px 20px; border-radius: 5px;">$generatedotp</p>
                </div >
                <br>
                <div style="text-align: start;"><p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">If you did not attempt this, please contact <a href="mailto:saadan@ca-eim.com">saadan@ca-eim.com</a></p></div>
                
                <br>
                      <div style="text-align: start;"><p style="color: #999999; font-style: italic; font-size: 12px">Disclaimer: 
                      This email is for verification purposes only.
                      Please do not share your OTP with anyone.<br><br>
                      This is system generated email. Do not reply.</p>
                </div>
              
                <div style="text-align: start;"><div style="text-align: start; border-top: 1px solid #ccc; padding-top: 10px;  "><p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2;">© 2024 Chaturvedi Software House LLC. All Rights Reserved</p>
                <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2; padding-top: 0px">513 Al Khaleej Center Bur Dubai, Dubai United Arab Emirates, +97143258361 </p>
                
                </div>
                </div>''';
    try {
      final sendReport = await send(message, smtpServer); // send mail

      /*_scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Message sent'),
        ),
      );*/

      /*print('Message sent: ${sendReport.toString()}');*/
    }
    catch (e)
    {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      /*print('$e');*/
    }
  }

  @override
  void didChangeDependencies()
  {
    super.didChangeDependencies();
    _getDeviceIdentifier();
  }

  Future<void> _getDeviceIdentifier() async
  {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? identifier = '';

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        identifier = androidInfo.id; // ✅ use 'id' instead of 'androidId'
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        identifier = iosInfo.identifierForVendor; // ✅ same key in iOS
      }
    } catch (e) {
      debugPrint('Error getting device identifier: $e');
    }
    setState(() {
      deviceIdentifier = identifier;
    });
  }

  void _onPasswordChanged() {
    // Check the length of the password
    if (passwordController.text.length < requiredLength) {
      // If the password is too short, update the button color to grey
      setState(() {
        _buttonColor = Colors.grey;
        isButtonDisabled = true;
      });
    }
    else
    {
      setState(() {
        _buttonColor = app_color;
        isButtonDisabled = false;
      });
    }
  }

  void _onResetEmailChanged() {
    // Check the length of the password
    if (resetemailController.text.isEmpty) {
      // If the password is too short, update the button color to grey
      setState(() {
        _resetbuttonColor = Colors.grey;
        isResetPassButtonDisabled = true;
      });
    }
    else
    {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(resetemailController.text))
    {
      setState(() {
        _resetbuttonColor = Colors.grey;
        isResetPassButtonDisabled = true;
      });
    }
      else
        {
          setState(() {
            _resetbuttonColor = app_color;
            isResetPassButtonDisabled = false;
          });}}}

  final TextEditingController otpController = TextEditingController();
  dynamic maskedEmail = '';
  String currentText = "";

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(child: MaterialApp(
        home: Builder(
            builder: (BuildContext context) {
              return WillPopScope(
                  onWillPop: () async {
                    final now = DateTime.now();
                    if (lastBackPressedTime == null || now.difference(lastBackPressedTime!) > Duration(seconds: 2)) {
                      lastBackPressedTime = now;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Press back again to exit')));
                      return false;
                    }
                    return true;
                  },
                  child: ScaffoldMessenger(
                      key: _scaffoldMessengerKey,
                      child: Scaffold(
                        key: _scaffoldKey,
                        appBar:PreferredSize(
                          preferredSize: Size.fromHeight(50),
                          child: AppBar(
                              backgroundColor:  app_color,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(20),
                                ),
                              ),
                              automaticallyImplyLeading: false,

                              centerTitle: true,
                              title: Text('Fincore',
                                style: TextStyle(
                                    color: Colors.white
                                ),),
                              actions: [
                                IconButton(
                                    icon: Icon(Icons.help_outline,
                                      color: Colors.white,),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => Help()),
                                      );})]
                          ),
                        ),
                        body:Container(
                            height: MediaQuery.of(context).size.height,
                            decoration:BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                    app_color.withOpacity(0.1),
                                    Colors.white,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter
                              ),
                            ),
                            child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(top: 30,bottom: 30),
                                    child: Image.asset(
                                      'assets/tally_1.png',
                                      width: 200.0,
                                      height: 100.0,
                                    ),
                                  ),

                                  Visibility(
                                      visible: isVisibleLoginForm,
                                      child:Expanded(child:  Container(
                                          padding: EdgeInsets.only(left: 32,right: 32,top : 70),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  spreadRadius: 0, // Spread radius
                                                  blurRadius: 20, // Blur radius
                                                  offset: Offset(0, -10),
                                                ),
                                              ],
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(50),
                                                  topRight: Radius.circular(50)
                                              )
                                          ),
                                          child:Form(
                                              key: _formKey,
                                              child: ListView(
                                                  children: [
                                                    Container(padding: EdgeInsets.only(top: 5),
                                                      child: TextFormField(
                                                        controller: usernameController,
                                                        focusNode: _usernameFocusNode,
                                                        decoration: InputDecoration(
                                                          labelText: 'Email Address',
                                                          filled: true,
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(5.0),
                                                            borderSide: BorderSide(
                                                              color: Colors.black12,
                                                            ),
                                                          ),
                                                          fillColor: Colors.white,
                                                          labelStyle: TextStyle(
                                                            color: Colors.black54, // Set the label text color to black
                                                          ),
                                                          focusedBorder: UnderlineInputBorder(
                                                            borderSide: BorderSide(color: app_color),
                                                          ),
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),

                                                        validator: (value) {
                                                          if (value == null || value.isEmpty)
                                                          {
                                                            return 'Please enter your email address';
                                                          }
                                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                                          {
                                                            return 'Please enter a valid email address';
                                                          }
                                                          return null;
                                                        },
                                                        onSaved: (value) => usernamee = value!,
                                                      ),),

                                                    SizedBox(height: 16.0),

                                                    TextFormField(
                                                      controller: passwordController,
                                                      focusNode: _passwordFocusNode,
                                                      decoration: InputDecoration(
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(5.0),
                                                          borderSide: BorderSide(
                                                            color: Colors.black12,
                                                          ),
                                                        ),

                                                        suffixIcon: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _obscureText = !_obscureText;
                                                            });
                                                          },
                                                          child: Icon(
                                                            _obscureText ? Icons.visibility_off :  Icons.visibility,
                                                          ),
                                                        ),

                                                        labelText: 'Password',
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        labelStyle: TextStyle(
                                                          color: Colors.black54, // Set the label text color to black
                                                        ),

                                                        focusedBorder: UnderlineInputBorder(
                                                          borderSide: BorderSide(color: app_color),

                                                        ),
                                                      ),
                                                      obscureText: _obscureText,

                                                      validator: (value)
                                                      {
                                                        if (value == null || value.isEmpty)
                                                        {
                                                          return 'Please enter your password';
                                                        }
                                                        return null;
                                                      },
                                                      onSaved: (value) => passwordd = value!,
                                                    ),

                                                    SizedBox(height: 5), // Ad

                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            // Handle "Forgot Password" tap event here
                                                            setState(() {
                                                              isVisibleLoginForm = false;
                                                              resetemailController.text = usernameController.text;
                                                              passwordController.clear();
                                                              isVisibleResetPassForm = true;
                                                            });
                                                          },
                                                          child: Text(
                                                            'Forgot Password?',
                                                            style: TextStyle(
                                                              color: Colors.black54,
                                                              /*decoration: TextDecoration.underline,*/
                                                            )
                                                          )
                                                        )
                                                      ]),

                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.start,children: [
                                                          Checkbox(
                                                            value: remember_me,
                                                            activeColor: app_color,
                                                            checkColor: Colors.white, // Optional: sets the color of the check icon
                                                            onChanged: (bool? value) {
                                                              setState(() {
                                                                remember_me = value!;
                                                              });
                                                            },
                                                          ),
                                                          Text(
                                                            'Remember Me',
                                                            style: TextStyle(fontSize: 16,color: Colors.black54),
                                                          ),
                                                        ]))
                                                      ],
                                                    ),

                                                    SizedBox(height: 32.0),

                                                    Container(
                                                      width: MediaQuery.of(context).size.width,
                                                      child: _isLoading
                                                          ? CupertinoActivityIndicator(
                                                        radius: 20.0,
                                                      )
                                                          : ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: _buttonColor,
                                                          elevation: 5, // Adjust the elevation to make it look elevated
                                                          shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                                        ),
                                                        onPressed: isButtonDisabled ? null : () {
                                                          if (_formKey.currentState != null &&
                                                              _formKey.currentState!.validate()) {
                                                            _formKey.currentState!.save();
                                                            _login();
                                                          }
                                                        },
                                                        child: Text('Login',
                                                            style: TextStyle(
                                                                color: Colors.white
                                                            )),
                                                      ),
                                                    ),

                                                    SizedBox(height: 5),

                                                    GestureDetector(onTap: ()
                                                    {
                                                      navigateToPDFView(context);
                                                    },
                                                        child: Container(
                                                            width: MediaQuery.of(context).size.width,
                                                            child : Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children:[
                                                                  Text('Not Registered?',
                                                                      style: TextStyle(color: Colors.black54)),

                                                                  Text('Click here for instructions',
                                                                      style: TextStyle(color: Colors.black54,
                                                                          fontWeight: FontWeight.bold,
                                                                          decoration: TextDecoration.underline))
                                                                ])))]))

                                      ),)
                                  ),

                                  Visibility(
                                      visible: isVisibleResetPassForm,
                                      child:Expanded(child:Container(
                                          padding: EdgeInsets.only(left: 32,right: 32,top: 70),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  spreadRadius: 0, // Spread radius
                                                  blurRadius: 20, // Blur radius
                                                  offset: Offset(0, -10),
                                                ),
                                              ],

                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(50),
                                                  topRight: Radius.circular(50)
                                              )
                                          ),
                                          child: Form(
                                              key: _resetformKey,
                                              child: ListView(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.only(top: 5),
                                                      child: TextFormField(
                                                        controller: resetemailController,
                                                        focusNode: _resetemailFocusNode,
                                                        decoration: InputDecoration(
                                                          labelText: 'Registered Email Address',
                                                          filled: true,
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(5.0),
                                                            borderSide: BorderSide(
                                                              color: Colors.black12,
                                                            ),
                                                          ),
                                                          fillColor: Colors.white,
                                                          labelStyle: TextStyle(
                                                            color: Colors.black54, // Set the label text color to black
                                                          ),
                                                          focusedBorder: UnderlineInputBorder(
                                                            borderSide: BorderSide(color: app_color),
                                                          ),
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),

                                                        validator: (value) {
                                                          if (value == null || value.isEmpty)
                                                          {
                                                            return 'Please enter your email address';
                                                          }
                                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                                          {
                                                            return 'Please enter a valid email address';
                                                          }
                                                          return null;
                                                        },
                                                        onSaved: (value) => resetemail = value!,
                                                      ),),

                                                    SizedBox(height: 32.0),

                                                    Container(
                                                      width: MediaQuery.of(context).size.width,
                                                      child: _isLoadingResetPass
                                                          ? CupertinoActivityIndicator(
                                                        radius: 20.0,
                                                      )
                                                          : ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: _resetbuttonColor,
                                                          elevation: 5, // Adjust the elevation to make it look elevated
                                                          shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                                        ),
                                                        onPressed: isResetPassButtonDisabled ? null : () {
                                                          if (_resetformKey.currentState != null &&
                                                              _resetformKey.currentState!.validate()) {
                                                            _resetformKey.currentState!.save();

                                                            if(resetemailController.text.trim() == 'demouser@ca-eim.com')
                                                            {
                                                              _scaffoldMessengerKey.currentState?.showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Reset password is not allowed for Demo User'),
                                                                ),
                                                              );
                                                            }
                                                            else
                                                            {
                                                              _resetpass();
                                                            }
                                                          }
                                                        },
                                                        child: Text('Reset Password',
                                                            style: TextStyle(
                                                                color: Colors.white
                                                            )),
                                                      ),
                                                    ),

                                                    Container(
                                                        width: MediaQuery.of(context).size.width,
                                                        child:ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: app_color,
                                                              elevation: 5, // Adjust the elevation to make it look elevated
                                                              shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                                            ),
                                                            onPressed: () {

                                                              setState(() {
                                                                usernameController.text = resetemailController.text;
                                                                resetemailController.clear();
                                                                isVisibleResetPassForm = false;
                                                                isVisibleLoginForm = true;
                                                              });
                                                            },
                                                            child: Text('Cancel',
                                                                style: TextStyle(
                                                                    color: Colors.white
                                                                ))))]))))),
                                  Visibility(
                                      visible: isVisibleOTPForm,
                                      child:Expanded(child:Container(

                                          padding: EdgeInsets.only(left: 32,right: 32,top: 30),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  spreadRadius: 0, // Spread radius
                                                  blurRadius: 20, // Blur radius
                                                  offset: Offset(0, -10),
                                                  // Shadow position
                                                ),
                                              ],
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(50),
                                                  topRight: Radius.circular(50)
                                              )
                                          ),
                                          child: Form(
                                              key: _otpformKey,
                                              child: ListView(
                                                children:[

                                                  Icon(Icons.mark_email_read_outlined, size: 100,
                                                  color: app_color), // Mobile phone icon
                                                  SizedBox(height: 20),
                                                  Text(
                                                    'Enter Verification Code',
                                                    style: TextStyle(fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  SizedBox(height: 5.0),
                                                  Center(child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: "We've sent you an OTP on ",
                                                    style: TextStyle(color: Colors.black54),

                                                  ),
                                                  TextSpan(
                                                    text: maskedEmail, // The masked email value
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), // Bold style
                                                  ),
                                                ],
                                              ),
                                            ),),

                                                  Text(
                                                      ". Please enter that code below to continue."
                                                    ,style: TextStyle(color: Colors.black54),
                                                    textAlign: TextAlign.center// Regular text style
                                                  ),

                                                  Padding(
                                                    padding: EdgeInsets.only(left: 5,right: 5,top: 16),
                                                    child: PinCodeTextField(
                                                      appContext: context,
                                                      pastedTextStyle: TextStyle(
                                                        color: Colors.green.shade600,
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                      length: 4, // Specify the length of OTP
                                                      onChanged: (value) {
                                                        currentText = value;
                                                      },
                                                      pinTheme: PinTheme(
                                                          shape: PinCodeFieldShape.box,
                                                          borderRadius: BorderRadius.circular(15),
                                                          fieldHeight: 50,
                                                          fieldWidth: 50,
                                                          activeFillColor: app_color,
                                                          inactiveFillColor: Colors.white,
                                                          activeColor: app_color,
                                                          inactiveColor: Colors.grey,
                                                          borderWidth: 1,
                                                          selectedColor: app_color
                                                      ),
                                                      controller: otpController,
                                                      keyboardType: TextInputType.number,
                                                      onCompleted: (value) {
                                                        // OTP entry is complete
                                                      },
                                                      obscureText: true,
                                                    ),
                                                  ),
                                                  SizedBox(height: 20),

                                                  Visibility(visible: isVisibleTimer,
                                                  child: Column(children: [
                                                    Text(
                                                      "Resend OTP in: $_formattedTime", // Display remaining time
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 16, color: Colors.black54),
                                                    ),
                                                    SizedBox(height: 20),


                                                  ],),),

                                                  Visibility(visible: _isButtonEnabled,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: app_color, // Change button color based on enabled state
                                                    ),
                                                    onPressed: () {
                                                      sendOTP(usernamee);
                                                      setState(() {
                                                        _isButtonEnabled = false;
                                                        isVisibleTimer = true;
                                                        _startTimer();
                                                      });

                                                    }, // Disable button if not enabled
                                                    child: Text(
                                                      'Resend OTP',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ),),

                                                  SizedBox(height: 10),

                                                  ElevatedButton(

                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _buttonColor,
                                                    ),
                                                    onPressed: () {

                                                      if (currentText.length == 4) {
                                                        final generatedOTP = generatedotp;
                                                        final enteredOTP = currentText;

                                                        if (enteredOTP == generatedOTP) {

                                                          socket.emit('deleteMyId', socket_data);

                                                          isOTPVerified = true;
                                                          isAnotherDevice = true;

                                                          _directlogin();
                                                        }
                                                        else {
                                                          isOTPVerified = false;
                                                          isAnotherDevice = false;
                                                          Fluttertoast.showToast(msg: 'Incorrect OTP');
                                                        }
                                                      }
                                                      else
                                                      {
                                                        isOTPVerified = false;
                                                        isAnotherDevice = false;
                                                        Fluttertoast.showToast(msg: 'Please enter a 4-digit OTP');
                                                      }
                                                    },
                                                    child: Text('Verify',
                                                        style: TextStyle(
                                                            color: Colors.white
                                                        )),
                                                  )
                                                ]
                                                  ))))),
                                ])),
                      )));})
    ), onWillPop: () async
    {
      _showConfirmationDialogAndExit(context);
      return true;
    });
  }
}