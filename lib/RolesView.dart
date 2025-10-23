import 'dart:convert';
import 'package:FincoreGo/AddRole.dart';
import 'package:FincoreGo/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ModifyRole.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SerialSelect.dart';
import 'Sidebar.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;

class RoleModel {
  final String role_name;

  RoleModel({
    required this.role_name
  });
  factory RoleModel.fromJson(Map<String, dynamic> json)
  {
    return RoleModel
    (
      role_name: json['role_name']
    );
  }
}

class RolesView extends StatefulWidget {
  const RolesView({Key? key}) : super(key: key);
  @override
  _RolesViewPageState createState() => _RolesViewPageState();
}

class _RolesViewPageState extends State<RolesView> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = false,
      _isLoading = false,
      isVisibleNoRoleFound = false;

      String rolename_fetched = "";

      final List<RoleModel> roles = [];

      String name = "",email = "";

      final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

      late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

      late SharedPreferences prefs;

      String? hostname = "", company = "",company_lowercase = "",serial_no= "",username= "",HttpURL= "",SecuritybtnAcessHolder= "";

      Future<void> _initSharedPreferences() async {
        prefs = await SharedPreferences.getInstance();
        setState(() {
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
        fetchRoles(serial_no!);
      }

  Future<void> _showConfirmationDialogAndNavigate(BuildContext context) async {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Delete Role Confirmation",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: controller..forward(), curve: Curves.easeOutBack),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔴 Warning Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 42,
                      color: Colors.redAccent,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 🧾 Title
                  Text(
                    'Delete Role Confirmation',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // 💬 Description
                  Text(
                    'Are you sure you want to permanently delete this role?\n'
                        'This action cannot be undone.',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 26),

                  // 🔘 Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: app_color, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: app_color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Delete
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            roledelete(serial_no!, rolename_fetched);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> roledelete(String selectedserial,String rolename) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/roles/delete');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'serialno': selectedserial,
      'rolename' : rolename
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );


    if (response.statusCode == 200)
    {
      final responsee = response.body;
      if (responsee != null)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
        if (responsee == "Unable to Delete! User Exists Against This Role.")
        {
          setState(() {
            _isLoading = false;
          });
        }
        else
        {
          setState(() {
            _isLoading = true;
            fetchRoles(serial_no!);
          });
        }
      } else
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
      else
      {
        error = 'Something went wrong!!!';
      }
      Fluttertoast.showToast(msg: error);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchRoles(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.parse('$BASE_URL_config/api/roles/get');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode( {
      'serialno': selectedserial,
    });

    final response = await http.post(
        url,
        body: body,
        headers:headers
    );

    if (response.statusCode == 200)
    {
      roles.clear();

      try
      {
        final List<dynamic> jsonList = json.decode(response.body);

        if (jsonList != null)
        {
          isVisibleNoRoleFound = false;
          roles.addAll(jsonList.map((json) => RoleModel.fromJson(json)).toList());
        }
        else
        {
          throw Exception('Failed to fetch data');
        }
        setState(() {
          if(roles.isEmpty)
          {
            isVisibleNoRoleFound = true;
          }
          _isLoading = false;
        });

      }
      catch (e)
      {
        print(e);
      }
    }
        setState(() {
          if(roles.isEmpty)
          {
            isVisibleNoRoleFound = true;
          }
          _isLoading = false;
        });
  }

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }

  Future<void> _refresh() async
  {
    setState(()
    {
      fetchRoles(serial_no!);
    });
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
      child: Scaffold(
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

        drawer: Sidebar(
          isDashEnable: isDashEnable,
          isRolesVisible: isRolesVisible,
          isRolesEnable: isRolesEnable,
          isUserEnable: isUserEnable,
          isUserVisible: isUserVisible,
          Username: name,
          Email: email,
          tickerProvider: this,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Stack(
            children: [
              Visibility(
                visible: isVisibleNoRoleFound,
                child:  Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Text(
                      'No Roles Found',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final card = roles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: app_color.withOpacity(0.1),
                        child: Icon(Icons.group, color: app_color, size: 24),
                      ),
                      title: Text(
                        card.role_name,
                        style:  GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      trailing: Wrap(
                        spacing: 10,
                        children: [
                          GestureDetector(
                            onTap: () {
                              String rolename = card.role_name;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ModifyRole(role_name: rolename)),
                              );
                            },
                            child: Tooltip(
                              message: 'Edit Role',
                              child: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(Icons.edit, size: 18, color: Colors.blue),
                                radius: 16,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              rolename_fetched = card.role_name;
                              _showConfirmationDialogAndNavigate(context);
                            },
                            child: Tooltip(
                              message: 'Delete Role',
                              child: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                radius: 16,
                              ),
                            ),
                          ),
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
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: app_color,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AddRole()),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}