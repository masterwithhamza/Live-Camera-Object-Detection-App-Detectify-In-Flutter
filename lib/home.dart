import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isWorking = false;
  String result = "";
  late CameraController cameraController;
  CameraImage? cameraImage;

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }
  loadModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenet_v1_1.0_224.tflite",
      labels: "assets/mobilenet_v1_1.0_224.txt",
    );
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await cameraController.initialize();
    if (mounted) {
      cameraController.startImageStream((imageFromStream) {
        if (!isWorking) {
          setState(() {
            isWorking = true;
            cameraImage = imageFromStream;
            runModelOnStreamFrames();
          });
        }
      });
    }
  }
  runModelOnStreamFrames() async {
    if (cameraImage != null) {
      var recognition = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes!;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      // Process the recognition results
      result="";
      recognition!.forEach((response) {
        result+=response["label"] + " " + (response["confidence"] as double).toStringAsFixed(2)+"\n";
      });
      setState(() {
        result;
      });
      isWorking=false;
    }
  }
  @override
  void dispose() {

    super.dispose();
    cameraController.dispose();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Detectify")),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            height: 270,
            width: 360,
            child: cameraImage == null
                ? Container(
              height: 270,
              width: 360,
              child: const Icon(Icons.photo_camera, color: Colors.red),
            )
                : AspectRatio(
              aspectRatio: cameraController.value.aspectRatio,
              child: CameraPreview(cameraController),
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: Colors.green,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}
