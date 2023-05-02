import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:math';
import 'helper_functions.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

Future<bool> compareImages(File image1, File image2) async {
  // Load the mobilefacenet.tflite model
  final interpreter =
      await Interpreter.fromAsset('models/mobilefacenet.tflite');

  // Load the two images
  final bytes1 = await image1.readAsBytes();
  final bytes2 = await image2.readAsBytes();

  // Convert the images to Image objects
  final image1Obj = img.decodeImage(bytes1);
  final image2Obj = img.decodeImage(bytes2);

  final faces1 = await detectFace(image1.path);
  final faces2 = await detectFace(image2.path);

  if (faces1.isEmpty) {
    displayToast("No Face Detected");
    return false;
  }
  if(faces1.length > 1){
    displayToast("Multiple Faces Detected");
    return false;
  }

  // //Initialize Google ML Kit face detector
  // final inputImage1 = InputImage.fromFilePath(image1.path);
  // final inputImage2 = InputImage.fromFilePath(image2.path);
  // final faceDetector = GoogleMlKit.vision.faceDetector();

  // // Detect faces in the images
  // final faces1 = await faceDetector.processImage(inputImage1);
  // final faces2 = await faceDetector.processImage(inputImage2);

  // print("LENGTH");
  // print(faces1.length);

  // Check if only one face was detected in each image
  if (faces1.isEmpty ||
      faces2.isEmpty ||
      faces1.length > 1 ||
      faces2.length > 1) {
    return false;
  }

  final face1Image = cropFace(faces1, image1Obj!);
  final face2Image = cropFace(faces2, image2Obj!);

  // // Crop faces from image 1
  // final face1 = faces1.first;
  // final face1Rect = face1.boundingBox;
  // final face1Image = img.copyCrop(image1Obj!,
  //     x: face1Rect.left.toInt(),
  //     y: face1Rect.top.toInt(),
  //     width: face1Rect.width.toInt(),
  //     height: face1Rect.height.toInt());

  // // Crop faces from image 2
  // final face2 = faces2.first;
  // final face2Rect = face2.boundingBox;
  // final face2Image = img.copyCrop(image2Obj!,
  //     x: face2Rect.left.toInt(),
  //     y: face2Rect.top.toInt(),
  //     width: face2Rect.width.toInt(),
  //     height: face2Rect.height.toInt());

  var f1 = await convertImageTo3DList(face1Image);
  var f2 = await convertImageTo3DList(face2Image);

  // Generate embeddings for cropped faces using mobilefacenet.tflite model
  var output = List.filled(192, 0.0);
  var output1 = [output];
  var output2 = [output];

  // final output2 = List.filled(192, 0.0);
  interpreter.run(f1, output1);
  interpreter.run(f2, output2);

  // // Calculate the dot product of output1 and output2
  // double dotProduct = 0.0;
  // for (int i = 0; i < output1[0].length; i++) {
  //   dotProduct += output1[0][i] * output2[0][i];
  // }

  // // Calculate the magnitudes of output1 and output2
  // double mag1 = 0.0;
  // double mag2 = 0.0;
  // for (int i = 0; i < output1[0].length; i++) {
  //   mag1 += output1[0][i] * output1[0][i];
  //   mag2 += output2[0][i] * output2[0][i];
  // }
  // mag1 = sqrt(mag1);
  // mag2 = sqrt(mag2);

  // // Calculate the cosine similarity
  // double similarity = dotProduct / (mag1 * mag2);
  var similarity = calculateCosineSimilarity(output1, output2);
  print(similarity);
  // displayToast(similarity.toString());
// Determine if the two images are of the same person or not based on the cosine similarity threshold
  return similarity >= 0.75;
}

double calculateCosineSimilarity(
    List<List<double>> output1, List<List<double>> output2) {
  // Calculate the dot product of output1 and output2
  double dotProduct = 0.0;
  for (int i = 0; i < output1[0].length; i++) {
    dotProduct += output1[0][i] * output2[0][i];
  }

  // Calculate the magnitudes of output1 and output2
  double mag1 = 0.0;
  double mag2 = 0.0;
  for (int i = 0; i < output1[0].length; i++) {
    mag1 += output1[0][i] * output1[0][i];
    mag2 += output2[0][i] * output2[0][i];
  }
  mag1 = sqrt(mag1);
  mag2 = sqrt(mag2);

  // Calculate the cosine similarity
  double similarity = dotProduct / (mag1 * mag2);

  return similarity;
}

Future<List<List<List<List<double>>>>> convertImageTo3DList(
    img.Image image) async {
  // Resize the image to 112x112
  img.Image? resizedImage = img.copyResize(image, width: 112, height: 112);

  // Convert the resized image to a 3D list with shape [1, 112, 112, 3]
  List<List<List<List<double>>>> imageList = [];
  List<List<List<double>>> rowList = [];
  List<List<double>> pixelList = [];

  // Normalize the pixel values
  for (int i = 0; i < 112; i++) {
    for (int j = 0; j < 112; j++) {
      pixelList.add([
        (resizedImage.getPixel(j, i).r - 127.5) / 128.0,
        (resizedImage.getPixel(j, i).g - 127.5) / 128.0,
        (resizedImage.getPixel(j, i).b - 127.5) / 128.0,
      ]);
    }
    rowList.add(pixelList);
    pixelList = [];
  }
  imageList.add(rowList);

  return imageList;
}

  // Face face = faces.first;
  // int left = max(0, (face.boundingBox.left - 0.2 * face.boundingBox.width).round());
  // int top = max(0, (face.boundingBox.top - 0.2 * face.boundingBox.height).round());
  // int right = min(image.width, (face.boundingBox.right + 0.2 * face.boundingBox.width).round());
  // int bottom = min(image.height, (face.boundingBox.bottom + 0.2 * face.boundingBox.height).round());
  // img.Image? croppedImage = img.copyCrop(image, left, top, right - left, bottom - top);


// Future<List<List<List<List<double>>>>> convertImageTo3DList(img.Image image) async {
//   // Resize the image to 112x112
//   img.Image? resizedImage =
//       img.copyResize(image, width: 112, height: 112);

//   // Convert the resized image to a 3D list with shape [1, 112, 112, 3]
//   List<List<List<List<double>>>> imageList = [];
//   List<List<List<double>>> rowList = [];
//   List<List<double>> pixelList = [];
//   for (int i = 0; i < 112; i++) {
//     for (int j = 0; j < 112; j++) {
//       pixelList.add([
//         resizedImage.getPixel(j, i).r / 255.0,
//         resizedImage.getPixel(j, i).g / 255.0,
//         resizedImage.getPixel(j, i).b / 255.0,
//       ]);
//     }
//     rowList.add(pixelList);
//     pixelList = [];
//   }
//   imageList.add(rowList);
//   return imageList;
// }
