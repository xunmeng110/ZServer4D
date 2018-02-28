unit ZDBBatchDataServiceFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  DoStatusIO,
  ZDBEngine, ZDBLocalManager,
  CommunicationFramework_Server_CrossSocket,
  CommunicationFramework_Server_ICS,
  CommunicationFramework_Server_ICSCustomSocket,
  CommunicationFramework_Server_Indy, MemoryStream64, DataFrameEngine,
  JsonDataObjects, CommunicationFramework,
  CommunicationFrameworkDataStoreService, CoreClasses,
  CommunicationFrameworkDataStoreService_NoAuth,
  CommunicationFrameworkDoubleTunnelIO,
  CommunicationFrameworkDataStoreServiceCommon, UnicodeMixedLib,
  CommunicationFrameworkDataStoreService_VirtualAuth,
  CommunicationFrameworkDoubleTunnelIO_VirtualAuth;

type
  TMyDataStoreService = class(TDataStoreService_VirtualAuth)
  protected
    procedure UserLoginSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth); override;
    procedure UserLinkSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth); override;
    procedure UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth); override;
  end;

  TZDBBatchDataServiceForm = class(TForm)
    StatusMemo: TMemo;
    WatchMemo: TMemo;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { Private declarations }
    procedure MyCustomJsonQuery(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
    procedure MyCustomJsonAnalysisQuery(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
  public
    { Public declarations }
    RecvTunnel, SendTunnel: TCommunicationFrameworkServer;
    DBService             : TMyDataStoreService;
    procedure DoStatusNear(AText: string; const ID: Integer);
  end;

var
  ZDBBatchDataServiceForm: TZDBBatchDataServiceForm;

implementation

{$R *.dfm}


procedure TMyDataStoreService.UserLinkSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth);
begin
  DoStatus('�û� %s �����������ӳɹ�', [UserDefineIO.UserID]);
  inherited;
end;

procedure TMyDataStoreService.UserLoginSuccess(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth);
begin
  DoStatus('�û� %s ��¼�ɹ�', [UserDefineIO.UserID]);
  inherited;
end;

procedure TMyDataStoreService.UserOut(UserDefineIO: TPeerClientUserDefineForRecvTunnel_VirtualAuth);
begin
  DoStatus('�û� %s ����', [UserDefineIO.UserID]);
  inherited;
end;

procedure TZDBBatchDataServiceForm.DoStatusNear(AText: string; const ID: Integer);
begin
  StatusMemo.Lines.Add(AText);
end;

procedure TZDBBatchDataServiceForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  RecvTunnel.StopService;
  SendTunnel.StopService;
end;

procedure TZDBBatchDataServiceForm.MyCustomJsonQuery(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
var
  key  : string;
  value: string;
  j    : TDBEngineJson;
begin
  // query�Ǹ������ʵĴ���Ƶ�ʣ�ÿ������¼�������������
  // ��дquery��һ��Ҫע���Ż����������ٵĴ���ʵ�������Ա�
  // ����������query�д���ʵ����󣬸�Ƶ�ʴ�������̫�ϲ�ѯЧ��
  if not qState.IsJson then
      exit;

  // �����ݿ��ȡһ��json����
  j := qState.DBEng.GetJson(qState);

  // ���������ܻ�ȡ��ȫ���
  if not dPipe.Values.Exists('Key') then
      exit;
  if not dPipe.Values.Exists('Value') then
      exit;

  // dPipe�е�Values���Կͻ��˷����Ĳ�ѯ�������������ݿ�
  key := dPipe.Values.GetDefaultValue('Key', '');

  // dPipe�е�Values���Կͻ��˷����Ĳ�ѯ�������������ݿ�
  value := dPipe.Values.GetDefaultValue('Value', '');

  Allowed := umlMultipleMatch(value, j.S[key]);
end;

procedure TZDBBatchDataServiceForm.MyCustomJsonAnalysisQuery(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean);
var
  key  : string;
  value: Integer;
  j    : TDBEngineJson;
begin
  // query�Ǹ������ʵĴ���Ƶ�ʣ�ÿ������¼�������������
  // ��дquery��һ��Ҫע���Ż����������ٵĴ���ʵ�������Ա�
  // ����������query�д���ʵ����󣬸�Ƶ�ʴ�������̫�ϲ�ѯЧ��
  if not qState.IsJson then
      exit;

  // �����ݿ��ȡһ��json����
  j := qState.DBEng.GetJson(qState);

  // ���������ܻ�ȡ��ȫ���
  if not dPipe.Values.Exists('Key') then
      exit;
  if not dPipe.Values.Exists('Value') then
      exit;

  // dPipe�е�Values���Կͻ��˷����Ĳ�ѯ�������������ݿ�
  key := dPipe.Values.GetDefaultValue('Key', '');

  // dPipe�е�Values���Կͻ��˷����Ĳ�ѯ�������������ݿ�
  value := dPipe.Values.GetDefaultValue('Value', 0);

  Allowed := value = j.I[key];
end;

procedure TZDBBatchDataServiceForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatusNear);
  RecvTunnel := TCommunicationFramework_Server_CrossSocket.Create;

  SendTunnel := TCommunicationFramework_Server_CrossSocket.Create;

  DBService := TMyDataStoreService.Create(RecvTunnel, SendTunnel);
  DBService.RegisterCommand;
  DBService.ZDBLocal.LoadDB(False);

  DBService.RegisterQueryCall('MyCustomQuery').OnPipelineQuery := MyCustomJsonQuery;
  DBService.RegisterQueryCall('MyCustomAnalysis').OnPipelineQuery := MyCustomJsonAnalysisQuery;

  RecvTunnel.StartService('', 10099);
  SendTunnel.StartService('', 10098);

  RecvTunnel.QuietMode := True;
  SendTunnel.QuietMode := True;

  DBService.SwitchAsMaxSafe;
end;

procedure TZDBBatchDataServiceForm.FormDestroy(Sender: TObject);
begin
  DeleteDoStatusHook(self);
  DisposeObject([DBService, RecvTunnel, SendTunnel]);
end;

procedure TZDBBatchDataServiceForm.Timer1Timer(Sender: TObject);
begin
  DBService.Progress;
end;

procedure TZDBBatchDataServiceForm.Timer2Timer(Sender: TObject);
var
  I  : Integer;
  lst: TCoreClassListForObj;
  db : TZDBStoreEngine;
  pl : TZDBPipeline;
begin
  lst := TCoreClassListForObj.Create;
  DBService.ZDBLocal.GetDBList(lst);

  WatchMemo.Lines.BeginUpdate;
  WatchMemo.Lines.Clear;

  I := Round(DBService.PostCounterOfPerSec);

  WatchMemo.Lines.Add(Format('ƽ��ÿ���յ� %d ����ɾ�Ĳ���', [I]));

  WatchMemo.Lines.Add('��Ծ���ݿ�...');
  for I := 0 to lst.Count - 1 do
    begin
      db := TZDBStoreEngine(lst[I]);
      WatchMemo.Lines.Add(Format('�� %s ��Ŀ:%d ��С:%s ���� %s', [db.name, db.Count, umlSizeToStr(db.DBEngine.Size).Text, db.CacheAnnealingState]));
    end;

  lst.Clear;
  WatchMemo.Lines.Add('���ڹ����Ĳ�ѯ����...');
  DBService.ZDBLocal.GetPipeList(lst);
  for I := 0 to lst.Count - 1 do
    begin
      pl := TZDBPipeline(lst[I]);
      WatchMemo.Lines.Add(Format('���� %s ÿ����ȡ%d��', [pl.PipelineName, Round(pl.QueryCounterOfPerSec)]));
    end;

  DisposeObject(lst);
  WatchMemo.Lines.EndUpdate;
end;

end.
