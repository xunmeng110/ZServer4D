unit FMXBatchDataClientFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.TabControl, FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation,
  FMX.DialogService, FMX.Layouts,
  CommunicationFrameworkDataStoreService, ZDBEngine,
  ZDBLocalManager, CommunicationFramework_Client_Indy,
  CommunicationFramework, CoreClasses, DoStatusIO, FMX.ScrollBox, FMX.Memo,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, PascalStrings, MemoryStream64, UnicodeMixedLib,
  CommunicationFrameworkDataStoreService_VirtualAuth,
  CommunicationFrameworkDoubleTunnelIO_VirtualAuth, FileBuffOfCode,
  FMX.ListBox, FMX.Objects, DataFrameEngine, JsonDataObjects;

type
  TMyDataStoreClient = class(TDataStoreClient_VirtualAuth)
  protected
    procedure ClientDisconnect(Sender: TCommunicationFrameworkClient); override;

  end;

  TFMXBatchDataClientForm = class(TForm)
    TabControl: TTabControl;
    LoginTabItem: TTabItem;
    Layout1: TLayout;
    Layout2: TLayout;
    Label1: TLabel;
    UserIDEdit: TEdit;
    Layout3: TLayout;
    Label2: TLabel;
    PasswdEdit: TEdit;
    LoginBtn: TButton;
    Layout4: TLayout;
    Label3: TLabel;
    ServerEdit: TEdit;
    Timer1: TTimer;
    StatusMemo: TMemo;
    OfflineTabItem: TTabItem;
    Layout5: TLayout;
    DisconnectButton: TButton;
    DBOperationDataTabItem: TTabItem;
    Gen1JsonButton: TButton;
    DisconnectCheckTimer: TTimer;
    Layout6: TLayout;
    Label4: TLabel;
    JsonDestDBEdit: TEdit;
    ResultTabItem: TTabItem;
    QueryJsonButton: TButton;
    Layout7: TLayout;
    Label5: TLabel;
    JsonKeyEdit: TEdit;
    Layout8: TLayout;
    Label6: TLabel;
    JsonValueEdit: TEdit;
    ResetJsonDBButton: TButton;
    AnalysisJsonButton: TButton;
    Layout9: TLayout;
    Label7: TLabel;
    AnalysisDestDBEdit: TEdit;
    PictureListBox: TListBox;
    Layout10: TLayout;
    Label8: TLabel;
    ResultListBox: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoginBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure DisconnectButtonClick(Sender: TObject);
    procedure DisconnectCheckTimerTimer(Sender: TObject);
    procedure Gen1JsonButtonClick(Sender: TObject);
    procedure QueryJsonButtonClick(Sender: TObject);
    procedure ResetJsonDBButtonClick(Sender: TObject);
    procedure AnalysisJsonButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    RecvTunnel, SendTunnel: TCommunicationFrameworkClient;
    DBClient              : TMyDataStoreClient;
    procedure DoStatusNear(AText: string; const ID: Integer);
  end;

var
  FMXBatchDataClientForm: TFMXBatchDataClientForm;

implementation

{$R *.fmx}


procedure TMyDataStoreClient.ClientDisconnect(Sender: TCommunicationFrameworkClient);
begin
  FMXBatchDataClientForm.TabControl.ActiveTab := FMXBatchDataClientForm.LoginTabItem;
  inherited;
end;

procedure TFMXBatchDataClientForm.AnalysisJsonButtonClick(Sender: TObject);
var
  vl: TDBEngineVL; // TDBEngineVL�Ǹ�key-value���ݽṹԭ��
