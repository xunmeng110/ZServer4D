unit EzServFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  JsonDataObjects,
  CommunicationFramework,
  CommunicationFramework_Server_ICS,
  CommunicationFramework_Server_Indy,
  CommunicationFramework_Server_CrossSocket,
  DoStatusIO, CoreClasses,
  DataFrameEngine, UnicodeMixedLib, MemoryStream64;

type
  // TPeerClientUserSpecial�ǻ���ÿ�û����Ӻ��Զ�������ʵ��
  // ʹ��ʱ����ע���ͷ��ڴ�
  // TPeerClientUserDefine����Auth,DB�ȵȷ���
  // TPeerClientUserSpecial����������߼������Auth,DB������ͻʱ���Կ������ṩ����ʵ��
  TMySpecialDefine = class(TPeerClientUserSpecial)
  public
    tempStream: TMemoryStream64;
    constructor Create(AOwner: TPeerClient); override;
    destructor Destroy; override;
  end;

  TEZServerForm = class(TForm)
    Memo1: TMemo;
    StartServiceButton: TButton;
    Timer1: TTimer;
    procedure StartServiceButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatusNear(AText: string; const ID: Integer);

    procedure cmd_helloWorld_Console(Sender: TPeerClient; InData: string);
    procedure cmd_helloWorld_Stream(Sender: TPeerClient; InData: TDataFrameEngine);
    procedure cmd_helloWorld_Stream_Result(Sender: TPeerClient; InData, OutData: TDataFrameEngine);

    procedure cmd_Json_Stream(Sender: TPeerClient; InData: TDataFrameEngine);

    procedure cmd_TestMiniStream(Sender: TPeerClient; InData: TDataFrameEngine);

    procedure cmd_Test128MBigStream(Sender: TPeerClient; InData: TCoreClassStream; BigStreamTotal, BigStreamCompleteSize: Int64);

    procedure cmd_TestCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
  public
    { Public declarations }
    server: TCommunicationFramework_Server_CrossSocket;
  end;

var
  EZServerForm: TEZServerForm;

implementation

{$R *.dfm}


procedure TEZServerForm.cmd_helloWorld_Console(Sender: TPeerClient; InData: string);
begin
  DoStatus('client: %s', [InData]);
end;

procedure TEZServerForm.cmd_helloWorld_Stream(Sender: TPeerClient; InData: TDataFrameEngine);
begin
  DoStatus('client: %s', [InData.Reader.ReadString]);
end;

procedure TEZServerForm.cmd_helloWorld_Stream_Result(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
begin
  OutData.WriteString('result 654321');
end;

procedure TEZServerForm.cmd_Json_Stream(Sender: TPeerClient; InData: TDataFrameEngine);
var
  js: TJsonObject;
  ns: TStringList;
begin
  js := TJsonObject.Create;
  ns := TStringList.Create;
  InData.Reader.ReadJson(js);
  js.SaveToLines(ns);
  DoStatus(ns);
  disposeObject(ns);
end;

procedure TEZServerForm.cmd_TestMiniStream(Sender: TPeerClient; InData: TDataFrameEngine);
var
  ms: TMemoryStream;
begin
  ms := TMemoryStream.Create;
  InData.Reader.ReadStream(ms);

  DoStatus(umlMD5Char(ms.Memory, ms.Size).Text);

  disposeObject(ms);
end;

procedure TEZServerForm.cmd_Test128MBigStream(Sender: TPeerClient; InData: TCoreClassStream; BigStreamTotal, BigStreamCompleteSize: Int64);
var
  tempStream: TMemoryStream64;
begin
  tempStream := TMySpecialDefine(Sender.UserSpecial).tempStream;
  tempStream.CopyFrom(InData, InData.Size);

  // bigstream complete
  if tempStream.Size = BigStreamTotal then
    begin
      Sender.Print('bigsteram finish');
      Sender.Print('bigsteram md5:' + umlMD5Char(tempStream.Memory, tempStream.Size).Text);
      tempStream.Clear;
    end;
end;

procedure TEZServerForm.cmd_TestCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
begin
  Sender.Print('Complete buffer md5: %s', [umlMD5String(InData, DataSize).Text]);
end;

procedure TEZServerForm.DoStatusNear(AText: string; const ID: Integer);
begin
  Memo1.Lines.Add(AText);
end;

procedure TEZServerForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatusNear);
  server := TCommunicationFramework_Server_CrossSocket.Create;
  server.PeerClientUserSpecialClass := TMySpecialDefine;

  // �������completeBuffer������ֻ���ڲ��ԣ��������з�����������һ���4M�Ϳ�����
  server.MaxCompleteBufferSize := 128 * 1024 * 1024;

  server.RegisterDirectConsole('helloWorld_Console').OnExecute := cmd_helloWorld_Console;
  server.RegisterDirectStream('helloWorld_Stream').OnExecute := cmd_helloWorld_Stream;
  server.RegisterStream('helloWorld_Stream_Result').OnExecute := cmd_helloWorld_Stream_Result;

  server.RegisterDirectStream('Json_Stream').OnExecute := cmd_Json_Stream;

  server.RegisterDirectStream('TestMiniStream').OnExecute := cmd_TestMiniStream;
  server.RegisterBigStream('Test128MBigStream').OnExecute := cmd_Test128MBigStream;

  // ע��Completebufferָ��
  server.RegisterCompleteBuffer('TestCompleteBuffer').OnExecute := cmd_TestCompleteBuffer;
end;

procedure TEZServerForm.FormDestroy(Sender: TObject);
begin
  disposeObject(server);
  DeleteDoStatusHook(self);
end;

procedure TEZServerForm.StartServiceButtonClick(Sender: TObject);
begin
  // ����CrosssSocket�ٷ��ĵ������ַ������Ϊ�գ���IPV6+IPV4
  if server.StartService('', 9818) then
      DoStatus('start service success')
  else
      DoStatus('start service failed!')
end;

procedure TEZServerForm.Timer1Timer(Sender: TObject);
begin
  server.ProgressBackground;
end;

{ TMySpecialDefine }

constructor TMySpecialDefine.Create(AOwner: TPeerClient);
begin
  inherited Create(AOwner);
  tempStream := TMemoryStream64.Create;
end;

destructor TMySpecialDefine.Destroy;
begin
  DoStatus('%s disconnect', [Owner.GetPeerIP]);
  disposeObject(tempStream);
  inherited Destroy;
end;

end.
