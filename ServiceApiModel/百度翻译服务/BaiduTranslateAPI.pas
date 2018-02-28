{ * �ⲿapi֧�֣��ٶȷ������http֧��                                          * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ ****************************************************************************** }
unit BaiduTranslateAPI;

interface

uses Classes, CoreClasses, PascalStrings, UnicodeMixedLib, MemoryStream64, JsonDataObjects;

var
  // ʹ�����е�ַ����ٶȷ���
  // http://api.fanyi.baidu.com

  // ����apiʹ���ʸ�����ѵģ���������ɺ�
  // �ڿ����߿�̨��ҳ���ῴ��appid����Կ��ճ�������漴��

  // �ٶȷ���ӿڿ������ڿͻ��ˣ�Ҳ��������FMX
  // �����ڿͻ���ֱ��ʹ�÷������������Կ��ʧ���Լ��޷���¼�û��ķ�����ʷ�ͼ��ٷ��룬���ҷ��������׳��꣬��ɲ��ɿ��Ƶı��۷�

  // �ٶȵĹ���������Կ
  BaiduTranslate_Appid: string = '2015063000000001';
  BaiduTranslate_Key  : string = '12345678';

  // �ӿڰٶȷ�������ȫ�߳�
  // ϵͳÿ���̻߳�ռ��1-4M(linux X64����8M)�Ķ�ջ�ռ䣬�����ź�̨��Դ
  // �̶߳�ջ�ļ���ժҪ�����вο����н���
  // http://blog.csdn.net/cherish_2012/article/details/45073399
  BaiduTranslate_MaxSafeThread: Integer = 100; // 100�Ǻ������õ�linux������

type
  TTranslateLanguage = (
    tL_auto, // �Զ�
    tL_zh,   // ����
    tL_en,   // Ӣ��
    tL_yue,  // ����
    tL_wyw,  // ������
    tL_jp,   // ����
    tL_kor,  // ����
    tL_fra,  // ����
    tL_spa,  // ��������
    tL_th,   // ̩��
    tL_ara,  // ��������
    tL_ru,   // ����
    tL_pt,   // ��������
    tL_de,   // ����
    tL_it,   // �������
    tL_el,   // ϣ����
    tL_nl,   // ������
    tL_pl,   // ������
    tL_bul,  // ����������
    tL_est,  // ��ɳ������
    tL_dan,  // ������
    tL_fin,  // ������
    tL_cs,   // �ݿ���
    tL_rom,  // ����������
    tL_slo,  // ˹����������
    tL_swe,  // �����
    tL_hu,   // ��������
    tL_cht,  // ��������
    tL_vie); // Խ����

  TTranslateCompleteProc = reference to procedure(UserData: Pointer; Success: Boolean; sour, dest: TPascalString);

procedure BaiduTranslateWithHTTP(UsedSSL: Boolean;
  sourLanguage, desLanguage: TTranslateLanguage;
  text: TPascalString;
  UserData: Pointer;
  OnResult: TTranslateCompleteProc);

threadvar BaiduTranslateTh: Int64;

implementation

uses SysUtils, IDHttp;

type
  THTTPGetTh = class;

  THTTPSyncIntf = class
    th: THTTPGetTh;
    url: string;
    HTTP: TIdCustomHTTP;
    m64: TMemoryStream64;
    UserData: Pointer;
    RepleatGet: Integer;
    OnResult: TTranslateCompleteProc;

    procedure AsyncGet;
  end;

  THTTPGetTh = class(TThread)
    syncIntf: THTTPSyncIntf;
    procedure execute; override;
  end;

procedure THTTPSyncIntf.AsyncGet;
var
  js       : TJsonObject; // ��Ƶ�ʷ������ֶ���������Ҫ��JsonDataObjects������ȱ���ǲ�֧��fpc���������ȶ��Ϳ���
  ja       : TJsonArray;
  I        : Integer;
  Success  : Boolean;
  sour, dst: TPascalString;
