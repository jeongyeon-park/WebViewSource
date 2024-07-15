import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'webview.dart';
import 'package:bixolon_btprinter/btprinter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async{
  await dotenv.load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _btprinterPlugin = Btprinter();//플러그인 호출
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>(); // Scaffold의 key

  @override
  void initState() {
    super.initState();

    initBle();// 블루투스 연결
  }
  void initBle() async {
    // Request BLE permissions from MainActivity
    await _getBle();
  }

  Future<void> _getBle() async {
    String? value;
    try {
      // value = await platform.invokeMethod('getBle');
      value = await _btprinterPlugin.getBtPermission();
    } on PlatformException catch (e) {
      value = 'native code error: ${e.message}';
    }
    print(value);
    _showSnackBar(value!, value == "success" ? true : false);
  }

  void _showSnackBar(String message, bool isSuccess) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      backgroundColor: Colors.blue,
    );

    final errSnackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      backgroundColor: Colors.red,
    );

    if (isSuccess) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(snackBar);
    } else {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!)
          .showSnackBar(errSnackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);//풀스크린 설정, 화면 로테이션 없음
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white, // 배경을 흰색으로 설정
        body: WebViewContainer(),
      ),
    );
  }
}


