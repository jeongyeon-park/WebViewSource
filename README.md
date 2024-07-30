# 블루투스 프린터 플러그인 적용 테스트 프로젝트

 [플러그인 배포 링크](https://pub.dev/packages/bixolon_btprinter) 
- bixolon_btprinter 플러그인 개발하여 사용
- bixolon_btprinter: ^0.1.1 사용
- flutter_dotenv(env 파일 사용하기위한 플러그인)

## Getting Started
flutter pub get 후 Android Studio 혹은 VSCode 에서 실행

**루트 폴더에 .env 생성 후 BASE_URL='사용할 address' 설정해줘야 실행 가능합니다.** 


### 사용 플러그인
- bixolon_btprinter
- webview_flutter

## webview 출력 전송 양식 

### 웹뷰 소스
```javascript
//웹뷰 소스 
sendSample() {
	//console.log(this.cData);
	if('messageHandler' in window)
	{
		const printData = this.makeSample();
		window.messageHandler.postMessage(window.messageHandler.postMessage(JSON.stringify(printData)));
		//window.messageHandler.postMessage(JSON.stringify(printData));
	}
	this.makeSample();
},
```
**데이터를 JSON 배열 양식으로 보냅니다.** 
**JSON 배열 첫 요소가 {barcode : true} 혹은 {barcode : false} 여야 합니다.**
**접속 WIFI 주소가 cw 로 시작하는 WIFI 여야 접근할 수 있습니다.**

아래와 같이 flutter 소스에서 배열 첫 요소의 barcode 값이 true 냐 false 이냐에 따라
분기가 나뉘기 때문입니다. 
때문에 아래와 같은 양식으로 보낼 수 있습니다. 

### 웹뷰 데이터 전송 양식
```javascript 
//웹뷰 데이터 전송 양식 
makeSample() { 
	const printText = [{'barcode' : true}, //바코드 유무
    {'text': 'Alignment left\n', 'textAlignment': btprinter.ALIGNMENT_LEFT, 'textAttribute': btprinter.ATTRIBUTE_NORMAL},
    {'text': 'Alignment Center\n', 'textAlignment': btprinter.ALIGNMENT_CENTER, 'textAttribute': btprinter.ATTRIBUTE_NORMAL},
    {'text': 'Alignment Right\n', 'textAlignment': btprinter.ALIGNMENT_RIGHT, 'textAttribute': btprinter.ATTRIBUTE_NORMAL},
    {'text': 'Font Size 1\n', 'textAttribute': btprinter.ATTRIBUTE_NORMAL, 'textSize': 1},
    {'text': 'Font Size 2\n', 'textAttribute': btprinter.ATTRIBUTE_NORMAL, 'textSize': 2},
    {'text': 'Font Reverse\n', 'textAttribute': btprinter.ATTRIBUTE_REVERSE},
    {'text': 'Font Bold\n', 'textAttribute': btprinter.ATTRIBUTE_REVERSE},
    {'text': 'Font Underline\n', 'textAttribute': btprinter.ATTRIBUTE_UNDERLINE},
    {'text': '\u{1B}|0fT Font A\n'},
    {'text': '\u{1B}|1fT Font A\n'},
    {'text': '\u{1B}|2fT Font A\n'},
    {'text': '\u{1B}|2hC Font width magnification x2\n'},
    {'text': '\u{1B}|4hC Font width magnification x4\n'},
    {'text': '\u{1B}|8hC Font width magnification x8\n'},
    {'text': '\u{1B}|2vC Font height magnification x2\n'},
    {'text': '\u{1B}|4vC Font height magnification x4\n'},
    {'text': '\u{1B}|8vC Font height magnification x8\n'},
  ];

   //QR CODE 출력
	printText.push({data:'https://www.comware.co.kr/solution/baljugo',  symbology : btprinter.BARCODE_TYPE_QRCODE, alignment: btprinter.ALIGNMENT_CENTER});
	//바코드 출력
	printText.push({data: '123456789012' , symbology : btprinter.BARCODE_TYPE_ITF, alignment : btprinter.ALIGNMENT_CENTER })

	console.log(printText); // 가공된 데이터 확인
    return printText;
},
```

위 양식을 flutter 에서 받는 소스는 아래와 같습니다. 

#### 추후 개선 필요 
**아래 flutter 소스에서 webview 에서 전송한 배열 첫번째 요소의 
barcode : true 라면 배열 끝 요소 두개를 barcode 데이터 배열에 넣고
추후 바코드 요청을 하도록 개발되어있습니다.**
이 점 개선이 필요합니다. 

### flutter 소스 
```dart
//flutter 소스 
 ..addJavaScriptChannel('messageHandler', onMessageReceived: (message) async {
        List<dynamic> jsonData = jsonDecode(message.message);
        List<Object> printData = [];
        List<Object> barcodeData = [];
        // List<Object>로 변환
        // barcode : true 이면 배열의 맨 끝 두 요소를 barcodeData 에 넣습니다. 
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
```

### 발주고 관리자 소스 static\js 에 btprinter.js 생성 필요 
```javascript
// 블루투스 프린터 출력 형식 객체
const btprinter = {
  // Alignment
  ALIGNMENT_LEFT: 1,
  ALIGNMENT_CENTER: 2,
  ALIGNMENT_RIGHT: 4,

  // Text attribute
  ATTRIBUTE_NORMAL: 0,
  ATTRIBUTE_FONT_A: 1,
  ATTRIBUTE_FONT_B: 2,
  ATTRIBUTE_FONT_C: 4,
  ATTRIBUTE_BOLD: 8,
  ATTRIBUTE_UNDERLINE: 16,
  ATTRIBUTE_REVERSE: 32,
  ATTRIBUTE_FONT_D: 64,

  // Barcode Symbology
  BARCODE_TYPE_UPCA: 101,
  BARCODE_TYPE_UPCE: 102,
  BARCODE_TYPE_EAN8: 104,
  BARCODE_TYPE_EAN13: 103,
  BARCODE_TYPE_ITF: 106,
  BARCODE_TYPE_Codabar: 107,
  BARCODE_TYPE_Code39: 105,
  BARCODE_TYPE_Code93: 108,
  BARCODE_TYPE_Code128: 109,
  BARCODE_TYPE_PDF417: 201,
  BARCODE_TYPE_MAXICODE: 203,
  BARCODE_TYPE_DATAMATRIX: 204,
  BARCODE_TYPE_QRCODE: 202,
  BARCODE_TYPE_EAN128: 120,

  // Barcode HRI
  BARCODE_HRI_NONE: -11,
  BARCODE_HRI_ABOVE: -12,
  BARCODE_HRI_BELOW: -13,

  isHangul: function isHangul(char) {
    return /\p{Script=Hangul}/u.test(char);
  },

  getStringLength: function getStringLength(str) {
    let length = 0;
    for (const char of str) {
      if (btprinter.isHangul(char)) {
        length += 2; // 한글은 두 자리로 취급
      } else {
        length += 1; // 나머지 문자는 한 자리로 취급
      }
    }
    return length;
  },

  //Align : left 로 지정하고 
  //배송금액                     1,000원
  //처럼 글자 사이 공백을 설정해주는 함수 
  //첫번째 프로퍼니 words 에 ['배송금액', '1,000원'] 이렇게 넣으면 두 요소 사이 공백 설정
  //현재 배열에 요소 두개 넣는것만 가능 ['배송금액', '1개', '1,000원'] 이렇게 세개 이상 불가. 개선 필요  
  setStrBlank: function setStrBlank(words, maxLineLength = 48) {
    let currentLineLength = 0;
    let currentLineWords = [];
    let result = "";

    for (const word of words) {
      const wordLength = btprinter.getStringLength(word);

      if (currentLineLength + wordLength <= maxLineLength) {
        currentLineWords.push(word);
        currentLineLength += wordLength + 1; // 단어 뒤에 공백 포함
      } else {
        const spacesToAdd = maxLineLength - currentLineLength + 1; // 공백 포함
        const spacedLine = btprinter.addSpaces(currentLineWords, spacesToAdd);
        result += spacedLine + "\n"; // 최종 문자열 결과에 추가
        currentLineWords = [word];
        currentLineLength = wordLength + 1;
      }
    }

    if (currentLineWords.length > 0) {
      const spacesToAdd = maxLineLength - currentLineLength + 1; // 공백 포함
      const spacedLine = btprinter.addSpaces(currentLineWords, spacesToAdd);
      result += spacedLine; // 최종 문자열 결과에 추가
    }

    return result;
  },

  addSpaces: function addSpaces(words, spacesToAdd) {
    return words[0] + " ".repeat(spacesToAdd) + words[1];
  },
};

export default btprinter;

```

### 웹뷰 구현 소스
발주고 관리자 웹 DelOrderCustDetail.vue 에 구현. 

- sendMessage() : flutter webview 로 데이터 전송 로직 (텍스트 프린트)
- makeMessage() : 영수증 데이터 생성 함수 (텍스트 프린트)
- sendSample() : flutter webview 로 데이터 전송 로직 (바코드 프린트)
- makeSample() : 샘플 데이터(글자 굵게, 작게, QRCODE, Barcode 등등 출력 샘플) 생성 함수 

**로직소스**
```javascript
sendMessage(){
			//console.log(this.cData);
			if('messageHandler' in window)
			{
				const printData = this.makeMessage();
				window.messageHandler.postMessage(window.messageHandler.postMessage(JSON.stringify(printData)));
				//window.messageHandler.postMessage(JSON.stringify(printData));
			}
			this.makeMessage();
		},
		makeMessage(){
			//바코드 유무 
			const printText = [{'barcode' : false}];

 			// 상호
			printText.push({ text: '\n\n'+ this.cuSangho + '\n\n', textAlignment: btprinter.ALIGNMENT_CENTER, textAttribute: btprinter.ATTRIBUTE_BOLD, textSize: 2 });

    		// 주문상세정보
    		printText.push({ text: this.$t('orderInfo.orderInfo') + '\n', textAlignment: btprinter.ALIGNMENT_LEFT, textAttribute: btprinter.ATTRIBUTE_REVERSE });

    		// 주문번호
    		printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.reno'), this.reno]) });

    		// 총 주문금액
    		const tamt = this.tAmount + this.$t('unitTxt.currency');
    		printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.tsumamount'), tamt]) });

    		// 주문일자
    		printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.condate'), this.GetDateFormat('01', this.conDate)]) });

    		// 납기요청
    		printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.duedate'), this.GetDateFormat('01', this.dueDate) + '\n']) });

			// 구분선
    		printText.push({ text: "-".repeat(48) });

    		// 주문내역
    		printText.push({ text: this.$t('orderInfo.orderList') + '\n', textAlignment: btprinter.ALIGNMENT_LEFT, textAttribute: btprinter.ATTRIBUTE_REVERSE });

    		// 주문 아이템 리스트
    		this.orderItemList.forEach(item => {
      		printText.push({ text: btprinter.setStrBlank([item.itemname, this.rstatus == 1 ? this.$t('orderInfo.delComplete') : this.$t('orderInfo.returnCompleted') ]) + '\n', textAlignment: btprinter.ALIGNMENT_LEFT, textAttribute: btprinter.ATTRIBUTE_NORMAL });

      if (item.chk_pricenone == 1) {
        printText.push({ text: this.$t('title.priceone') + '\n', textAlignment: btprinter.ALIGNMENT_LEFT, textAttribute: btprinter.ATTRIBUTE_NORMAL });
      }

      printText.push({ text: 'ㄴ' +  item.sname + ' (' + item.itemcode + ')\n', textAlignment: btprinter.ALIGNMENT_LEFT, textAttribute: btprinter.ATTRIBUTE_NORMAL });

      if (item.rstatus == 'R') {
        printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.orderQty'), item.qty + item.pc_name]) });
        printText.push({ text: btprinter.setStrBlank([this.$t('iteminfo.unitprice4'), this.numComma(item.unitprice) + this.$t('unitTxt.currency')]) });

        if (item.boxorder != '0') {
          printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.boxQty'), item.boxqty + item.boxunitnm + ' ' + item.pcsqty + item.pc_name]) });
        }

        printText.push({ text: btprinter.setStrBlank([this.$t('iteminfo.gamt'), this.numComma(item.amount * this.rstatus) + this.$t('unitTxt.currency')]) });
        printText.push({ text: btprinter.setStrBlank([this.$t('iteminfo.vat'), this.numComma(item.vatamt * this.rstatus) + this.$t('unitTxt.currency')]) });
        printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.tamount'), this.numComma(item.tamount * this.rstatus) + this.$t('unitTxt.currency')]) });
      } else if (item.rstatus == 'D') {
        printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.delQty'), item.qty + item.pc_name]) });
        printText.push({ text: btprinter.setStrBlank([this.$t('iteminfo.unitprice4'), this.numComma(item.del_unitprice) + this.$t('unitTxt.currency')]) });

        if (item.boxorder != '0') {
          printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.boxQty'), item.del_boxqty + item.boxunitnm + ' ' + item.del_pcsqty + item.pc_name]) });
        }

        printText.push({ text: btprinter.setStrBlank([this.$t('iteminfo.gamt'), this.numComma(item.del_amount) + this.$t('unitTxt.currency')]) });
        printText.push({ text: btprinter.setStrBlank([this.$t('iteminfo.vat'), this.numComma(item.del_vatamt) + this.$t('unitTxt.currency')]) });
        printText.push({ text: btprinter.setStrBlank([this.$t('orderInfo.delTamount'), this.numComma(item.del_tamount) + this.$t('unitTxt.currency') + "\n"]) });
	}
    });
    printText.push({ text: "-".repeat(48) +"\n" });

	printText.push({text : '콤웨어\n서울특별시 금천구 가산동 60-3\n\n\n', textAlignment:btprinter.ALIGNMENT_RIGHT});

    console.log(printText); // 가공된 데이터 확인
    return printText;

		},
		sendSample() {
			//console.log(this.cData);
			if('messageHandler' in window)
			{
				const printData = this.makeSample();
				window.messageHandler.postMessage(window.messageHandler.postMessage(JSON.stringify(printData)));
				//window.messageHandler.postMessage(JSON.stringify(printData));
			}
			this.makeSample();
		},
		makeSample() { 
			//바코드 유무 
			const printText = [{'barcode' : true},
    {'text': 'Alignment left\n', 'textAlignment': btprinter.ALIGNMENT_LEFT, 'textAttribute': btprinter.ATTRIBUTE_NORMAL},
    {'text': 'Alignment Center\n', 'textAlignment': btprinter.ALIGNMENT_CENTER, 'textAttribute': btprinter.ATTRIBUTE_NORMAL},
    {'text': 'Alignment Right\n', 'textAlignment': btprinter.ALIGNMENT_RIGHT, 'textAttribute': btprinter.ATTRIBUTE_NORMAL},
    {'text': 'Font Size 1\n', 'textAttribute': btprinter.ATTRIBUTE_NORMAL, 'textSize': 1},
    {'text': 'Font Size 2\n', 'textAttribute': btprinter.ATTRIBUTE_NORMAL, 'textSize': 2},
    {'text': 'Font Reverse\n', 'textAttribute': btprinter.ATTRIBUTE_REVERSE},
    {'text': 'Font Bold\n', 'textAttribute': btprinter.ATTRIBUTE_REVERSE},
    {'text': 'Font Underline\n', 'textAttribute': btprinter.ATTRIBUTE_UNDERLINE},
    {'text': '\u{1B}|0fT Font A\n'},
    {'text': '\u{1B}|1fT Font A\n'},
    {'text': '\u{1B}|2fT Font A\n'},
    {'text': '\u{1B}|2hC Font width magnification x2\n'},
    {'text': '\u{1B}|4hC Font width magnification x4\n'},
    {'text': '\u{1B}|8hC Font width magnification x8\n'},
    {'text': '\u{1B}|2vC Font height magnification x2\n'},
    {'text': '\u{1B}|4vC Font height magnification x4\n'},
    {'text': '\u{1B}|8vC Font height magnification x8\n'},
  ];
			printText.push({data:'https://www.comware.co.kr/solution/baljugo',  symbology : btprinter.BARCODE_TYPE_QRCODE, alignment: btprinter.ALIGNMENT_CENTER});

			printText.push({data: '123456789012' , symbology : btprinter.BARCODE_TYPE_ITF, alignment : btprinter.ALIGNMENT_CENTER })

			console.log(printText); // 가공된 데이터 확인
    		return printText;
		},
```
