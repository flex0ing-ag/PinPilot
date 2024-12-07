import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(CombinedScannerApp());

class CombinedScannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combined Scanner App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CombinedScannerScreen(),
    );
  }
}

class CombinedScannerScreen extends StatefulWidget {
  @override
  _CombinedScannerScreenState createState() => _CombinedScannerScreenState();
}

class _CombinedScannerScreenState extends State<CombinedScannerScreen> {
  bool isQRScannerActive = false; // Initially, none of the scanners are active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Combined Scanner'),
      ),
      body: Column(
        children: [
          // Toggle buttons (always visible)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isQRScannerActive = true;
                    });
                  },
                  child: Text('QR Code Scanner'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isQRScannerActive = false;
                    });
                  },
                  child: Text('Image Scanner'),
                ),
              ],
            ),
          ),
          
          // Show selected scanner or an instruction message
          Expanded(
            child: isQRScannerActive
                ? QRScannerScreen() // Only show the QR Scanner when selected
                : ImageScannerScreen(), // Show the image scanner when selected
          ),
        ],
      ),
    );
  }
}

// QR Code Scanner Widget
class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String qrText = 'Scan a QR code';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.red,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ),
        Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  qrText,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    controller?.resumeCamera(); // Resume scanning if paused
                  },
                  child: Text('Scan QR'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera(); // Stop scanning after the first scan

      setState(() {
        qrText = scanData.code!;
      });

      // Call scanQRCode with the scanned data
      await scanQRCode(scanData.code!);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> scanQRCode(String data) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/scan_qr_code'), // Backend running on localhost
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': data}),
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body) as Map<String, dynamic>;
          setState(() {
            qrText = responseData['text'] ?? 'No data received';
          });
          print('Scanned QR Code data: $responseData');
        } catch (e) {
          // Handle JSON decoding errors
          print('Error decoding JSON: $e');
          setState(() {
            qrText = 'Error decoding JSON';
          });
        }
      } else {
        print('Failed to scan QR Code: ${response.reasonPhrase}');
        setState(() {
          qrText = 'Failed to scan QR Code';
        });
      }
    } catch (e) {
      // Handle network or other errors
      print('Error making request: $e');
      setState(() {
        qrText = 'Error making request';
      });
    }
  }
}

// Image Scanner Widget
class ImageScannerScreen extends StatefulWidget {
  @override
  _ImageScannerScreenState createState() => _ImageScannerScreenState();
}

class _ImageScannerScreenState extends State<ImageScannerScreen> {
  bool textScanning = false;
  XFile? imageFile;
  String scannedText = "";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (textScanning) const CircularProgressIndicator(),
              if (!textScanning && imageFile == null)
                Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[300]!,
                ),
              if (imageFile != null) Image.file(File(imageFile!.path)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    child: Column(
                      children: [
                        const Icon(Icons.image, size: 30),
                        const Text("Gallery"),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      getImage(ImageSource.camera);
                    },
                    child: Column(
                      children: [
                        const Icon(Icons.camera_alt, size: 30),
                        const Text("Camera"),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                scannedText,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          textScanning = true;
          imageFile = pickedImage;
        });
        await uploadImage(pickedImage);
      }
    } catch (e) {
      setState(() {
        textScanning = false;
        imageFile = null;
        scannedText = "Error occurred while scanning";
      });
    }
  }

  Future<void> uploadImage(XFile image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:5000/decode_qr'), // Backend running on localhost
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final response = await request.send();
    
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      setState(() {
        scannedText = responseData; // Update with the text received from backend
      });

      // Call generateQRCode with the scanned text
      await generateQRCode(scannedText);
    } else {
      setState(() {
        textScanning = false;
        scannedText = "Failed to upload image.";
      });
    }

    setState(() {
      textScanning = false;
    });
  }

  Future<void> generateQRCode(String data) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/generate_qr'), // Backend running on localhost
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'data': data}),
    );

    if (response.statusCode == 200) {
      // Handle the QR code image response if needed
      print('QR Code generated successfully.');
    } else {
      print('Failed to generate QR Code: ${response.reasonPhrase}');
    }
  }
}
