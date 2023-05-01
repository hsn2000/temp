import 'dart:async';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

bool checkUserInput(String inputStr) {
  RegExp regExp = new RegExp(
      r'^k\d{6}$'); // pattern for matching 'k' followed by 5 digits
  if (!regExp.hasMatch(inputStr)) {
    return false; // input does not match pattern
  } else {
    return true; // input is valid
  }
}

Future<List<Face>> detectFace(String path) async {
  final options = FaceDetectorOptions();
  final faceDetector = FaceDetector(options: options);
  final input = InputImage.fromFilePath(path);
  final faces = await faceDetector.processImage(input);
  // Detect faces in the images
  // final faces = await faceDetector.processImage(input);
  return faces;
}

img.Image cropFace(List<Face> faces, img.Image originalImage) {
  // Crop faces from image
  final face1 = faces.first;
  final face1Rect = face1.boundingBox;
  final faceImage = img.copyCrop(originalImage,
      x: face1Rect.left.toInt(),
      y: face1Rect.top.toInt(),
      width: face1Rect.width.toInt(),
      height: face1Rect.height.toInt());
  return faceImage;
}

void askPermissions() async {
  // Request location permission
  var status = await Permission.locationAlways.status;
  if (status.isDenied) {
    var result = await Permission.locationAlways.request();
    if (result.isGranted) {
      displayToast("Permission Granted");
    } else {
      displayToast("Permission Denied");
    }
  }
  // Request Bluetooth permission
  status = await Permission.bluetoothScan.status;
  if (status.isDenied) {
    var result = await Permission.bluetoothScan.request();
    if (result.isGranted) {
      displayToast("Permission Granted");
    } else {
      displayToast("Permission Denied");
    }
  }
}

Future<geo.Position> determinePosition() async {
  bool serviceEnabled;
  geo.LocationPermission permission;
  permission = await geo.Geolocator.requestPermission();

  permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.denied) {
      displayToast('Location permissions are denied');
      return Future.error('Location permissions are denied');
    }
  }
  if (permission == geo.LocationPermission.deniedForever) {
    displayToast(
        'Location permissions are permanently denied, we cannot request permissions.');
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    displayToast('Location services are disabled.');
    return Future.error('Location services are disabled.');
  }

  return await geo.Geolocator.getCurrentPosition();
}

int mean(List<int> list) {
  var sum = 0;
  for (int i = 0; i < list.length; i++) {
    sum += list[i];
  }
  var avg = sum / list.length;
  return avg.toInt();
}

double meanFLoat(List<double> list) {
  var sum = 0.0;
  for (int i = 0; i < list.length; i++) {
    sum += list[i];
  }
  var avg = sum / list.length;
  return roundDouble(avg, 2);
}

double roundDouble(double value, int places) {
  num mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

int median(List<int> list) {
  list.sort();
  var index;
  var med;
  var sum;
  if (list.length % 2 == 0) // if even length
  {
    index = list.length / 2;
    sum = list[index.toInt() - 1] + list[index.toInt()];
    med = sum / 2;
  } else {
    index = list.length / 2;
    med = list[index.toInt()];
  }
  return med.toInt();
}

int mode(List<dynamic> list) {
  var map = Map();
  list.forEach((element) {
    if (!map.containsKey(element)) {
      map[element] = 1;
    } else {
      map[element] += 1;
    }
  });
  List sortedValues = map.keys.toList()..sort();
  int popularValue = sortedValues.first;
  return popularValue;
}

void displayToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey.shade800,
      textColor: Colors.white,
      fontSize: 16.0);
}