begin
  vl := TDBEngineVL.Create;
  vl['Key'] := 'RandomValue';
  vl['Value'] := 1; // ����Ҫ����ͳ�Ƶ�ֵΪ1

  // ͳ�ƺͷ���ʹ�÷�������ע��� MyCustomAnalysis ���������д���
  // ͳ�ƺͷ����ڷ������˽���ʱ�����Խ������ƥ�䣬ͼ�������ԣ��ı������ԣ����������Եȵȣ����Ƕ����ڲ��л�ƽ̨�й�������Ȼ���㻹��Ҫ��Ӧ���㷨ģ��֧��
  // ͳ�ƺͷ��������ڷ�������ִ̬�У�����Ƭ���������������ͳ�ƴ������ݿ⣬���ú����ԣ�
  // ��������������ִ�����ͳ�ƺͷ���������ͨ���¼�������step to step�Ĳ�����ZDB��ȫ���ݺ�֧��������������
  // �ǲ��Ǹо��͵���һ����
  DBClient.QueryDB(
    'MyCustomAnalysis',      // MyCustomAnalysis �ڷ�����ע���ʵ��
    False,                   // ������Ƭ�Ƿ�ͬ�����ͻ��ˣ���Ϊ���ǵ�ͳ��׷����ǽ�������ﲻ��Ҫͬ�����÷�����ȥ�ɣ�����ֻ��Ҫ������¼���ָ��ͳ����ɺ��ʲô��
    True,                    // �Ƿ񽫲�ѯ���д�뵽Output���ݿ⣬���Output�൱����select����ͼ������Output��Copy
    False,                   // output����Ϊ�ڴ����ݿ⣬�����False����ѯ��output����һ��ʵ���ļ����д洢
    False,                   // �Ƿ����ѯ�������ʼ��
    JsonDestDBEdit.Text,     // ��ѯ�����ݿ�����
    AnalysisDestDBEdit.Text, // ͳ�Ƶ�Output����
    1.0,                     // ��Ƭ����ʱ��,��Ϊ��ѯ����Ƶ�ʣ�ZDB�ײ���ڸ�ʱ���ڶԲ�ѯ������л����ѹ����Ȼ���ٷ��͹���,0�Ǽ�ʱ����
    0,                       // ���ȴ��Ĳ�ѯʱ�䣬0������
    0,                       // ���ƥ���ѯ�ķ�����Ŀ����0������
    vl,                      // ���͸�MyCustomQuery�õ�KeyValue����
    nil,
    procedure(dbN, outN, pipeN: string; TotalResult: Int64)
    begin
      ResultListBox.Clear;
      // ��������ѯ���ʱ������������¼�
      DoStatus('ͳ�� %s ��� �ܹ������ %d �������ݿ�%s��', [dbN, TotalResult, outN]);
      // ͳ����ɺ�����һ���������ļ����ݿ�
      // �����ڸ��¼��п��Է����Ը����ݿ�����ٴ�ͳ�ƣ��ٴβ�ѯ���Եõ�������Ҫ�Ľ��
      // �������ﲻ����β�ѯ�ˣ�ֱ�ӽ�ͳ�ƽ�����ص����ز�����ʾ
      if TotalResult > 0 then
          DBClient.DownloadDB(False, outN,
          procedure(dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64)
          var
            js: TJsonObject;
            litm: TListBoxItem;
          begin
            // ��������ѯ����������������ݷ���
            // ���¼�����������ʱ�ģ����ý��������ɵ������Ҫ�ݴ��ѯ������ݣ�������������
            js := TJsonObject.Create;
            js.LoadFromStream(DataSour);
            litm := TListBoxItem.Create(ResultListBox);
            litm.Parent := ResultListBox;
            litm.Text := js.ToString;
            litm.Selectable := False;
            ResultListBox.AddObject(litm);
            DisposeObject(js);
          end,
          procedure(dbN, outN, pipeN: string; TotalResult: Int64)
          begin
            // ��Ϊ���������ͳ�ƽ����������������Ҫ���ͳ�����ݿ��ˣ����ڣ����ǽ�ɾ����
            // ע�⣺���ͳ�ƿ����ڱ�ĳ�����߷��ʣ������ɾ���ͻ����
            // Ҫ��������⣬������ͳ��ʱ��ֻ��Ҫȷ��ͳ��������ļ����ݿ���Ψһ��
            DBClient.CloseDB(dbN, True);

            DoStatus('ͳ�ƽ�� %s ������� �ܹ� %d ��', [dbN, TotalResult]);
            TabControl.ActiveTab := ResultTabItem;
          end);
    end);

  DisposeObject(vl);
end;

