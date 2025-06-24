import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String _scanBarcode = 'Unknown';
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Start scanning automatically when page loads
    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    cameraController.stop();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _stopScanning();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _scanBarcode = barcode.rawValue!;
                  });

                  // Stop scanning and handle result
                  _stopScanning();
                  
                  // Navigate back with result
                  Navigator.pop(context, _scanBarcode);

                  // Show scan result
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scanned: $_scanBarcode'),
                      backgroundColor: Color(0xFF9A7ED0),
                    ),
                  );
                  return;
                }
              }
            },
          ),
          
          // Overlay UI
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                stops: [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
          
          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xFF9A7ED0),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                          left: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                          right: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                          left: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                          right: BorderSide(color: Color(0xFF9A7ED0), width: 5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFF9A7ED0),
                        size: 32,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Position QR code within the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Scan will happen automatically',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Manual scan button
                Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF9A7ED0),
                        Color(0xFFb296f2),
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startScanning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning ? Icons.stop : Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isScanning ? 'Scanning...' : 'Start Scan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
