import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'attendanceModel.dart';
import 'face_verification.dart';
import 'login.dart';
import 'helper_functions.dart';
import 'package:get/get.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:studentapp/controller/requirement_state_controller.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'model/sections.dart';

const int scanDuration = 7;

class StudentScreen extends StatefulWidget {
  StudentScreen({Key? key}) : super(key: key);

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

// List<attendanceModel> attendance = [];
List<attendanceModel> attend = [];

class _StudentScreenState extends State<StudentScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  var cardTextColor = Colors.grey.shade900;
  var box = Hive.box('sectionBox');
  String classRoom = "";
  String courseName = "";
  String date = "";
  String section = "";
  String teacherName = "";
  String time = "";
  String id = "";
  // String _bleLocations = "/bleLocations";
  String _locationStatus = "Not Located";
  String _authenticationStatus = "Not Authenticated";
  late DatabaseReference db;
  late var allAttendance;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  final controller = Get.find<RequirementStateController>();

  StreamSubscription<BluetoothState>? _streamBluetooth;

  var beaconInfo = {};
  var bles;
  var bleLocations;
  var beaconList = [];
  var sendingData = {};
  final studentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  late var studentID;

  @override
  void initState() {
    studentID = studentEmail.substring(0, 7);
    displayAttendance();
    if (box.values != null) {
      box.values.forEach((stuSection) {
        _classList.add(stuSection);
      });
    }
    listeningState();
    super.initState();
  }

