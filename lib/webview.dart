import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bixolon_btprinter/btprinter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebViewContainer extends StatefulWidget {
  @override
  _WebViewContainerState createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late WebViewController _controller;
  final _btprinterPlugin = Btprinter();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('messageHandler', onMessageReceived: (message) async {
        List<dynamic> jsonData = jsonDecode(message.message);
        List<Object> printData = [];
        List<Object> barcodeData = [];
        // List<Object>로 변환
        if(jsonData[0]['barcode'] == true)
          {

            for (var item in jsonData.sublist(1, jsonData.length-2)) {
              printData.add(item as Object); // Map<String, dynamic>을 Object로 캐스팅하여 추가
            }
            barcodeData.add(jsonData[jsonData.length-2] as Object);
            barcodeData.add(jsonData[jsonData.length-1] as Object);
            print(printData);
            print(barcodeData);
          }
        else
          {
            for (var item in jsonData.sublist(1)) {
              printData.add(item as Object); // Map<String, dynamic>을 Object로 캐스팅하여 추가
            }
          }
        print(printData);
        print(barcodeData);
        try{
          List<Object> devices = await _getPairedDevices();
          if(devices.length == 1){
            _showLoadingDialog(context, devices[0].toString(), printData, barcodeData);
          }
          else {
            _showAlertDialog(context, devices, printData, barcodeData);
          }
        }catch (e){
          await _showBluetoothErrDialog(context, e.toString());
        }
      })
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('Loading progress: $progress');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onHttpError: (HttpResponseError error) {
            print('HTTP error: $error');
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: $error');
          },
        ),
      )
      ..loadRequest(Uri.parse('${dotenv.env['BASE_URL']}/?auth=ndev2'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }

  Future<List<Object>> _getPairedDevices() async {
    String value;
    try {
      List<Object?> devices = await _btprinterPlugin.getPairedDevices();
      return devices.cast<String>().where((device) => device.startsWith('SPP')).toList();
    } on PlatformException catch (e) {
      value = "플러그인 호출 실패: ${e.message}";
      print(value);
      return [];
    }
  }

  Future<void> _print(String? device, List<Object> printText, BuildContext dialogContext,  List<Object> barcodeData) async {
    List<String> deviceInfo = device!.split('(');
    String logicalName = deviceInfo[0].split("_")[0].trim();
    String address = deviceInfo[1].replaceAll(')', '').trim();

    String? value;
   // value = await _btprinterPlugin.printBarcode([{'data': '123456789012' , 'symbology' : Btprinter.BARCODE_TYPE_QRCODE, 'alignment' : Btprinter.ALIGNMENT_CENTER }], logicalName, address);
    try {
      value = await _btprinterPlugin.printText(printText, logicalName, address);
      //바코드데이터 있을때만 출력
      if(barcodeData.isNotEmpty)
      {
        value = await _btprinterPlugin.printBarcode(barcodeData, logicalName, address);
      }
    } catch (e) {
      value = "기기연결을 확인하세요: ${e}";
    }

    if (mounted && dialogContext.mounted) {
      Navigator.of(dialogContext).pop(); // 로딩 다이얼로그 닫기
      _showResultDialog(dialogContext, value!); // 결과 표시하는 새로운 AlertDialog 열기
    }
  }

  void _showLoadingDialog(BuildContext context, String device, List<Object> printText, List<Object> barcodeData)  {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by clicking outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(color: Colors.lightBlueAccent,),
          ),
        );
      },
    );

    _print(device, printText, context, barcodeData);
  }

  void _showAlertDialog(BuildContext context, List<Object> devices, List<Object> printText,  List<Object> barcodeData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        if (devices.isEmpty) {
          return AlertDialog(
            title: Text('연결된 기기를 찾을 수 없습니다.'),
            content: Text('블루투스를 켜고 프린터를 연결해주세요.'),
            actions: [
              TextButton(
                child: Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text('출력할 프린터를 선택하세요'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(devices[index].toString()),
                    onTap: () {
                      Navigator.of(context).pop(); //프린터기 리스트 닫기
                      _showLoadingDialog(context, devices[index].toString(), printText, barcodeData);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _showResultDialog(BuildContext context,  String message) async {
    return showDialog<void>(
      context: context,
      //barrierDismissible: false, // true 하면 무조건 확인 눌러야 사라짐
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('프린트 결과'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBluetoothErrDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      //barrierDismissible: false, // true 하면 무조건 확인 눌러야 사라짐
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('블루투스 권한을 허용해주세요'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissionAfterDialog();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermissionAfterDialog() async {
    await Future.delayed(Duration(milliseconds: 100)); // 다이얼로그 닫히는 시간 고려
    await _handlePermissionRequest();
  }

  Future<void> _handlePermissionRequest() async {
    await _btprinterPlugin.getBtPermission();
  }
}
