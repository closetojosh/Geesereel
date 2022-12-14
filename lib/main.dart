import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;

import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(MaterialApp(
    title: 'Home',
    home: HomePage(
      camera: firstCamera,
    ),
  ));
}

class HomePage extends StatelessWidget {
  final CameraDescription camera;

  const HomePage({
    super.key,
    required this.camera,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      PreferredSize(
          preferredSize: const Size.fromHeight(75.0), // here the desired height
          child:
            AppBar(
              titleSpacing: 0.0,
              title: const Text(
                'GeeseReel',
                style:
                TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.brown,
            ),
      ),
      body: Center(
        child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints.expand(),
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/geese-background.png'),
                  fit: BoxFit.cover),
            ),
            child: SizedBox(
              height: 125,
              width: 225,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to second route when tapped.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                              camera: camera,
                            )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 189, 171, 116),
                  textStyle: const TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold
                  ),
                ),
                child: const Text('Daily Photo !'),
              ),
            )),
      ),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75.0), // here the desired height
          child:
            AppBar(
              titleSpacing: 0.0,
              title: const Text(
                'Find your Goose!',
                style:
                TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.brown,
            ),
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 115.0,
        width: 115.0,
        child: FittedBox(
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 189, 171, 116),
            // Provide an onPressed callback.
            onPressed: () async {
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                // Ensure that the camera is initialized.
                await _initializeControllerFuture;

                // Attempt to take a picture and get the file `image`
                // where it was saved.
                final image = await _controller.takePicture();

                if (!mounted) return;

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DisplayPictureScreen(tempImagePath: image.path)));

                // var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:5000/upload'));

                // request.files.add(http.MultipartFile.fromBytes('image', File(image.path).readAsBytesSync(),filename: image.path));

                // var res = await request.send();
                // debugPrint(res.toString());

              } catch (e) {
                // If an error occurs, log the error to the console.
                print(e);
              }
            },
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String tempImagePath;

  const DisplayPictureScreen({super.key, required this.tempImagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75.0), // here the desired height
          child:
            AppBar(
              titleSpacing: 0.0,
              title: const Text(
                'Score: 69',
                style:
                TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.brown,
            ),
      ),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height - 328,
                child: Image.asset(tempImagePath),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 35.0, horizontal: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Save photo to image gallery
                    GallerySaver.saveImage(tempImagePath);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 189, 171, 116),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  child: const Text('Save this Mastergeese?', textAlign: TextAlign.center,),
                )
              )
            ]
          )
        );
  }
}
