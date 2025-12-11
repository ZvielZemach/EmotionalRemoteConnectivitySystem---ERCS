// import 'package:flutter/material.dart';
// import 'package:flutter_blue/flutter_blue.dart';

// class Sendsongbt extends StatelessWidget {
//   final FlutterBlue flutterBlue = FlutterBlue.instance;
//   BluetoothDevice? _device;
//   BluetoothCharacteristic? _characteristic;

//   Sendsongbt({super.key});

//   void connectToBluetooth() async {
//     var scanResult = await flutterBlue.scanForDevices();
//     // מצא את המכשיר והתחבר אליו
//     _device = scanResult.firstWhere((device) => device.name == "ESP32_MP3_Control");
//     await _device!.connect();
//     _characteristic = await _device!.discoverServices()
//         .then((services) => services.first.characteristics.first);
//   }

//   void sendCommand(String command) async {
//     if (_characteristic != null) {
//       await _characteristic!.write(command.codeUnits);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Control MP3 Player via Bluetooth"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () => sendCommand("play"),
//               child: Text("הפעל שיר"),
//             ),
//             ElevatedButton(
//               onPressed: () => sendCommand("pause"),
//               child: Text("עצור שיר"),
//             ),
//             ElevatedButton(
//               onPressed: () => sendCommand("next"),
//               child: Text("שיר הבא"),
//             ),
//             ElevatedButton(
//               onPressed: () => sendCommand("prev"),
//               child: Text("שיר קודם"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
