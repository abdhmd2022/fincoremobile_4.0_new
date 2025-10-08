import 'dart:convert';
import 'package:fincoremobile/Dashboard.dart';
import 'package:fincoremobile/ModifyUser.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CreateUser.dart';
import 'SerialSelect.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;

class UserModel {
  final String role_name;
  final String name;
  final String email;

  UserModel({
    required this.role_name,
    required this.name,
    required this.email
  });

  factory UserModel.fromJson(Map<String, dynamic> json)
  {
    return UserModel
    (
        role_name: json['role_name'],
        name: json['customer_name'],
        email: json['user_name']
    );
  }
}

class UserView extends StatefulWidget {
  const UserView({Key? key}) : super(key: key);
  @override
  _UserViewPageState createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserView> with TickerProviderStateMixin {
  bool isDashEnable = true,
       isRolesVisible = true,
       isUserEnable = false,
       isUserVisible = true,
       isRolesEnable = true,
       _isLoading = false,
       isVisibleNoUserFound = false;

  String user_email_fetched = "";

  final List<UserModel> users = [];

  String name = "",email = "";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  late SharedPreferences prefs;

  String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    setState(()
    {
      hostname = prefs.getString('hostname');
      company  = prefs.getString('company_name');
      company_lowercase = company!.replaceAll(' ', '').toLowerCase();
      serial_no = prefs.getString('serial_no');
      username = prefs.getString('username');

      SecuritybtnAcessHolder = prefs.getString('secbtnaccess');

      String? email_nav = prefs.getString('email_nav');
      String? name_nav = prefs.getString('name_nav');

      if (email_nav!=null && name_nav!= null)
      {
        name = name_nav;
        email = email_nav;
      }
      if(SecuritybtnAcessHolder == "True")
      {
        isRolesVisible = true;
        isUserVisible = true;
      }
      else
      {
        isRolesVisible = false;
        isUserVisible = false;
      }
    });
    fetchUsers(serial_no!);
  }

  Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button to close dialog
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: AnimationController(
              duration: const Duration(milliseconds: 500),
              vsync: this,
            )..forward(),
            curve: Curves.fastOutSlowIn,
          ),
          child: AlertDialog(
            title: Text('Removal Confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Do you really want to Delete User'),
                ],
              ),
            ),
            actions: <Widget>[

              TextButton(
                child: Text(
                  'No',
                  style: GoogleFonts.poppins(
                    color: Colors.grey, // Change the text color here
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

              TextButton(
                child: Text(
                  'Yes',
                  style: GoogleFonts.poppins(
                    color: app_color, // Change the text color here
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  userdelete(serial_no!,user_email_fetched);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> userdelete(String selectedserial,String email) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/login/deleteUser');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial,
      'username' : email
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      final responsee = response.body;
      if (responsee != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
          setState(()
          {
            _isLoading = true;
            fetchUsers(serial_no!);
          }
          );
      }
      else
      {
        throw Exception('Failed to fetch data');
      }
    }
    else
    {
      Map<String, dynamic> data = json.decode(response.body);
      String error = '';

      if (data.containsKey('error')) {
        setState(() {
          error = data['error'];
        });
      }
      else {
        error = "Something went wrong!!!";
      }
      Fluttertoast.showToast(msg: error);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchUsers(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/login/getRole');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial,
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      users.clear();
      try
      {
        final List<dynamic> jsonList = json.decode(response.body);

        if (jsonList != null)
        {
          isVisibleNoUserFound = false;

          users.addAll(jsonList.map((json) => UserModel.fromJson(json)).toList());
          users.sort(compareDataObjects);
        }
        else
        {
          throw Exception('Error in data fetching');
        }
        setState(()
        {
          if(users.isEmpty)
          {
            isVisibleNoUserFound = true;
          }
          _isLoading = false;
        });
      }
      catch (e)
      {
        print(e);
      }
    }

    setState(()
    {
      if(users.isEmpty)
      {
        isVisibleNoUserFound = true;
      }
      _isLoading = false;
    });
  }

  @override
  void initState()
  {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  Future<void> _refresh() async
  {
    setState(() {
      fetchUsers(serial_no!);
    });
  }

  int compareDataObjects(UserModel a, UserModel b) {
    return a.name.compareTo(b.name);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
        return true;
      },
      child:Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: AppBar(
            backgroundColor:  app_color,
            elevation: 6,
            automaticallyImplyLeading: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SerialSelect()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      company ?? '',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
            centerTitle: true,
          ),
        ),

        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Stack(
            children: [
              if (isVisibleNoUserFound)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No User Found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: users.length,

                itemBuilder: (context, index) {
                  final card = users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /// Left Column (Avatar + Info)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Name
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: app_color.withOpacity(0.2),
                                      child: Icon(Icons.person, color: app_color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        card.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                /// Email
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        card.email,
                                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                /// Role
                                Row(
                                  children: [
                                    Icon(Icons.security_outlined, size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        card.role_name,
                                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          /// Right Column (Edit/Delete)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ModifyUser(
                                          email_address: card.email,
                                          user_name: card.name,
                                          rolename: card.role_name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Tooltip(
                                    message: 'Edit User',
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      radius: 16,
                                      child: Icon(Icons.edit, size: 18, color: Colors.blue),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                GestureDetector(
                                  onTap: () {
                                    user_email_fetched = card.email;
                                    _showConfirmationDialogAndNavigate(context);
                                  },
                                  child: Tooltip(
                                    message: 'Delete User',
                                    child: CircleAvatar(
                                      backgroundColor: Colors.red.shade50,
                                      radius: 16,
                                      child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),

              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  backgroundColor: app_color,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => CreateUser()),
                    );
                  },
                  child: Icon(Icons.person_add_alt_1_rounded, size: 26, color: Colors.white),
                ),
              ),
            ],
          ),
        ),




      ));}




}