procedure TFMXBatchDataClientForm.DisconnectButtonClick(Sender: TObject);
begin
  DBClient.Disconnect;
end;

procedure TFMXBatchDataClientForm.DisconnectCheckTimerTimer(
  Sender: TObject);
begin
  // ��Ϊ��ƽ̨�����⣬indy��ios�Ͱ�׿ƽ̨�ײ㶼��֧�ֶ����¼�
  // �����ֶ�������״̬
  // �����ӳɹ������Ǽ���һ����ʱ����ѭ��������
  if not DBClient.Connected then
    begin
      DBClient.RecvTunnel.TriggerDoDisconnect;
      DisconnectCheckTimer.Enabled := False;
    end;
end;

procedure TFMXBatchDataClientForm.DoStatusNear(AText: string;
const ID: Integer);
begin
  StatusMemo.Lines.Add(AText);
  StatusMemo.GoToTextEnd;
end;

procedure TFMXBatchDataClientForm.FormCreate(Sender: TObject);
type
  TGetStreamProc = procedure(Output: TStream);
  procedure RegisterFileStream(MD5Text: string; OnProc: TGetStreamProc; FileName: string);
  var
    m   : TMemoryStream64;
    img : TImage;
    litm: TListBoxItem;
  begin
    m := TMemoryStream64.Create;
    OnProc(m);

    litm := TListBoxItem.Create(PictureListBox);
    litm.Parent := PictureListBox;
    litm.Selectable := True;
    img := TImage.Create(litm);
    img.Parent := litm;
    img.HitTest := False;
    m.Position := 0;
    img.Bitmap.LoadFromStream(m);
    img.Align := TAlignLayout.Client;
    litm.TagObject := img;
    PictureListBox.AddObject(litm);
    DisposeObject(m);
  end;

begin
  AddDoStatusHook(self, DoStatusNear);
  RecvTunnel := TCommunicationFramework_Client_Indy.Create;
  SendTunnel := TCommunicationFramework_Client_Indy.Create;
  DBClient := TMyDataStoreClient.Create(RecvTunnel, SendTunnel);
  DBClient.RegisterCommand;

  RecvTunnel.QuietMode := True;
  SendTunnel.QuietMode := True;

  RegisterFileStream('c81c2ef1794dfa4863e6ed5752201313', Get_Chrysanthemum_Stream, 'Chrysanthemum.jpg');
  RegisterFileStream('e805490727905eada15ca44916412449', Get_Desert_Stream, 'Desert.jpg');
  RegisterFileStream('7697f1b7e9cac01203bb56eb83c9dc83', Get_Hydrangeas_Stream, 'Hydrangeas.jpg');
  RegisterFileStream('e24ba2b3e84bd20cb4ecf1e8947b82bc', Get_Jellyfish_Stream, 'Jellyfish.jpg');
  RegisterFileStream('cef583eeb89487665ac09dd963787546', Get_Koala_Stream, 'Koala.jpg');
  RegisterFileStream('7bfc6de65b3020ed89c849020527bcfd', Get_Lighthouse_Stream, 'Lighthouse.jpg');
  RegisterFileStream('0223d1c7652587fbb7b3eeace6dbd5c6', Get_Penguins_Stream, 'Penguins.jpg');
  RegisterFileStream('c97ece645bdf4973adf6a645a5121da0', Get_Tulips_Stream, 'Tulips.jpg');

  PictureListBox.ListItems[0].IsSelected := True;
end;

procedure TFMXBatchDataClientForm.FormDestroy(Sender: TObject);
begin
  DeleteDoStatusHook(self);
  DisposeObject([DBClient, RecvTunnel, SendTunnel]);
end;

procedure TFMXBatchDataClientForm.Gen1JsonButtonClick(Sender: TObject);
var
  i  : Integer;
  img: TImage;
  m  : TMemoryStream64;