  listeningState() async {
    print('Listening to bluetooth state');
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      await checkAllRequirements();
    });
    StreamSubscription<geo.ServiceStatus> serviceStatusStream =
        geo.Geolocator.getServiceStatusStream()
            .listen((geo.ServiceStatus status) async {
      await checkAllRequirements();
    });
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.updateBluetoothState(bluetoothState);

    final authorizationStatus = await flutterBeacon.authorizationStatus;
    controller.updateAuthorizationStatus(authorizationStatus);

    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);
  }

  void readOnlineDB() async {
    db = FirebaseDatabase.instance.ref().child("/bleLocations");
    DatabaseEvent event = await db.once();
    bleLocations = event.snapshot.value;
    bleLocations.forEach((key, value) async {
      beaconList.add(key);
    });
    for (int j = 0; j < beaconList.length; j++) {
      List<int> empty = [];
      List<double> emp = [];
      beaconInfo[beaconList[j]] = {};
      beaconInfo[beaconList[j]]['rssi'] = empty;
      beaconInfo[beaconList[j]]['Est_Distance'] = emp;
      beaconInfo[beaconList[j]]['classroom'] = bleLocations[beaconList[j]];
    }
    var box = await Hive.box('bleBox');
    box.clear();
    bleLocations.forEach((key, value) async {
      beaconList.add(key);
      await box.put(key, value);
    });
  }

  void readOfflineDB() async {
    var box = Hive.box('bleBox');
    var data = box.values.toList();
    beaconList = box.keys.toList();
    for (int j = 0; j < beaconList.length; j++) {
      List<int> empty = [];
      List<double> emp = [];
      beaconInfo[beaconList[j]] = {};
      beaconInfo[beaconList[j]]['rssi'] = empty;
      beaconInfo[beaconList[j]]['Est_Distance'] = emp;
      beaconInfo[beaconList[j]]['classroom'] = box.get(beaconList[j]);
    }
  }

  Future<void> _refresh() async {
    await displayAttendance();
  }

  int checkScanRequirements() {
    if (!controller.bluetoothEnabled) {
      return 1;
    }
    if (!controller.locationServiceEnabled) {
      return 2;
    }
    if (!controller.authorizationStatusOk) {
      return 3;
    }
    return 0;
  }

  void scan() async {
    var permissionStatus = await requestPermissions();
    if (permissionStatus) {
      var result = checkScanRequirements();
      if (result == 0) {
        Directory directory =
            await pathProvider.getApplicationDocumentsDirectory();
        Hive.init(directory.path);
        await Hive.openBox("bleBox");
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.mobile ||
            connectivityResult == ConnectivityResult.wifi) {
          readOnlineDB();
        } else {
          readOfflineDB();
          if (beaconInfo.isEmpty) {
            displayToast("Please turn on Internet before scanning");
            Navigator.of(context).pop();
            return;
          }
        }
        bool blesFound = false;
        StreamSubscription<RangingResult>? _streamRanging;
        await flutterBeacon.initializeScanning;
        final regions = <Region>[
          Region(
            identifier: 'myBeacons',
            proximityUUID: 'fda50693a4e24fb1afcfc6eb07647825',
          ),
        ];
        _streamRanging =
            flutterBeacon.ranging(regions).listen((RangingResult result) {
          for (var element in result.beacons) {
            var major = element.major;
            var minor = element.minor;
            var uid = "${major}_$minor";
            if (beaconInfo.containsKey(uid)) {
              beaconInfo[uid]['rssi'].add(element.rssi);
              beaconInfo[uid]['Est_Distance'].add(element.accuracy);
            }
            blesFound = true;
          }
        });
        await Future.delayed(const Duration(seconds: scanDuration));
        _streamRanging.cancel();
        beaconInfo.forEach((key, value) {
          if (beaconInfo[key]['rssi'].isNotEmpty) {
            beaconInfo[key]['meanRSSI'] = mean(beaconInfo[key]['rssi']);
            if (beaconInfo[key]['Est_Distance'].isNotEmpty) {
              beaconInfo[key]['Mean_Est_Distance'] =
                  meanFLoat(beaconInfo[key]['Est_Distance']);
            }
          } else {
            beaconInfo[key]['meanRSSI'] = 0;
            beaconInfo[key]['Mean_Est_Distance'] = 0;
          }
        });
        if (blesFound) {
          try {
            await predictPosition();
            Navigator.of(context).pop();
            return;
          } on Exception catch (_, e) {
            displayToast("Please try again");
            Navigator.of(context).pop();
            return;
          }
        } else {
          displayToast("No Beacons found");
          Navigator.of(context).pop();
          return;
        }
      } else if (result == 1) {
        displayToast("Please enable Bluetooth");
        Navigator.of(context).pop();
        return;
      } else if (result == 2) {
        displayToast("Please enable Location");
        Navigator.of(context).pop();
        return;
      } else if (result == 3) {
        displayToast("Please allow required permissions to scan");
        Navigator.of(context).pop();
        return;
      }
    } else {
      Navigator.of(context).pop();
      return;
    }
  }

  Future<void> predictPosition() async {
    var bleDistance = 'Mean_Est_Distance';
    var min_distance = 1000.0;
    var bleWithMinDistance;
    beaconList.forEach((element) {
      if (beaconInfo[element][bleDistance] != 0.0) {
        if (min_distance > beaconInfo[element][bleDistance]) {
          min_distance = beaconInfo[element][bleDistance];
          bleWithMinDistance = element;
        }
      }
    });
    var max_Rssi = -10000;
    var bleWithMaxRssi;
    var bestAverage = 'meanRSSI';
    beaconList.forEach((element) {
      if (beaconInfo[element][bestAverage] != 0.0) {
        if (max_Rssi < beaconInfo[element][bestAverage]) {
          max_Rssi = beaconInfo[element][bestAverage];
          bleWithMaxRssi = element;
        }
      }
    });
    if (bleWithMaxRssi == bleWithMinDistance) {
      setState(() {
        _locationStatus = bleLocations[bleWithMaxRssi];
      });
      displayToast("Location Updated");
      Future.delayed(Duration(minutes: 3), () {
        setState(() {
          _locationStatus = "Not Located";
        });
      });
    } else {
      displayToast("Please Re-Scan");
      setState(() {
        _locationStatus = 'Not Located';
      });
    }
  }

  void addAttendance(String cr, String cn, String dt, String sec, String tn,
      String tm, String iid) {
    attendanceModel am = attendanceModel(
      classRoom: cr,
      courseName: cn,
      date: dt,
      section: sec,
      teacherName: tn,
      time: tm,
      id: iid,
    );
    setState(() {
      attend.add(am);
    });
  }

  void logout() {
    FirebaseAuth.instance.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return const SignInFive();
    }));
    displayToast("Logged Out Successfully");
  }

  Future<void> displayAttendance() async {
    db = FirebaseDatabase.instance.ref().child("/liveAttendance");
    DatabaseEvent event = await db.once();
    allAttendance = event.snapshot.value;
    if (allAttendance != null) {
      setState(() {
        attend.clear();
        allAttendance.forEach((key, value) async {
          if (allAttendance[key]["classRoom"].toString().toUpperCase() ==
              _locationStatus.toUpperCase()) {
            addAttendance(
              allAttendance[key]['classRoom'],
              allAttendance[key]['courseName'],
              allAttendance[key]['date'],
              allAttendance[key]['section'],
              allAttendance[key]['teacherName'],
              allAttendance[key]['time'],
              key.toString(),
            );
          }
        });
      });
    }
  }

  Future<File> saveImageToTempFile(img.Image faceImage) async {
    final tempDir =
        await pathProvider.getTemporaryDirectory(); // get temporary directory
    final tempFile =
        File('${tempDir.path}/$studentID.jpg'); // create temporary file
    await tempFile.writeAsBytes((await faceImage.getBytes())
        .buffer
        .asUint8List()); // write image data to file
    return tempFile; // return temporary file
  }

  Future<String> downloadImageAndStoreInCache(String imageUrl) async {
    final cacheManager = DefaultCacheManager();
    final file = await cacheManager.getSingleFile(imageUrl);

    return file.path;
  }

  Future<XFile?> captureImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    return capturedImage;
  }

  Future<void> authenticate(XFile? capturedImage) async {
    db = FirebaseDatabase.instance.ref().child("/faceAuth/$studentID");
    DatabaseEvent event = await db.once();
    var imageUrl = event.snapshot.value;
    final storedImage = await downloadImageAndStoreInCache(imageUrl.toString());

    bool res = false;
    res = await compareImages(File(capturedImage!.path), File(storedImage));

    if (res == true) {
      setState(() {
        _authenticationStatus = "Authenticated";
      });
      Navigator.of(context).pop();
      Future.delayed(Duration(minutes: 3), () {
        setState(() {
          _authenticationStatus = "Not Authenticated";
        });
      });
      return;
    } else {
      displayToast("Please Try Again");
      Navigator.of(context).pop();
      return;
    }
  }

  Future<void> updateAuthenticationStatus() async {
    var image = await captureImage();
    ProgressIndicator(context, 'Authenticating...  Please Wait.');
    await authenticate(image);
  }

  Future<void> markAttendance(attendanceModel attendanceObject) async {
    if (_authenticationStatus == "Not Authenticated") {
      displayToast("Please Authenticate before Marking Attendance");
      return;
    }
    if (_authenticationStatus == "Authenticated") {
      var section = null;
      String attendanceID = attendanceObject.id;
      _classList.forEach((stuSection) {
        if (stuSection.className == attendanceObject.courseName) {
          section = stuSection.section;
        }
      });
      if (section == null) {
        displayToast(
            "Please add your class and section accurately and then try again");
        return;
      }
      db = FirebaseDatabase.instance
          .ref()
          .child("/markAttendance/$attendanceID/${section}/$studentID");
      await db.set("P");
      displayToast(
          "Attendance Marked in ${attendanceObject.courseName}-$section");
      setState(() {
        _authenticationStatus = "Not Authenticated";
        _locationStatus = "Not Located";
        attend.clear();
      });
    }
  }