begin
  try
    HTTP.ReadTimeout := 2000;
    HTTP.Get(url, m64);
  except
    inc(RepleatGet);

    // ��������������https�����ᷢ�����ߺ��쳣���������������������ظ�5�εķ�ʽ������ȡ��ֱ���ɹ�
    if RepleatGet < 5 then
      begin
        AsyncGet;
      end
    else
      begin
        th.Synchronize(
          procedure
          begin
            OnResult(UserData, False, '', '');
          end);
      end;
    exit;
  end;
  m64.Position := 0;
  js := TJsonObject.Create;
  try
      js.LoadFromStream(m64, TEncoding.UTF8, True);
  except
    DisposeObject([js]);
    OnResult(UserData, False, '', '');
    exit;
  end;

  Success := False;
  sour := '';
  dst := '';

  try
    // �Է���������ȫ���
    if js.IndexOf('trans_result') >= 0 then
      begin
        ja := js.A['trans_result'];
        if ja.Count > 0 then
          begin
            for I := 0 to ja.Count - 1 do
              begin
                Success := True;
                if I = 0 then
                  begin
                    sour := ja[I].S['src'];
                    dst := ja[I].S['dst'];
                  end
                else
                  begin
                    sour.Append(#13#10 + ja[I].S['src']);
                    dst.Append(#13#10 + ja[I].S['dst']);
                  end;
              end;
          end;
      end;
  except
    DisposeObject([js]);
    th.Synchronize(
      procedure
      begin
        OnResult(UserData, False, '', '');
      end);
    exit;
  end;

  th.Synchronize(
    procedure
    begin
      OnResult(UserData, Success, sour, dst);
    end);

  DisposeObject([js]);

  DisposeObject([m64]);
end;

procedure THTTPGetTh.execute;
begin
  inc(BaiduTranslateTh);
  FreeOnTerminate := True;
  syncIntf.HTTP := TIdCustomHTTP.Create(nil);
  try
      syncIntf.AsyncGet;
  finally
    // ��ȫ����
    try
        DisposeObject(syncIntf.HTTP);
    except
    end;
    DisposeObject(syncIntf);
    dec(BaiduTranslateTh);
  end;
end;

function TranslateLanguage2Token(t: TTranslateLanguage): TPascalString; inline;
begin
  // ���ѱ�ע����������
  case t of
    tL_auto: Result := 'auto'; // auto�����http�������������������ԣ���������
    tL_zh: Result := 'zh';     // ����
    tL_en: Result := 'en';     // Ӣ��
    tL_yue: Result := 'yue';   // ����
    tL_wyw: Result := 'wyw';   // ������
    tL_jp: Result := 'jp';     // ����
    tL_kor: Result := 'kor';   // ����
    tL_fra: Result := 'fra';   // ����
    tL_spa: Result := 'spa';   // ��������
    tL_th: Result := 'th';     // ̩��
    tL_ara: Result := 'ara';   // ��������
    tL_ru: Result := 'ru';     // ����
    tL_pt: Result := 'pt';     // ��������
    tL_de: Result := 'de';     // ����
    tL_it: Result := 'it';     // �������
    tL_el: Result := 'el';     // ϣ����
    tL_nl: Result := 'nl';     // ������
    tL_pl: Result := 'pl';     // ������
    tL_bul: Result := 'bul';   // ����������
    tL_est: Result := 'est';   // ��ɳ������
    tL_dan: Result := 'dan';   // ������
    tL_fin: Result := 'fin';   // ������
    tL_cs: Result := 'cs';     // �ݿ���
    tL_rom: Result := 'rom';   // ����������
    tL_slo: Result := 'slo';   // ˹����������
    tL_swe: Result := 'swe';   // �����
    tL_hu: Result := 'hu';     // ��������
    tL_cht: Result := 'cht';   // ��������
    tL_vie: Result := 'vie';   // Խ����
    else
      Result := 'auto'; // auto�����http�������������������ԣ���������
  end;
end;

procedure BaiduTranslateWithHTTP(UsedSSL: Boolean; sourLanguage, desLanguage: TTranslateLanguage; text: TPascalString; UserData: Pointer; OnResult: TTranslateCompleteProc);
var
  salt    : Integer;
  httpurl : TPascalString;
  soursign: TPascalString;
  lasturl : TPascalString;
  intf    : THTTPSyncIntf;
  th      : THTTPGetTh;
begin
  if text.Len > 2000 then
    begin
      OnResult(UserData, False, '', '');
      exit;
    end;
  salt := umlRandomRange(32767, 1024 * 1024 * 2);
  soursign := BaiduTranslate_Appid + text + intToStr(salt) + BaiduTranslate_Key;

  if UsedSSL then
      httpurl := 'https://api.fanyi.baidu.com/api/trans/vip/translate'
  else
      httpurl := 'http://api.fanyi.baidu.com/api/trans/vip/translate';

  lasturl.text := httpurl + '?' +
    'q=' + umlURLEncode(text) +
    '&from=' + TranslateLanguage2Token(sourLanguage) +
    '&to=' + TranslateLanguage2Token(desLanguage) +
    '&appid=' + BaiduTranslate_Appid +
    '&salt=' + intToStr(salt) +
    '&sign=' + umlStringMD5Char(soursign);
  intf := THTTPSyncIntf.Create;
  intf.th := THTTPGetTh.Create;
  intf.th.syncIntf := intf;
  intf.url := lasturl;
  intf.HTTP := nil;
  intf.m64 := TMemoryStream64.Create;
  intf.UserData := UserData;
  intf.RepleatGet := 0;
  intf.OnResult := OnResult;
  intf.th.Suspended := False;
end;

end.
