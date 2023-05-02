import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studentapp/attendence_page.dart';
import 'package:studentapp/signUp.dart';
import 'helper_functions.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SignInFive extends StatefulWidget {
  const SignInFive({Key? key}) : super(key: key);

  @override
  State<SignInFive> createState() => _SignInFiveState();
}

class _SignInFiveState extends State<SignInFive> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  late DatabaseReference db;
  String errorMessage = '';

  Future signIn() async {
    var UID = await getDeviceUID();
    String enteredEmail = emailController.text.trim();
    String enteredStudentID = enteredEmail.substring(0, 7);
    String enteredEmailDomain = enteredEmail.substring(7);
    String enteredPassword = passController.text.trim();
    if (enteredEmailDomain != "@nu.edu.pk") {
      //displayToast("Please enter NU Email ID");
      setState(() {
        errorMessage = "Please enter NU Email ID";
      });
    }
    bool checkResult = checkUserInput(enteredStudentID);
    if (checkResult == false) {
      //displayToast("Invalid NU Email ID");
      setState(() {
        errorMessage = "Invalid NU Email ID";
      });
      return;
    }
    db = FirebaseDatabase.instance.ref().child("/UID/${enteredStudentID}");
    DatabaseEvent event = await db.once();
    var studentUID_Record = event.snapshot.value;
    if (studentUID_Record == null) {
      //displayToast("User Doesn't Exist");
      setState(() {
        errorMessage = "User Doesn't Exist";
      });
      return;
    }
    if (studentUID_Record != UID) {
      // displayToast(
      //     "You can only Login in a Single Device.\nPlease Contact the admin");
      setState(() {
        errorMessage =
            "You can only Login in a Single Device.\nPlease Contact the admin";
      });
      return;
    }
    //If user has logged in before then check for his device info
    // if (studentUID_Record == UID) {
    //if his device is the same one he used to login for the first time then allow login
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: enteredEmail, password: enteredPassword);
      Navigator.push(context,
          MaterialPageRoute(builder: (BuildContext context) {
        return StudentScreen();
      }));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        setState(() {
          errorMessage = "Invalid Password";
        });
      }
      if (e.code == 'user-not-found') {
        setState(() {
          errorMessage = "User Doesn't Exist";
        });
      }
      if (e.code == 'too-many-requests') {
        setState(() {
          errorMessage = "Too many tries.\nPlease try again later";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Unknown Error Occured";
      });
    }
    // } else {
    //   //reject login if he is logging in with a different device.
    //   displayToast(
    //       "You can only Login in a Single Device.\nPlease Contact the admin");
    // }
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
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
                              'Sign in with your NU ID',
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
                            height: 15,
                          ),

                          //sign in button & continue with text here
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                signInButton(size),
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

  Widget logo(double height_, double width_) {
    return SvgPicture.asset(
      'assets/images/logo3.svg',
      height: height_,
      width: width_,
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
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
          TextSpan(
            text: 'LOGIN',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

  Widget passwordTextField(Size size) {
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
                controller: passController,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty || value.length < 7) {
                    return 'Password must be atleast 7 characters long';
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
                    border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Widget buildRemember(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          width: 17.0,
          height: 17.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            gradient: const LinearGradient(
              begin: Alignment(5.65, -1.0),
              end: Alignment(-1.0, 1.94),
              colors: [Color(0xFF00AD8F), Color(0xFF7BF4DF)],
            ),
          ),
          child: SvgPicture.string(
            // Vector 5
            '<svg viewBox="47.0 470.0 7.0 4.0" ><path transform="translate(47.0, 470.0)" d="M 0 1.5 L 2.692307710647583 4 L 7 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" /></svg>',
            width: 7.0,
            height: 4.0,
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Text(
          'Remember me',
          style: GoogleFonts.inter(
            fontSize: 14.0,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }*/

  Widget signInButton(Size size) {
    return ElevatedButton(
      onPressed: signIn,
      style: ElevatedButton.styleFrom(
          alignment: Alignment.center,
          elevation: size.height / 5,
          backgroundColor: Colors.blue.shade600,
          minimumSize: const Size(400, 50)),
      child: Text(
        'Sign in',
        style: GoogleFonts.inter(
          fontSize: 16.0,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget signUpButton(Size size) {
  //   return ElevatedButton(
  //     onPressed: () {
  //       Navigator.push(context,
  //           MaterialPageRoute(builder: (BuildContext context) {
  //         return const SignUp();
  //       }));
  //     },
  //     style: ElevatedButton.styleFrom(
  //         alignment: Alignment.center,
  //         elevation: size.height / 5,
  //         backgroundColor: Colors.transparent,
  //         minimumSize: const Size(100, 40)),
  //     child: Text(
  //       'Sign up',
  //       style: GoogleFonts.inter(
  //         fontSize: 12.0,
  //         color: Colors.white,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

  // Widget buildContinueText() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     children: <Widget>[
  //       const Expanded(
  //           child: Divider(
  //         color: Colors.white,
  //       )),
  //       Expanded(
  //         child: Text(
  //           'Or Continue with',
  //           style: GoogleFonts.inter(
  //             fontSize: 12.0,
  //             color: Colors.white,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //       const Expanded(
  //           child: Divider(
  //         color: Colors.white,
  //       )),
  //     ],
  //   );
  // }

  // Widget signInGoogleFacebookButton(Size size) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     children: <Widget>[
  //       //sign in google button
  //       Container(
  //         alignment: Alignment.center,
  //         width: size.width / 2.8,
  //         height: size.height / 13,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(10.0),
  //           border: Border.all(
  //             width: 1.0,
  //             color: Colors.white,
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             //icon of google
  //             SvgPicture.string(
  //               '<svg viewBox="63.54 641.54 22.92 22.92" ><path transform="translate(63.54, 641.54)" d="M 22.6936149597168 9.214142799377441 L 21.77065277099609 9.214142799377441 L 21.77065277099609 9.166590690612793 L 11.45823860168457 9.166590690612793 L 11.45823860168457 13.74988651275635 L 17.93386268615723 13.74988651275635 C 16.98913192749023 16.41793632507324 14.45055770874023 18.33318138122559 11.45823860168457 18.33318138122559 C 7.661551475524902 18.33318138122559 4.583295345306396 15.25492572784424 4.583295345306396 11.45823860168457 C 4.583295345306396 7.661551475524902 7.661551475524902 4.583295345306396 11.45823860168457 4.583295345306396 C 13.21077632904053 4.583295345306396 14.80519008636475 5.244435787200928 16.01918983459473 6.324374675750732 L 19.26015281677246 3.083411931991577 C 17.21371269226074 1.176188230514526 14.47633838653564 0 11.45823860168457 0 C 5.130426406860352 0 0 5.130426406860352 0 11.45823860168457 C 0 17.78605079650879 5.130426406860352 22.91647720336914 11.45823860168457 22.91647720336914 C 17.78605079650879 22.91647720336914 22.91647720336914 17.78605079650879 22.91647720336914 11.45823860168457 C 22.91647720336914 10.68996334075928 22.83741569519043 9.940022468566895 22.6936149597168 9.214142799377441 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(64.86, 641.54)" d="M 0 6.125000953674316 L 3.764603137969971 8.885863304138184 C 4.78324031829834 6.363905429840088 7.250198841094971 4.583294868469238 10.13710117340088 4.583294868469238 C 11.88963890075684 4.583294868469238 13.48405265808105 5.244434833526611 14.69805240631104 6.324373722076416 L 17.93901443481445 3.083411693572998 C 15.89257335662842 1.176188111305237 13.15520095825195 0 10.13710117340088 0 C 5.735992908477783 0 1.919254422187805 2.484718799591064 0 6.125000953674316 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(64.8, 655.32)" d="M 10.20069408416748 9.135653495788574 C 13.16035556793213 9.135653495788574 15.8496036529541 8.003005981445312 17.88286781311035 6.161093711853027 L 14.33654403686523 3.160181760787964 C 13.14749050140381 4.064460277557373 11.69453620910645 4.553541660308838 10.20069408416748 4.55235767364502 C 7.220407009124756 4.55235767364502 4.689855575561523 2.6520094871521 3.736530303955078 0 L 0 2.878881216049194 C 1.896337866783142 6.589632034301758 5.747450828552246 9.135653495788574 10.20069408416748 9.135653495788574 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(75.0, 650.71)" d="M 11.23537635803223 0.04755179211497307 L 10.31241607666016 0.04755179211497307 L 10.31241607666016 0 L 0 0 L 0 4.583295345306396 L 6.475625038146973 4.583295345306396 C 6.023715496063232 5.853105068206787 5.209692478179932 6.962699413299561 4.134132385253906 7.774986743927002 L 4.135851383209229 7.773841857910156 L 7.682177066802979 10.77475357055664 C 7.431241512298584 11.00277233123779 11.45823955535889 8.020766258239746 11.45823955535889 2.291647672653198 C 11.45823955535889 1.523372769355774 11.37917804718018 0.773431122303009 11.23537635803223 0.04755179211497307 Z" fill="#ffffff" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
  //               width: 22.92,
  //               height: 22.92,
  //             ),
  //             const SizedBox(
  //               width: 16,
  //             ),
  //             //google txt
  //             Text(
  //               'Google',
  //               style: GoogleFonts.inter(
  //                 fontSize: 14.0,
  //                 color: Colors.white,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(
  //         width: 16,
  //       ),

  //       //sign in facebook button
  //       Container(
  //         alignment: Alignment.center,
  //         width: size.width / 2.8,
  //         height: size.height / 13,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(10.0),
  //           border: Border.all(
  //             width: 1.0,
  //             color: Colors.white,
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             //facebook icon
  //             SvgPicture.string(
  //               '<svg viewBox="0.3 0.27 22.44 22.44" ><defs><linearGradient id="gradient" x1="0.500031" y1="0.970054" x2="0.500031" y2="0.0"><stop offset="0.0" stop-color="#ffffffff"  /><stop offset="1.0" stop-color="#ffffffff"  /></linearGradient></defs><path transform="translate(0.3, 0.27)" d="M 9.369577407836914 22.32988739013672 C 4.039577960968018 21.3760986328125 0 16.77546882629395 0 11.22104930877686 C 0 5.049472332000732 5.049472808837891 0 11.22105026245117 0 C 17.39262962341309 0 22.44210624694824 5.049472332000732 22.44210624694824 11.22104930877686 C 22.44210624694824 16.77546882629395 18.40252304077148 21.3760986328125 13.07252502441406 22.32988739013672 L 12.45536518096924 21.8249397277832 L 9.986735343933105 21.8249397277832 L 9.369577407836914 22.32988739013672 Z" fill="url(#gradient)" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(6.93, 4.65)" d="M 8.976840972900391 9.986734390258789 L 9.481786727905273 6.844839572906494 L 6.508208274841309 6.844839572906494 L 6.508208274841309 4.656734466552734 C 6.508208274841309 3.759051322937012 6.844841003417969 3.085787773132324 8.191367149353027 3.085787773132324 L 9.650103569030762 3.085787773132324 L 9.650103569030762 0.2244201600551605 C 8.864629745483398 0.1122027561068535 7.966946125030518 0 7.181471347808838 0 C 4.600629806518555 0 2.805262804031372 1.570946097373962 2.805262804031372 4.376209735870361 L 2.805262804031372 6.844839572906494 L 0 6.844839572906494 L 0 9.986734390258789 L 2.805262804031372 9.986734390258789 L 2.805262804031372 17.8975715637207 C 3.422420024871826 18.00978851318359 4.039577484130859 18.06587600708008 4.656735897064209 18.06587600708008 C 5.273893356323242 18.06587600708008 5.89105224609375 18.009765625 6.508208274841309 17.8975715637207 L 6.508208274841309 9.986734390258789 L 8.976840972900391 9.986734390258789 Z" fill="#21899c" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
  //               width: 22.44,
  //               height: 22.44,
  //             ),
  //             const SizedBox(
  //               width: 16,
  //             ),

  //             //facebook txt
  //             Text(
  //               'Facebook',
  //               textAlign: TextAlign.center,
  //               style: GoogleFonts.inter(
  //                 fontSize: 14.0,
  //                 color: Colors.white,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

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
              text: 'Don\'t have account? ',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  const SignUp())),
                    },
              text: 'Sign up',
              style: GoogleFonts.inter(
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