begin
  if PictureListBox.Selected = nil then
    begin
      TDialogService.ShowMessage('����ѡ��һ��ͼƬ');
      exit;
    end;

  img := nil;
  for i := 0 to PictureListBox.Count - 1 do
    if PictureListBox.ListItems[i].IsSelected then
      begin
        img := PictureListBox.ListItems[i].TagObject as TImage;
        break;
      end;

  if img = nil then
    begin
      TDialogService.ShowMessage('����ѡ��һ��ͼƬ');
      exit;
    end;
  m := TMemoryStream64.Create;
  img.Bitmap.SaveToStream(m);
  m.Position := 0;
  DoStatus('post size:%d md5:%s', [m.Size, umlMD5Char(m.Memory, m.Size).Text]);
  // InitDB�ĵ�һ���������ڴ����ݿ⣬�������ó�false�Ǵ���һ���ļ����ݿ�
  DBClient.InitDB(False, JsonDestDBEdit.Text);
  // 111�������Զ����picture id
  // ��Ϊ��ѯֻ����c_Json��id����̨��ѯ��������ȥ���������ǿ���ֱ�Ӱ�img�ύ��ͬһ�ű���
  DBClient.BeginAssembleStream;                                   // BeginAssembleStream�����������Batch�ύStream�����ݷ��������ݴ�buffer
  DBClient.PostAssembleStream(JsonDestDBEdit.Text, m, 111, True); // ��Stream�����ύ�����ݷ�����
  // ��Զ�����ݿ��ȡ����ύimg�����ݿ�洢��Ϣ
  DBClient.GetBatchStreamState(
    procedure(Sender: TPeerClient; ResultData: TDataFrameEngine)
    var
      bpInfo: TBigStreamBatchPostData;
      df: TDataFrameEngine;
      j: TDBEngineJson;
    begin
      if ResultData.Count > 0 then
        begin
          // ��������ύ��Batch Stream�����ݿ����ݴ����ݣ�������ȡ�ܶ�״̬������ȡ���һ��BatchStream״̬�����ҽ���
          df := TDataFrameEngine.Create;
          ResultData.ReadDataFrame(ResultData.Count - 1, df);
          bpInfo.Decode(df);
          DisposeObject(df);
          // ����1��json����ʵ���ļ���
          j := TDBEngineJson.Create;
          j.S['myKey'] := '1';                  // �����൱�����ǵ��ճ�������
          j.L['StorePos'] := bpInfo.DBStorePos; // ���������Ǳ����ύimg�����ݿ��StorePos������Ҫ��int64�ı�������
          // randomValue������ʾͳ�ƺͷ�������
          j.i['RandomValue'] := 1;
          DBClient.PostAssembleStream(JsonDestDBEdit.Text, j);
          DisposeObject(j);
          DBClient.EndAssembleStream; // EndAssembleStream�����������Batch�ύStream�����ݷ��������ݴ�buffer
        end;
    end);
end;

procedure TFMXBatchDataClientForm.LoginBtnClick(Sender: TObject);
begin
  if not SendTunnel.Connect(ServerEdit.Text, 10099) then
      exit;
  if not RecvTunnel.Connect(ServerEdit.Text, 10098) then
      exit;

  DBClient.UserLogin(UserIDEdit.Text, PasswdEdit.Text,
    procedure(const State: Boolean)
    begin
      if State then
        begin
          DoStatus('��¼�ɹ�');
          DBClient.TunnelLink(
            procedure(const State: Boolean)
            begin
              if State then
                begin
                  DoStatus('˫ͨ�����ӳɹ�');
                  TabControl.ActiveTab := DBOperationDataTabItem;

                  // ��Ϊ��ƽ̨�����⣬indy��ios�Ͱ�׿ƽ̨�ײ㶼��֧�ֶ����¼�
                  // �����ֶ�������״̬
                  // �����ӳɹ������Ǽ���һ����ʱ����ѭ��������
                  DisconnectCheckTimer.Enabled := True;
                end;
            end);
        end;
    end);
end;

procedure TFMXBatchDataClientForm.QueryJsonButtonClick(Sender: TObject);
var
  vl: TDBEngineVL; // TDBEngineVL�Ǹ�key-value���ݽṹԭ��
