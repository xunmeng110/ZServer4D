unit CustomProtocolFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,

  CommunicationFramework, PascalStrings,
  CommunicationFramework_Server_CrossSocket, DoStatusIO, MemoryStream64, CoreClasses,

  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdGlobal;

type
  // TPeerClientUserSpecial��ÿ���ͻ���p2p���Ӻ������ʵ���ӿ�
  // ����Ҳ����ͨ���̳�TPeerClientUserDefine�ﵽͬ���Ĺ���
  TMyPeerClientUserSpecial = class(TPeerClientUserSpecial)
  public
    myBuffer: TMemoryStream64;

    constructor Create(AOwner: TPeerClient); override;
    destructor Destroy; override;

    // ������ͬ���¼��������ڴ˴�ʵ�ֶԵ���д�����Ƭ���������������
    procedure Progress; override;
  end;

  TMyServer = class(TCommunicationFramework_Server_CrossSocket)
  public
    // �ӷ�������ȡ�ⲿ���ƻ����������ӿ�
    // �����bufferȫ������Ƭ��������
    procedure FillCustomBuffer(Sender: TPeerClient; const Th: TCoreClassThread; const Buffer: PByte; const Size: NativeInt; var Done: Boolean); override;
  end;

  TCustomProtocolForm = class(TForm)
    Memo: TMemo;
    Timer: TTimer;
    Panel1: TPanel;
    connectButton: TButton;
    WriteStringButton: TButton;
    IdTCPClient1: TIdTCPClient;
    procedure FormCreate(Sender: TObject);
    procedure connectButtonClick(Sender: TObject);
    procedure WriteStringButtonClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    myServer: TMyServer;
    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
  end;

var
  CustomProtocolForm: TCustomProtocolForm;

implementation

{$R *.dfm}


constructor TMyPeerClientUserSpecial.Create(AOwner: TPeerClient);
begin
  inherited;
  myBuffer := TMemoryStream64.Create;

end;

destructor TMyPeerClientUserSpecial.Destroy;
begin
  DisposeObject(myBuffer);

  inherited;
end;

procedure TMyPeerClientUserSpecial.Progress;
begin
  inherited;
  // ������ͬ���¼��������ڴ˴�ʵ�ֶԵ���д�����Ƭ���������������

  // �ȼ�黺�����ǲ��ǿ�
  if myBuffer.Size > 0 then
    begin
      // ������������ǿ�
      // ���Ǵ�ӡ���յ���������
      DoStatus(format('receive [%s] [%d] ', [Owner.PeerIP, Owner.ID]), myBuffer.Memory, myBuffer.Size, 16);
      // ���ǽ����յ�������ԭ�ⲻ���ķ��������ͷ�
      Owner.WriteCustomBuffer(myBuffer.Memory, myBuffer.Size);

      // ��ջ�������Ϊ��һ�δ�����׼��
      myBuffer.Clear;
    end;
end;

procedure TMyServer.FillCustomBuffer(Sender: TPeerClient; const Th: TCoreClassThread; const Buffer: PByte; const Size: NativeInt; var Done: Boolean);
begin
  // �ӷ�������ȡ�ⲿ���ƻ����������ӿ�
  // �����bufferȫ������Ƭ��������

  // �������Լ��Ķ��ƻ�Э�� doneҪ����Ϊ��true
  Done := True;

  if Size <= 0 then
      exit;

  // �����߳�״̬�ж��Ƿ�ͬ����������Ƭ������
  if Th <> nil then
      Th.Synchronize(Th,
      procedure
      begin
        // ���ǽ���Ƭ������׷��д�뵽myBuffer
        TMyPeerClientUserSpecial(Sender.UserSpecial).myBuffer.WritePtr(Buffer, Size);
      end)
  else
    begin
      // ���ǽ���Ƭ������׷��д�뵽myBuffer
      TMyPeerClientUserSpecial(Sender.UserSpecial).myBuffer.WritePtr(Buffer, Size);
    end;
end;

procedure TCustomProtocolForm.connectButtonClick(Sender: TObject);
begin
  IdTCPClient1.Connect;

  if IdTCPClient1.Connected then
      DoStatus('connect ok!');
end;

procedure TCustomProtocolForm.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(AText);
end;

procedure TCustomProtocolForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  myServer := TMyServer.Create;
  // ָ���ͻ��˵�p2pʵ���ӿ�
  myServer.PeerClientUserSpecialClass := TMyPeerClientUserSpecial;
  myServer.StartService('', 9989);
end;

procedure TCustomProtocolForm.TimerTimer(Sender: TObject);
var
  iBuf: TIdBytes;
begin
  myServer.ProgressBackground;

  if IdTCPClient1.Connected then
    begin
      // ������Է������ķ���
      if IdTCPClient1.IOHandler.InputBuffer.Size > 0 then
        begin
          // �������յ����������Ǵ�ӡ�������ķ���
          IdTCPClient1.IOHandler.InputBuffer.ExtractToBytes(iBuf);
          IdTCPClient1.IOHandler.InputBuffer.Clear;
          DoStatus(format('response ', []), @iBuf[0], length(iBuf), 16);
        end;
    end;
end;

procedure TCustomProtocolForm.WriteStringButtonClick(Sender: TObject);
var
  d: UInt64;
begin
  d := $FFFFFF1234567890;
  // ������indy�ӿ�������������һ��uint����
  IdTCPClient1.IOHandler.WriteBufferOpen;
  IdTCPClient1.IOHandler.Write(d);
  IdTCPClient1.IOHandler.WriteBufferFlush;
  IdTCPClient1.IOHandler.WriteBufferClose;
end;

end.
