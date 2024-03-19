import 'package:flutter/material.dart';
import 'package:serial_port_win32/serial_port_win32.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serial Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Serial Chat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> ports = [];
  SerialPort? port;
  int baudRate = 115200;

  List<List<dynamic>> msgs = [];

  TextEditingController textEditingController = TextEditingController();

  void checkAvailablePorts() {
    ports = SerialPort.getAvailablePorts();
    setState(() {});
  }

  void selectPort(String name) {
    port = SerialPort(
      name,
      openNow: false,
      ByteSize: 8,
      //ReadIntervalTimeout: 5,
      //ReadTotalTimeoutConstant: 10,
    );
    setState(() {});
  }

  void openAndListenPort() {
    if (port == null) return;

    try {
      port!.openWithSettings(BaudRate: baudRate);

      port!.readBytesOnListen(255, (value) {
        String s = String.fromCharCodes(value);
        msgs.add([s, DateTime.now(), true]);
        setState(() {});
      });

      setState(() {});
    } catch (e) {}
  }

  void sendMsg() {
    if (port == null) return;
    try {
      port!.writeBytesFromString("${textEditingController.text}\n");
      msgs.add([textEditingController.text, DateTime.now(), false]);
      textEditingController.text = "";
      setState(() {});
    } catch (e) {}
  }

  void closePort() {
    if (port == null) return;
    port!.close();
    msgs.clear();
    setState(() {});
  }

  bool isPortOpened() {
    return port != null && port!.isOpened;
  }

  Widget chatMsg(List msg) {
    return Row(
      children: [
        if (!msg[2]) const Spacer(),
        Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: msg[2] ? Colors.grey.shade300 : Colors.deepPurple.shade100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${msg[2] ? port!.portName : 'ME'} · ${msg[1].hour.toString().padLeft(2, '0')}:${msg[1].minute.toString().padLeft(2, '0')}:${msg[1].second.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(msg[0]),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    closePort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: isPortOpened()
                      ? null
                      : () {
                          checkAvailablePorts();
                        },
                  child: const Text("Load Available Ports"),
                ),
                const SizedBox(width: 10),
                DropdownButton(
                  hint: const Text("Select a port"),
                  value: port != null ? port!.portName : null,
                  items: [
                    for (String p in ports)
                      DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                  ],
                  onChanged: isPortOpened()
                      ? null
                      : (String? value) {
                          selectPort(value!.toString());
                        },
                ),
                DropdownButton(
                  hint: const Text("Baud Rate"),
                  value: baudRate,
                  items: [
                    for (int r in [9600, 14400, 19200, 38400, 57600, 115200])
                      DropdownMenuItem<int>(
                        value: r,
                        child: Text(r.toString()),
                      ),
                  ],
                  onChanged: isPortOpened()
                      ? null
                      : (int? value) {
                          baudRate = value!;
                          setState(() {});
                        },
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: port == null
                      ? null
                      : () {
                          if (port!.isOpened) {
                            closePort();
                          } else {
                            openAndListenPort();
                          }
                        },
                  child: Text(isPortOpened() ? "Disconnect" : "Connect"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "LIVE COMMUNICATION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: msgs.isNotEmpty
                    ? SingleChildScrollView(
                        reverse: true,
                        child: Column(
                          children: [
                            for (final s in msgs) chatMsg(s),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          "No Messages",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    controller: textEditingController,
                    decoration: const InputDecoration(
                      hintText: "Type a message here...",
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                FloatingActionButton(
                  onPressed:
                      textEditingController.text.isEmpty // || !isPortOpened()
                          ? null
                          : () {
                              sendMsg();
                            },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