begin
  vl := TDBEngineVL.Create;
  vl['Key'] := JsonKeyEdit.Text;
  vl['Value'] := JsonValueEdit.Text;

  ResultListBox.Clear;
  //
  DBClient.QueryDB('MyCustomQuery', // MyCustomQuery�ڷ�����ע���ʵ��
  True,                             // ������Ƭ�Ƿ�ͬ�����ͻ���
  False,                            // �Ƿ񽫲�ѯ���д�뵽Output���ݿ⣬���Output�൱����select����ͼ������Output��Copy
  True,                             // output����Ϊ�ڴ����ݿ⣬�����False����ѯ��output����һ��ʵ���ļ����д洢
  False,                            // �Ƿ����ѯ�������ʼ��
  JsonDestDBEdit.Text,              // ��ѯ�����ݿ�����
  '',                               // ��ѯ��Output���ƣ���Ϊ���ǲ�д��Output��������ʱ�ڴ棬������Ժ��Ե�
  1.0,                              // ��Ƭ����ʱ��,��Ϊ��ѯ����Ƶ�ʣ�ZDB�ײ���ڸ�ʱ���ڶԲ�ѯ������л����ѹ����Ȼ���ٷ��͹���,0�Ǽ�ʱ����
  0,                                // ���ȴ��Ĳ�ѯʱ�䣬0������
  0,                                // ���ƥ���ѯ�ķ�����Ŀ����0������
  vl,                               // ���͸�MyCustomQuery�õ�KeyValue����
    procedure(dbN, pipeN: SystemString; StorePos: Int64; ID: Cardinal; DataSour: TMemoryStream64)
    var
      js: TJsonObject;
      litm: TListBoxItem;
    begin
      // ��������ѯ����������������ݷ���
      // ���¼�����������ʱ�ģ����ý��������ɵ������Ҫ�ݴ��ѯ������ݣ�������������
      js := TJsonObject.Create;
      js.LoadFromStream(DataSour);
      litm := TListBoxItem.Create(ResultListBox);
      litm.Parent := ResultListBox;
      litm.Text := js.ToString;
      litm.Selectable := False;
      ResultListBox.AddObject(litm);

      // DownloadAssembleStream ������������ݷ��������ȱ����ѹ���ͼ��ܣ�Ȼ�������أ��˷��������ڹ���ͨѶ���أ����ֻ��ˣ�pc���ʻ�����������
      // FastDownloadAssembleStream��DownloadAssembleStreamһ��������FastDownloadAssembleStream���������ݴ��������ٶȸ��죬�˷�����Ҫ���ڷ��������ͨѶ
      DBClient.FastDownloadAssembleStream(JsonDestDBEdit.Text, js.L['StorePos'],
        procedure(dbN: SystemString; dStorePos: Int64; stream: TMemoryStream64)
        var
          img: TImage;
          m: TMemoryStream64;
        begin
          // stream����ʱ�ģ�������encode�����ݣ�����ʹ��DecodeOneFragment�������н���
          // ��ɺ�����M�У��ڵ��ý���ʱע���ͷ�M
          m := DecodeOneFragment(stream);
          img := TImage.Create(litm);
          img.Parent := litm;
          img.Align := TAlignLayout.Right;
          stream.Position := 0;
          //DoStatus('download size:%d md5:%s', [m.Size, umlMD5Char(m.Memory, m.Size).Text]);
          m.Position := 0;
          img.Bitmap.LoadFromStream(m);
          DisposeObject(m);
        end);

      DisposeObject(js);
    end,
    procedure(dbN, outN, pipeN: string; TotalResult: Int64)
    begin
      // ��������ѯ���ʱ������������¼�
      TabControl.ActiveTab := ResultTabItem;
      DoStatus('��ѯ %s ��� �ܹ��ҵ�ƥ�� %d ��', [dbN, TotalResult]);
    end);

  DisposeObject(vl);
end;

procedure TFMXBatchDataClientForm.ResetJsonDBButtonClick(Sender: TObject);
begin
  DBClient.ResetData(JsonDestDBEdit.Text);
  DBClient.ResetData(AnalysisDestDBEdit.Text);
end;

procedure TFMXBatchDataClientForm.Timer1Timer(Sender: TObject);
begin
  DBClient.Progress;
end;

end.