/////////////////DRAWWER FUNCTIONALITIES/////////////////////////////////////////////
  List<studentSections> _classList = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  void _addToList() {
    if (_formKey.currentState!.validate()) {
      var stuSection = studentSections(
        className: _classNameController.text.toUpperCase(),
        section: _sectionController.text.toUpperCase(),
      );
      setState(() {
        if (_classList.length < 6) {
          _classList.add(stuSection);
          box.add(stuSection);
          _classNameController.clear();
          _sectionController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only add up to 6 classes.'),
            ),
          );
        }
      });
    }
  }

  void _removeFromList(int index) {
    setState(() {
      _classList.removeAt(index);
      box.deleteAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.blue.shade600),
        backgroundColor: Colors.grey.shade900,
        toolbarHeight: 50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title:
            Text('Students App', style: TextStyle(color: Colors.blue.shade600)),
        centerTitle: false,
        actions: <Widget>[
          Obx(() {
            if (!controller.locationServiceEnabled) {
              return IconButton(
                tooltip: 'Not Determined',
                //iconSize: 5,
                icon: const Icon(
                  Icons.portable_wifi_off,
                ),
                color: Colors.grey,
                onPressed: () {},
              );
            }

            if (!controller.authorizationStatusOk) {
              return IconButton(
                tooltip: 'Not Authorized',
                icon: const Icon(Icons.portable_wifi_off),
                color: Colors.white70,
                onPressed: () async {
                  await flutterBeacon.requestAuthorization;
                },
              );
            }

            return IconButton(
              tooltip: 'Authorized',
              icon: const Icon(Icons.wifi_tethering),
              color: Colors.blue.shade600,
              onPressed: () async {
                await flutterBeacon.requestAuthorization;
              },
            );
          }),
          Obx(() {
            return IconButton(
              tooltip: controller.locationServiceEnabled
                  ? 'Location Service ON'
                  : 'Location Service OFF',
              icon: Icon(
                controller.locationServiceEnabled
                    ? Icons.location_on
                    : Icons.location_off,
              ),
              color: controller.locationServiceEnabled
                  ? Colors.blue.shade600
                  : Colors.white70,
              onPressed: controller.locationServiceEnabled
                  ? () {}
                  : handleOpenLocationSettings,
            );
          }),
          Obx(() {
            final state = controller.bluetoothState.value;

            if (state == BluetoothState.stateOn) {
              return IconButton(
                tooltip: 'Bluetooth ON',
                icon: const Icon(Icons.bluetooth_connected),
                onPressed: () {},
                color: Colors.blue.shade600,
              );
            }

            if (state == BluetoothState.stateOff) {
              return IconButton(
                tooltip: 'Bluetooth OFF',
                icon: const Icon(Icons.bluetooth),
                onPressed: handleOpenBluetooth,
                color: Colors.white70,
              );
            }

            return IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Bluetooth State Unknown',
              onPressed: () {},
              color: Colors.grey.shade900,
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Location: ${_locationStatus}',
                    style: TextStyle(color: Colors.blue.shade600)),
                // SizedBox(width: 10.0),
                VerticalDivider(width: 10),
                GestureDetector(
                  onTap: () async {
                    await updateAuthenticationStatus();
                  },
                  child: Text(
                    'Auth Status: $_authenticationStatus',
                    style: TextStyle(color: Colors.blue.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey.shade800,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.grey.shade800,
              title: const Text('My Classes'),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  color: Colors.blue.shade600,
                  onPressed: logout,
                ),
              ],
              iconTheme: IconThemeData(color: Colors.blue.shade600),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _classList.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) {
                      _removeFromList(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(50, 5, 50, 5),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        // color: color2,
                        shadowColor: Colors.blue.shade100,
                        elevation: 8.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade700,
                                  Colors.grey.shade500,
                                  Colors.grey.shade700
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            shape: BoxShape.rectangle,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _classList[index].className,
                                style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              const VerticalDivider(),
                              const VerticalDivider(),
                              Text(
                                _classList[index].section,
                                style: const TextStyle(fontSize: 20.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      style: TextStyle(color: Colors.grey.shade300),
                      controller: _classNameController,
                      decoration: InputDecoration(
                          labelText: 'Class Name',
                          labelStyle: TextStyle(color: Colors.grey.shade300)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a class name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      style: TextStyle(color: Colors.grey.shade300),
                      controller: _sectionController,
                      decoration: InputDecoration(
                          fillColor: Colors.grey.shade300,
                          labelText: 'Section',
                          labelStyle: TextStyle(color: Colors.grey.shade300)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a section';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue.shade700)),
                      onPressed: _addToList,
                      child: Text(
                        'Add Class',
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            //padding: const EdgeInsets.fromLTRB(0, 0.0, 0.0, 0.0),
            child: Stack(
              children: [
                Positioned(
                  left: -34,
                  top: 181.0,
                  child: SvgPicture.string(
                    // Group 3178
                    '<svg viewBox="-34.0 181.0 99.0 99.0" ><path transform="translate(-34.0, 181.0)" d="M 74.25 0 L 99 49.5 L 74.25 99 L 24.74999618530273 99 L 0 49.49999618530273 L 24.7500057220459 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-26.57, 206.25)" d="M 0 0 L 42.07500076293945 16.82999992370605 L 84.15000152587891 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(15.5, 223.07)" d="M 0 56.42999649047852 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                    width: 99.0,
                    height: 99.0,
                  ),
                ),
                Positioned(
                  right: -52,
                  top: 45.0,
                  child: SvgPicture.string(
                    // Group 3177
                    '<svg viewBox="288.0 45.0 139.0 139.0" ><path transform="translate(288.0, 45.0)" d="M 104.25 0 L 139 69.5 L 104.25 139 L 34.74999618530273 139 L 0 69.5 L 34.75000762939453 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(298.42, 80.45)" d="M 0 0 L 59.07500076293945 23.63000106811523 L 118.1500015258789 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(357.5, 104.07)" d="M 0 79.22999572753906 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                    width: 139.0,
                    height: 139.0,
                  ),
                ),
                if (attend.isEmpty)
                  Center(
                    child: ListView(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Text(
                                'No Attendance is Live',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 20),
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                            Image.asset(
                              'assets/images/waiting.png',
                              height: 200,
                              fit: BoxFit.fill,
                            )
                          ],
                        )
                      ],
                    ),
                  )
                else
                  ListView(
                    clipBehavior: Clip.antiAlias,
                    children: attend.map((bl) {
                      return Center(
                        child: GestureDetector(
                          onTap: () async {
                            await updateAuthenticationStatus();
                            await markAttendance(bl);
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 24.0),
                            elevation: 8.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.grey.shade700,
                                    Colors.grey.shade500,
                                    Colors.grey.shade700
                                  ],
                                  // stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          // color: Colors.black54,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8.0),
                                        child: Text(
                                          bl.courseName,
                                          style: TextStyle(
                                            color: cardTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Text(
                                      'Instructor',
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    Text(
                                      bl.teacherName,
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Divider(
                                      color: cardTextColor,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Day',
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    Text(
                                      bl.date,
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Divider(
                                      color: cardTextColor,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Time Slot',
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    Text(
                                      bl.time,
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Divider(
                                      color: cardTextColor,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Section',
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    Text(
                                      bl.section,
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Divider(
                                      color: cardTextColor,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Classroom',
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    Text(
                                      bl.classRoom,
                                      style: TextStyle(
                                        color: cardTextColor,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ProgressIndicator(context, 'Scanning...  Please Wait.');
          scan();
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.search, color: Colors.black),
      ),
      // bottomNavigationBar: SizedBox(
      //   height: 60,
      //   child: BottomNavigationBar(
      //     selectedItemColor: Colors.grey,
      //     unselectedItemColor: Colors.grey,
      //     backgroundColor: Colors.grey.shade800,
      //     elevation: 0.0,
      //     items: [
      //       BottomNavigationBarItem(
      //         label: 'Authorized',
      //         icon: SizedBox(
      //           height: 30,
      //           child: Obx(() {
      //             if (!controller.locationServiceEnabled) {
      //               return IconButton(
      //                 tooltip: 'Not Determined',
      //                 //iconSize: 5,
      //                 icon: const Icon(
      //                   Icons.portable_wifi_off,
      //                 ),
      //                 color: Colors.grey,
      //                 onPressed: () {},
      //               );
      //             }

      //             if (!controller.authorizationStatusOk) {
      //               return IconButton(
      //                 tooltip: 'Not Authorized',
      //                 icon: const Icon(Icons.portable_wifi_off),
      //                 color: Colors.white70,
      //                 onPressed: () async {
      //                   await flutterBeacon.requestAuthorization;
      //                 },
      //               );
      //             }

      //             return IconButton(
      //               tooltip: 'Authorized',
      //               icon: const Icon(Icons.wifi_tethering),
      //               color: Colors.blue.shade600,
      //               onPressed: () async {
      //                 await flutterBeacon.requestAuthorization;
      //               },
      //             );
      //           }),
      //         ),
      //       ),
      //       BottomNavigationBarItem(
      //         label: 'Location',
      //         icon: SizedBox(
      //           height: 30,
      //           child: Obx(() {
      //             return IconButton(
      //               tooltip: controller.locationServiceEnabled
      //                   ? 'Location Service ON'
      //                   : 'Location Service OFF',
      //               icon: Icon(
      //                 controller.locationServiceEnabled
      //                     ? Icons.location_on
      //                     : Icons.location_off,
      //               ),
      //               color: controller.locationServiceEnabled
      //                   ? Colors.blue.shade600
      //                   : Colors.white70,
      //               onPressed: controller.locationServiceEnabled
      //                   ? () {}
      //                   : handleOpenLocationSettings,
      //             );
      //           }),
      //         ),
      //       ),
      //       BottomNavigationBarItem(
      //         label: 'Bluetooth',
      //         icon: SizedBox(
      //           height: 30,
      //           child: Obx(() {
      //             final state = controller.bluetoothState.value;

      //             if (state == BluetoothState.stateOn) {
      //               return IconButton(
      //                 tooltip: 'Bluetooth ON',
      //                 icon: const Icon(Icons.bluetooth_connected),
      //                 onPressed: () {},
      //                 color: Colors.blue.shade600,
      //               );
      //             }

      //             if (state == BluetoothState.stateOff) {
      //               return IconButton(
      //                 tooltip: 'Bluetooth OFF',
      //                 icon: const Icon(Icons.bluetooth),
      //                 onPressed: handleOpenBluetooth,
      //                 color: Colors.white70,
      //               );
      //             }

      //             return IconButton(
      //               icon: const Icon(Icons.bluetooth_disabled),
      //               tooltip: 'Bluetooth State Unknown',
      //               onPressed: () {},
      //               color: Colors.grey.shade900,
      //             );
      //           }),
      //         ),
      //       ),
      //     ],
      //   ),
      // ));
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

  handleOpenLocationSettings() async {
    requestPermissions();
    if (Platform.isAndroid) {
      await flutterBeacon.openLocationSettings;
    } else if (Platform.isIOS) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Location Services Off'),
            content: const Text(
              'Please enable Location Services on Settings > Privacy > Location Services.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  handleOpenBluetooth() async {
    requestPermissions();
    if (Platform.isAndroid) {
      try {
        await flutterBeacon.openBluetoothSettings;
      } on PlatformException catch (e) {
        //print(e);
      }
    } else if (Platform.isIOS) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Bluetooth is Off'),
            content:
                const Text('Please enable Bluetooth on Settings > Bluetooth.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

class ProgressIndicatorWidget extends StatelessWidget {
  String displayText;
  ProgressIndicatorWidget({
    Key? key,
    required this.displayText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Text(
            displayText,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ),
      ]),
    );
  }
}
