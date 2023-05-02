import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studentapp/login.dart';
import 'helper_functions.dart';
//import 'package:studentapp/signUp.dart';

import 'helper_functions.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmpassctrl = TextEditingController();
  late DatabaseReference db;
  String errorMessage = '';

  Future<bool> validateUser() async {
    String enteredEmail = emailController.text.trim();
    String enteredStudentID = enteredEmail.substring(0, 7);
    String enteredEmailDomain = enteredEmail.substring(7);
    String enteredPassword = passController.text.trim();
    String enteredConfirmPassword = confirmpassctrl.text.trim();
    if (enteredEmailDomain != "@nu.edu.pk") {
      setState(() {
        errorMessage = "Please enter NU Email ID";
      });
      return false;
    }
    bool checkResult = checkUserInput(enteredStudentID);
    if (checkResult == false) {
      setState(() {
        errorMessage = "Invalid NU Email ID";
      });
      return false;
    }
    db = FirebaseDatabase.instance.ref().child("/UID/$enteredStudentID");
    DatabaseEvent event = await db.once();
    var studentID_Record = event.snapshot.value;
    if (studentID_Record != null) {
      setState(() {
        errorMessage = "This Student ID already exists.\nPlease Login instead";
      });
      return false;
    }
    if (enteredPassword != enteredConfirmPassword) {
      setState(() {
        errorMessage = "Password Mismatch";
      });
      return false;
    } else if (enteredPassword.length < 6) {
      setState(() {
        errorMessage = "Password length should be minimum 6";
      });
      return false;
    }
    return true;
  }

  Future<void> storeInfoToFirebase() async {
    var UID = await getDeviceUID();
    String enteredEmail = emailController.text.trim();
    String enteredStudentID = enteredEmail.substring(0, 7);
    String enteredPassword = passController.text.trim();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: enteredEmail, password: enteredPassword);
      db = FirebaseDatabase.instance.ref().child("/UID/$enteredStudentID");
      await db.set(UID);
      Navigator.of(context).pop();
      displayToast("Account Created Succesfully");
      await Future.delayed(Duration(seconds: 2));
      Navigator.push(context,
          MaterialPageRoute(builder: (BuildContext context) {
        Navigator.of(context).pop();
        return const SignInFive();
      }));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          errorMessage =
              "This Student ID already exists.\nPlease Login instead";
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          errorMessage = "Please use a stronger Password";
        });
      } else {
        setState(() {
          errorMessage = "Unknown Error Occurred.\nPlease try again later";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Unknown Error Occurred.\nPlease try again later";
      });
    }
  }

  Future<XFile?> captureImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    return capturedImage;
  }


  Future<bool> storePictureToDB(String studentID, XFile? photo) async {
    final face = await detectFace(photo!.path);

    if (face.length == 0) {
      displayToast("Face Not Detected. Please Re-capture your photo");
      displayToast("Sign Up Failed. Please Try Again");
      Navigator.of(context).pop();
      return false;
    }
    if (face.length > 1) {
      displayToast("Multiple Faces Detected. Please Re-capture your photo");
      displayToast("Sign Up Failed. Please Try Again");
      Navigator.of(context).pop();
      return false;
    }
    var fileImage = File(photo.path);
    try {
      final storageReference =
          FirebaseStorage.instance.ref().child('images/$studentID');
      final uploadTask = storageReference.putFile(fileImage);
      await uploadTask;

      // Get the download URL of the image from Firebase Storage
      final downloadUrl = await storageReference.getDownloadURL();

      // Store the download URL in Firebase Realtime Database
      final dbRef =
          FirebaseDatabase.instance.ref().child('/faceAuth/$studentID');
      await dbRef.set(downloadUrl);

      return true;
    } catch (e) {
      displayToast("Unknown Error Occured while saving your image");
      displayToast("Sign Up Failed. Please Try Again");
      Navigator.of(context).pop();
      return false;
    }
    // displayToast('Picture stored to database');
  }

  Future<void> signUp() async {
    var validationStatus = await validateUser();
    if(validationStatus){
      var image = await captureImage();
      if(image != null){
        ProgressIndicator(context, 'Creating Account...  Please Wait.');
        String enteredEmail = emailController.text.trim();
        String enteredStudentID = enteredEmail.substring(0, 7);
        var pictureStatus = await storePictureToDB(enteredStudentID, image);
        if(pictureStatus){
          await storeInfoToFirebase();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    requestPermissions();
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: -34,
                  top: 181.0,
                  child: SvgPicture.string(
                    // Group 3178
                    '<svg viewBox="-34.0 181.0 99.0 99.0" ><path transform="translate(-34.0, 181.0)" d="M 74.25 0 L 99 49.5 L 74.25 99 L 24.74999618530273 99 L 0 49.49999618530273 L 24.7500057220459 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-26.57, 206.25)" d="M 0 0 L 42.07500076293945 16.82999992370605 L 84.15000152587891 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(15.5, 223.07)" d="M 0 56.42999649047852 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                    width: 99.0,
                    height: 99.0,
                    color: Colors.blue.shade600,
                  ),
                ),

                //right side background design. I use a svg image here
                Positioned(
                  right: -52,
                  top: 45.0,
                  child: SvgPicture.string(
                    // Group 3177
                    '<svg viewBox="288.0 45.0 139.0 139.0" ><path transform="translate(288.0, 45.0)" d="M 104.25 0 L 139 69.5 L 104.25 139 L 34.74999618530273 139 L 0 69.5 L 34.75000762939453 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(298.42, 80.45)" d="M 0 0 L 59.07500076293945 23.63000106811523 L 118.1500015258789 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(357.5, 104.07)" d="M 0 79.22999572753906 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                    width: 139.0,
                    height: 139.0,
                    color: Colors.blue.shade600,
                  ),
                ),

                //content ui
                Positioned(
                  top: 8.0,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.06),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //logo section
                          SizedBox(
                            child: Column(
                              children: [
                                logo(size.height / 8, size.height / 8),
                                const SizedBox(
                                  height: 16,
                                ),
                                richText(23.12),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 35,
                          ),

                          //continue with email for sign in app text
                          SizedBox(
                            child: Text(
                              'Sign Up with your NU ID',
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 35,
                          ),

                          //email and password TextField here
                          SizedBox(
                            child: Column(
                              children: [
                                emailTextField(size),
                                const SizedBox(
                                  height: 8,
                                ),
                                passwordTextField(size),
                                const SizedBox(
                                  height: 8,
                                ),
                                confirmpasswordTextField(size),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 25,
                          ),

                          //sign in button & continue with text here
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                signUpButton(size),
                                const SizedBox(
                                  height: 20,
                                ),
                                buildFooter(size),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget passwordTextField(Size size) {
    bool obscurePassword = true;
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.grey.shade600,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //lock logo here
            const Icon(
              Icons.lock,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //password textField
            Expanded(
              // Define a bool variable to toggle password visibility
              child: TextFormField(
                maxLines: 1,
                controller: passController,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.visiblePassword,
                obscureText: obscurePassword,
                validator: (value) {
                  if (value!.isEmpty || value.length < 7) {
                    return 'Password must be at least 7 characters long';
                  }
                  return null;
                },
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.0,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      // Toggle password visibility here
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    child: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

            ),
          ],
        ),
      ),
    );
  }

  Widget confirmpasswordTextField(Size size) {
    bool obscureConfirmPassword = true;
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.grey.shade600,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //lock logo here
            const Icon(
              Icons.lock,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //password textField
            Expanded(
              child: TextFormField(
                maxLines: 1,
                controller: confirmpassctrl,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.visiblePassword,
                obscureText: obscureConfirmPassword,
                validator: (value) {
                  if (value!.isEmpty || value.length < 7) {
                    return 'Password must be at least 7 characters long';
                  }
                  return null;
                },
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Confirm your password',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.0,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      // Toggle password visibility here
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                    child: Icon(
                      obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emailTextField(Size size) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.grey.shade600,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //mail icon
            const Icon(
              Icons.mail_rounded,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),

            //divider svg
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),

            //email address textField
            Expanded(
              child: TextFormField(
                maxLines: 1,
                controller: emailController,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Email field must not be empty';
                  }
                  return null;
                },
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                    hintText: 'Enter your Email address',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget richText(double fontSize) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.inter(
          fontSize: 23.12,
          color: Colors.white,
          letterSpacing: 1.999999953855673,
        ),
        children: [
          TextSpan(
            text: 'STUDENT ',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Colors.grey.shade600),
          ),
          TextSpan(
            text: 'SIGN UP',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget logo(double height_, double width_) {
    return SvgPicture.asset(
      'assets/images/logo3.svg',
      height: height_,
      width: width_,
    );
  }

  Widget signUpButton(Size size) {
    return ElevatedButton(
      onPressed: () async {
        await signUp();
      },
      style: ElevatedButton.styleFrom(
          alignment: Alignment.center,
          elevation: size.height / 5,
          backgroundColor: Colors.blue.shade600,
          minimumSize: const Size(400, 50)),
      child: Text(
        'Sign Up',
        style: GoogleFonts.inter(
          fontSize: 16.0,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void ProgressIndicator(BuildContext context, String displayText) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
              title: Text(displayText),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 16.0,
                    width: 20,
                  ),
                ],
              ));
        });
      },
    );
  }

  Widget buildFooter(Size size) {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.nunito(
            fontSize: 16.0,
            color: Colors.white,
          ),
          children: [
            TextSpan(
              text: 'Already have account? ',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  const SignInFive())),
                    },
              text: 'Sign In',
              style: GoogleFonts.nunito(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
