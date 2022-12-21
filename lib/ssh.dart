import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:xterm/xterm.dart';
import 'package:xtermdemo/virtual_keyboard.dart';

const host = 'localhost';
const port = 22;
const username = '';
const password = '';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'xterm.dart demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final terminal = Terminal(inputHandler: keyboard);

  final keyboard = VirtualKeyboard(defaultInputHandler);

  var title = host;

  late SSHSession session;

  @override
  void initState() {
    super.initState();
    initTerminal();
  }

  Future<void> initTerminal() async {
    terminal.write('Connecting...\r\n');

    final client = SSHClient(
      await SSHSocket.connect(host, port),
      username: username,
      onPasswordRequest: () => password,
    );

    terminal.write('Connected\r\n');

    session = await client.shell(
      pty: SSHPtyConfig(
        width: terminal.viewWidth,
        height: terminal.viewHeight,
      ),
    );

    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);

    terminal.onTitleChange = (title) {
      setState(() => this.title = title);
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      session.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };

    terminal.onOutput = (data) {
      // for (var char in data.codeUnits) {
      //   switch (char) {
      //     case 3: // 终止
      //       session.write(utf8.encode('^%c') as Uint8List);
      //       break;
      //     case 13: // 回车
      //       session.write(utf8.encode('\n') as Uint8List);
      //       break;
      //     case 127: // 退格
      //       session.write(utf8.encode('\b \b') as Uint8List);
      //       break;
      //     default:
      //       session.write(utf8.encode(data) as Uint8List);
      //   }
      // }
    };

    session.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);

    session.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor:
        CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: TerminalView(terminal),
          ),
          VirtualKeyboardView(keyboard),
          CupertinoButton(onPressed: () {
            session.write(utf8.encode('pidof com.ilab.scione5cabinet\n') as Uint8List);
            // session.write(utf8.encode("12121212121212") as Uint8List);
          }, child: const Text("发送"))
        ],
      ),
    );
  }
}