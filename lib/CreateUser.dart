import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Sidebar.dart';
import 'UserView.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';


class CreateUser extends StatefulWidget
{
  const CreateUser({Key? key}) : super(key: key);
  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUser> with TickerProviderStateMixin {
  bool isDashEnable = true,
      isRolesVisible = true,
      isUserEnable = true,
      isUserVisible = true,
      isRolesEnable = true,
      _isLoading = false,
      isVisibleNoUserFound = false,
      _isFocused_email = false,
      _isFocus_name = false;

  List<dynamic> myData_roles = [];

  dynamic _selectedrole = "";
  List<String> _selectedCompanies = [];
  List<String> myDataCompanies = [];


  String user_email_fetched = "";

  late final TextEditingController controller_email = TextEditingController();
  late final TextEditingController controller_password = TextEditingController();
  late final TextEditingController controller_name = TextEditingController();

  bool _isFocused_password = false;
  bool _obscureText = true;

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
      fetchRoles(serial_no!);
      fetchCompany(serial_no!);
    });
  }

  void sendUserCredentialsEmailSMTP({
    required String email,
    required String name,
    required String password,
  }) async {
    final smtpServer = SmtpServer(
      'smtp.zoho.com',
      username: 'contact@tallyuae.ae',
      password: '355dD@3988',
      port: 587,
    );

    final message = Message()
      ..from = Address('contact@tallyuae.ae', 'Fincore Support')
      ..recipients.add(email)
      ..subject = 'Your Login Credentials for Fincore Mobile'
      ..html = '''
    <div style="border: 1px solid #ccc; padding: 30px; margin: 20px; text-align: center;">
      <a href="https://tallyuae.ae/">
        <img src="https://mobile.chaturvedigroup.com/fincore_logo/tally_1.png" alt="Logo" style="width: 150px; height: auto; margin-bottom: 10px;">
      </a>
      <div style="text-align: center;">
        <p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">
          Hi <strong>$name</strong>,<br><br>
          Welcome to Fincore Mobile! Your account has been successfully created. Below are your login credentials:
        </p>
      </div>

      <br>

      <div style="text-align: center;">
      
        <p style="background-color: #f5f5f5; color: #333; font-size: 14px; font-family: Arial, sans-serif; padding: 10px 20px; border-radius: 5px; text-align: left;">
          <strong>Email:</strong> $email<br>
          <strong>Password:</strong> $password
        </p>
      </div>

      <br>

      <div style="text-align: start;">
        <p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">
          You can change your password anytime from the "Reset Password" option in the app.
        </p>
      </div>

      <br>

      <div style="text-align: start;">
        <p style="font-size: 12px; font-family: Arial, sans-serif; color: #333;">
          If you did not request this account, please contact <a href="mailto:saadan@ca-eim.com">saadan@ca-eim.com</a>.
        </p>
      </div>

      <br>

      <div style="text-align: start;">
        <p style="color: #999999; font-style: italic; font-size: 12px">
          Disclaimer: This email is for credential delivery only. Please do not share your password with anyone.<br><br>
          This is a system-generated email. Do not reply.
        </p>
      </div>

      <div style="text-align: start; border-top: 1px solid #ccc; padding-top: 10px;">
        <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2;">
          © 2023-2025 Chaturvedi Software House LLC. All Rights Reserved
        </p>
        <p style="font-size: 10px; font-family: Arial, sans-serif; color: #a3a2a2;">
          513 Al Khaleej Center Bur Dubai, Dubai United Arab Emirates, +97143258361
        </p>
      </div>
    </div>
  ''';

    try {
      await send(message, smtpServer); // ✅ DO NOT assign it to a variable
      print('Credential email sent to $email');
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    }
  }


  Future<void> userRegistration(String selectedserial,String email,String password,String rolename, String name) async {
    setState(() {
      _isLoading = true;
    });

    try
    {
      final url = Uri.parse('$BASE_URL_config/api/login/userRegistration');


      Map<String,String> headers = {
        'Authorization' : 'Bearer $authTokenBase',
        "Content-Type": "application/json"
      };

      var body = jsonEncode( {
        "username": email ,
        "serialno" :selectedserial,
        "password": password,
        "rolename": rolename,
        "name": name,
      });

      final response = await http.post(
          url,
          body: body,
          headers:headers
      );

      if (response.statusCode == 200)
      {
        String responsee = response.body;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responsee),
          ),
        );
        if(responsee == "User Registered Successfully")
        {
          addAllowedCompanies(email, serial_no!, _selectedCompanies);

          controller_email.clear();
          controller_name.clear();
          controller_password.clear();
          _selectedrole =   myData_roles[0];
          FocusScope.of(context).unfocus();

           sendUserCredentialsEmailSMTP(
            email: email,
            name: name,
            password: password,
          );

        }
        else if (responsee == "No of users exceeded")
        {
          controller_email.clear();
          controller_name.clear();
          controller_password.clear();
          _selectedrole =   myData_roles.first;
          FocusScope.of(context).unfocus();

        }
        else
          {
            controller_email.clear();
            controller_name.clear();
            controller_password.clear();
            _selectedrole =   myData_roles[0];
            FocusScope.of(context).unfocus();
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
    catch (e)
    {print(e);
    setState(() {
      _isLoading = false;
    });}

  }

  Future<void> fetchRoles(String selectedserial) async {
    setState(() {
      _isLoading = true;
    });

    try
    {
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
        myData_roles = jsonDecode(response.body);
        if (myData_roles != null) {
          setState(() {
            _selectedrole = myData_roles.first;
          });



        }
        else
        {
          throw Exception('Failed to fetch data');
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
    catch (e)
    {print(e);
    setState(() {
      _isLoading = false;
    });}
  }

  Future<void> fetchCompany(String selectedserial) async {
    myDataCompanies.clear();
    final url = Uri.parse('$BASE_URL_config/api/admin/getCompany');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      'serialno': selectedserial
    });

    final response = await http.post(
        url,
        body : body,
        headers : headers
    );

    if (response.statusCode == 200)
    {
      final List<dynamic> responseData = jsonDecode(response.body);
      if (responseData != null) {
        setState(() {
          myDataCompanies = responseData.map<String>((item) {
            return item['company_name'] as String;
          }).toList();
        });
      }
      else
      {

        throw Exception('Failed to fetch data');
      }
      setState(() {
        _isLoading = false;
      });
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

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> addAllowedCompanies(String email, String serialno, List<String> companies_list) async {
    myDataCompanies.clear();
    final url = Uri.parse('$BASE_URL_config/api/roles/allowed_companies');

    Map<String,String> headers = {
      'Authorization' : 'Bearer $authTokenBase',
      "Content-Type": "application/json"
    };

    print('$serialno, $email, $companies_list');

    var body = jsonEncode({
      'serial_no': serialno,
      'user_name' : email,
      'companies' : companies_list
    });

    final response = await http.post(
        url,
        body : body,
        headers : headers
    );

    if (response.statusCode == 200)
    {
      print(response.body);
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

      setState(() {
        _isLoading = false;
      });
    }
  }


  void _openMultiSelectDialog() async {
    List<String> tempSelectedCompanies = List.from(_selectedCompanies);

    final selectedValues = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Companies',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                onPressed: () => Navigator.pop(context),
                splashRadius: 20,
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              bool isAllSelected = tempSelectedCompanies.length == myDataCompanies.length;

              return SizedBox(
                width: double.maxFinite,
                height: 170,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    children: [
                      // Select All
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Select All', style: GoogleFonts.poppins(fontSize: 14)),
                        value: isAllSelected,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              tempSelectedCompanies = List.from(myDataCompanies);
                            } else {
                              tempSelectedCompanies.clear();
                            }
                          });
                        },
                        activeColor: Colors.teal,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      Divider(),

                      // Individual Company Checkboxes
                      ...myDataCompanies.map((company) {
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(company, style: GoogleFonts.poppins(fontSize: 14)),
                          value: tempSelectedCompanies.contains(company),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                tempSelectedCompanies.add(company);
                              } else {
                                tempSelectedCompanies.remove(company);
                              }
                            });
                          },
                          activeColor: Colors.teal,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[800])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, tempSelectedCompanies),
              child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            ),
          ],
        );
      },
    );

    // Save selected companies if confirmed
    if (selectedValues != null) {
      setState(() {
        _selectedCompanies = selectedValues;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _initSharedPreferences();
  }


  bool isValidEmail(String email) {
    // Simple email validation pattern
    final RegExp emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*(\.[a-zA-Z]{2,})$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserView()),
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
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserView()));
              },
            ),
            title: GestureDetector(
              onTap: () {

              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      "User Registration",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              tickerProvider: this),
        body: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator.adaptive()),

            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight-50),
                    child: IntrinsicHeight(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.08),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: app_color.withOpacity(0.1),
                                radius: 22,
                                child: Icon(Icons.person, size: 24, color: app_color),
                              ),
                              title: Text(
                                'Create New User',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Please provide the details of the user you want to add.',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _modernTextField(
                              label: 'Full Name',
                              controller: controller_name,
                              icon: Icons.person_outline,
                              isFocused: _isFocus_name,
                              onFocus: () => _updateFocus(name: true),
                            ),
                            const SizedBox(height: 20),
                            _modernTextField(
                              label: 'Email Address',
                              controller: controller_email,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isFocused: _isFocused_email,
                              onFocus: () => _updateFocus(email: true),
                            ),
                            const SizedBox(height: 20),
                            Text("Select Role", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<dynamic>(
                              value: _selectedrole,
                              dropdownColor: Colors.white, // 👈 Set dropdown menu background to white
                              borderRadius: BorderRadius.circular(14), // 👈 Rounded corners for menu

                              isExpanded: true,
                              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),


                              decoration: _modernDropdownDecoration(),
                              items: myData_roles.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(item['role_name'],
                                      style: GoogleFonts.poppins( // 👈 Apply Poppins style to menu items
                                        fontSize: 15,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      )
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedrole = value),
                              onTap: () => _updateFocus(),
                              hint: Text('Choose a role', style: GoogleFonts.poppins()),
                            ),
                            const SizedBox(height: 20),
                            Text("Allowed Companies", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _openMultiSelectDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Text(
                                  _selectedCompanies.isNotEmpty
                                      ? _selectedCompanies.join('\n')
                                      : 'Tap to select companies',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            ),
                            SizedBox(height: 70),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: app_color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              icon: Icon(Icons.save_alt),
                              label: Text(
                                'REGISTER',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              onPressed: _submitForm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ),

      ),
    );
    // TODO: implement build
  }
  InputDecoration _modernDropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: app_color),
      borderRadius: BorderRadius.circular(10),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  String _generateRandomPassword({int length = 5}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Widget _modernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onFocus,
    bool isPassword = false,
    bool obscureText = false,
    bool isFocused = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onFocus,
      onChanged: (_) => onFocus(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isFocused ? app_color : Colors.black87,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: isFocused ? app_color : Colors.black),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: isFocused ? app_color : Colors.black,
          ),
          onPressed: toggleObscure,
        )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: app_color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _updateFocus({bool name = false, bool email = false, bool password = false}) {
    setState(() {
      _isFocus_name = name;
      _isFocused_email = email;
      _isFocused_password = password;
    });
  }

  void _submitForm() {
    final name = controller_name.text;
    final email = controller_email.text;
    final password = controller_password.text;
    final role = _selectedrole?["role_name"];

    if (name.isEmpty || email.isEmpty || role == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields.")));
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter a valid email address")));
      return;
    }



    _updateFocus();
    final generatedPassword = _generateRandomPassword(); // generates 5-char password
    userRegistration(serial_no!, email, generatedPassword, role, name);
  }



}