unit zsGatewayMiniServConfigureFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  System.IOUtils,
  ShellApi, TLHelp32,
  CoreClasses, MemoryStream64, ObjectDataManager, TextDataEngine, UnicodeMixedLib,
  PascalStrings, DoStatusIO, ItemStream, NotifyObjectBase, DataFrameEngine,
  CommunicationFramework,
  CommunicationFramework_Server_CrossSocket,
  CommunicationFramework_Server_ICSCustomSocket;

type
  TExecThread = class(TThread)
  public
    FileName                       : umlString;
    ExecCode                       : DWORD;
    SA                             : TSecurityAttributes;
    SI                             : TStartupInfo;
    PI                             : TProcessInformation;
    StdOutPipeRead, StdOutPipeWrite: THandle;

    procedure Execute; override;
  end;

  TzsGatewayMiniServConfigureForm = class(TForm)
    CfgPageControl: TPageControl;
    ServTabSheet: TTabSheet;
    Label2: TLabel;
    SharePortComboBox: TComboBox;
    NatPortEdit: TLabeledEdit;
    WebPortEdit: TLabeledEdit;
    ListView: TListView;
    AddItmButton: TButton;
    StartServerListenButton: TButton;
    AboutButton: TButton;
    DeleteItmButton: TButton;
    TokenEdit: TLabeledEdit;
    RandomTokenButton: TButton;
    X86RadioButton: TRadioButton;
    x64RadioButton: TRadioButton;
    Memo: TMemo;
    saveButton: TButton;
    sysProcessTimer: TTimer;
    RemoteConfigurePortEdit: TLabeledEdit;
    EnabledRemoteConfigureCheckBox: TCheckBox;
    Label1: TLabel;
    IPV6CheckBox: TCheckBox;
    MinimizedToTaskButton: TButton;
    GatewayTrayIcon: TTrayIcon;
    NetworkTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure AddItmButtonClick(Sender: TObject);
    procedure DeleteItmButtonClick(Sender: TObject);
    procedure RandomTokenButtonClick(Sender: TObject);
    procedure StartServerListenButtonClick(Sender: TObject);
    procedure AboutButtonClick(Sender: TObject);
    procedure saveButtonClick(Sender: TObject);
    procedure sysProcessTimerTimer(Sender: TObject);
    procedure EnabledRemoteConfigureCheckBoxClick(Sender: TObject);
    procedure GatewayTrayIconClick(Sender: TObject);
    procedure MinimizedToTaskButtonClick(Sender: TObject);
    procedure NetworkTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    DBEng       : TObjectDataManagerOfCache;
    Configure   : TSectionTextData;
    servTh      : TExecThread;
    ProgressPost: TNProgressPostWithCadencer;

    ConfigureService: TCommunicationFrameworkServer;

    procedure cmd_GetConfigure(Sender: TPeerClient; InData, OutData: TDataFrameEngine);

    procedure LoadConfig;
    procedure SaveConfigAsMemory;
    procedure SaveConfig;

    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
    procedure BuildFRPServerCfg(ns: TCoreClassStrings);
    procedure StopAllTh(th: TExecThread);
  end;

var
  zsGatewayMiniServConfigureForm: TzsGatewayMiniServConfigureForm = nil;
  ExecThreadList                : TCoreClassListForObj            = nil;
  DefaultPath                   : string                          = '';

function FindProcessCount(AFileName: string): Integer;
function FindProcess(AFileName: string): Boolean;
procedure EndProcess(AFileName: string);
function WinExecFile(fn: umlString): TExecThread;

implementation

{$R *.dfm}


function FindProcessCount(AFileName: string): Integer;
var
  hSnapshot : THandle;         // ���ڻ�ý����б�
  lppe      : TProcessEntry32; // ���ڲ��ҽ���
  Found     : Boolean;         // �����жϽ��̱����Ƿ����
  KillHandle: THandle;         // ����ɱ������
begin
  Result := 0;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0); // ���ϵͳ�����б�
  lppe.dwSize := SizeOf(TProcessEntry32);                       // �ڵ���Process32First API֮ǰ����Ҫ��ʼ��lppe��¼�Ĵ�С
  Found := Process32First(hSnapshot, lppe);                     // �������б�ĵ�һ��������Ϣ����ppe��¼��
  while Found do
    begin
      if SameText(ExtractFileName(lppe.szExeFile), AFileName) or SameText(lppe.szExeFile, AFileName) then
          inc(Result);
      Found := Process32Next(hSnapshot, lppe); // �������б����һ��������Ϣ����lppe��¼��
    end;
end;

function FindProcess(AFileName: string): Boolean;
var
  hSnapshot : THandle;         // ���ڻ�ý����б�
  lppe      : TProcessEntry32; // ���ڲ��ҽ���
  Found     : Boolean;         // �����жϽ��̱����Ƿ����
  KillHandle: THandle;         // ����ɱ������
begin
  Result := False;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0); // ���ϵͳ�����б�
  lppe.dwSize := SizeOf(TProcessEntry32);                       // �ڵ���Process32First API֮ǰ����Ҫ��ʼ��lppe��¼�Ĵ�С
  Found := Process32First(hSnapshot, lppe);                     // �������б�ĵ�һ��������Ϣ����ppe��¼��
  while Found do
    begin
      if SameText(ExtractFileName(lppe.szExeFile), AFileName) or SameText(lppe.szExeFile, AFileName) then
        begin
          Result := True;
        end;
      Found := Process32Next(hSnapshot, lppe); // �������б����һ��������Ϣ����lppe��¼��
    end;
end;

procedure EndProcess(AFileName: string);
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop   : BOOL;
  FSnapShotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  FSnapShotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapShotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
    begin
      if SameText(ExtractFileName(FProcessEntry32.szExeFile), AFileName) or SameText(FProcessEntry32.szExeFile, AFileName) then
          TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), FProcessEntry32.th32ProcessID), 0);
      ContinueLoop := Process32Next(FSnapShotHandle, FProcessEntry32);
    end;
end;

function WinExecFile(fn: umlString): TExecThread;
begin
  Result := TExecThread.Create(True);
  Result.FileName := fn;
  Result.Suspended := False;
end;

procedure TExecThread.Execute;
const
  Buffsize   = 65535;
  HideWindow = True;
var
  WasOK    : Boolean;
  Buffer   : array [0 .. Buffsize] of Char;
  BytesRead: Cardinal;
begin
  FreeOnTerminate := True;

  TThread.Synchronize(Self, procedure
    begin
      ExecThreadList.Add(Self);
    end);

  if HideWindow then
    begin
      with SA do
        begin
          nLength := SizeOf(SA);
          bInheritHandle := True;
          lpSecurityDescriptor := nil;
        end;

      { create pipe for standard output redirection }
      CreatePipe(StdOutPipeRead, { read handle }
      StdOutPipeWrite,           { write handle }
      @SA,                       { security attributes }
      0                          { number of bytes reserved for pipe - 0 default }
        );
    end;

  try
    { Make child process use StdOutPipeWrite as standard out, and
      make sure it does not show on screen }
    with SI do
      begin
        FillChar(SI, SizeOf(SI), 0);
        cb := SizeOf(SI);
        dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
        if HideWindow then
          begin
            wShowWindow := SW_HIDE;
            hStdInput := GetStdHandle(STD_INPUT_HANDLE); { don't redirect stdinput }
            hStdOutput := StdOutPipeWrite;
            hStdError := StdOutPipeWrite;
          end
        else
          begin
            wShowWindow := SW_SHOW;
          end;
      end;

    WasOK := CreateProcess(nil, PChar(FileName.Text), nil, nil, True, 0, nil, nil, SI, PI);
    {
      Now that the handle has been inherited, close write to be safe.We don't
      want to read or write to it accidentally
    }
    if HideWindow then
        CloseHandle(StdOutPipeWrite);

    { if process could be created then handle its output }
    if WasOK then
      begin
        try
          if HideWindow then
            begin
              { get all output until DOS app finishes }
              repeat
                { read block of characters (might contain carriage returns and line feeds) }
                WasOK := ReadFile(StdOutPipeRead, Buffer, Buffsize, BytesRead, nil);
                { has anything been read? }
                if (WasOK) and (BytesRead > 0) then
                  begin
                    { finish buffer to PChar }
                    Buffer[BytesRead + 1] := #0;
                    OemToAnsi(@Buffer, @Buffer);
                    { combine the buffer with the rest of the last run }
                    TThread.Synchronize(Self, procedure
                      begin
                        DoStatus(StrPas(PAnsiChar(@Buffer)));
                      end);
                  end;
              until (not WasOK) or (BytesRead = 0);
            end;
          { wait for console app to finish (should be already at this point) }
          WaitForSingleObject(PI.hProcess, INFINITE);
          GetExitCodeProcess(PI.hProcess, ExecCode);
        finally
          { Close all remaining handles }
          CloseHandle(PI.hThread);
          CloseHandle(PI.hProcess);
        end;
      end
    else
      begin
        ExecCode := 0;
      end;
  finally
    if HideWindow then
        CloseHandle(StdOutPipeRead);

    TThread.Synchronize(Self, procedure
      var
        i: Integer;
      begin
        i := 0;
        while i < ExecThreadList.Count do
          begin
            if ExecThreadList[i] = Self then
                ExecThreadList.Delete(i)
            else
                inc(i);
          end;

        if zsGatewayMiniServConfigureForm.servTh = Self then
            zsGatewayMiniServConfigureForm.servTh := nil;
      end);
  end;
end;

procedure TzsGatewayMiniServConfigureForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopAllTh(nil);

  if FindProcess('_fs.exe') then
      EndProcess('_fs.exe');

  umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.ini'));
  umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.exe'));

  Action := caFree;
end;

procedure TzsGatewayMiniServConfigureForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SaveConfig;
  CanClose := True;
end;

procedure TzsGatewayMiniServConfigureForm.FormCreate(Sender: TObject);
var
  c64: TResourceStream;
  m64: TMemoryStream64;
begin
  if FindProcess('_fs.exe') then
      EndProcess('_fs.exe');
  umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.ini'));
  umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.exe'));

  AddDoStatusHook(Self, DoStatusMethod);
  {$IFDEF CPU64}
  x64RadioButton.Checked := True;
  {$ELSE}
  X86RadioButton.Checked := True;
  {$IFEND}
  //
  c64 := TResourceStream.Create(hInstance, 'FRPMiniServPackage', RT_RCDATA);
  m64 := TMemoryStream64.Create;
  DecompressStream(c64, m64);
  m64.Position := 0;
  DBEng := TObjectDataManagerOfCache.CreateAsStream(m64, '', 0, True, False, True);
  DisposeObject(c64);

  RandomTokenButtonClick(RandomTokenButton);

  Configure := TSectionTextData.Create;

  ConfigureService := TCommunicationFramework_Server_CrossSocket.Create;
  ConfigureService.RegisterStream('GetConfigure').OnExecute := cmd_GetConfigure;
  ConfigureService.QuietMode := True;
  ConfigureService.SwitchMaxSafe;

  EnabledRemoteConfigureCheckBox.OnClick := nil;
  LoadConfig;

  ExecThreadList := TCoreClassListForObj.Create;

  servTh := nil;
  ProgressPost := TNProgressPostWithCadencer.Create;

  EnabledRemoteConfigureCheckBox.OnClick := EnabledRemoteConfigureCheckBoxClick;
  EnabledRemoteConfigureCheckBoxClick(EnabledRemoteConfigureCheckBox);

  sysProcessTimer.Enabled := True;
  NetworkTimer.Enabled := True;
end;

procedure TzsGatewayMiniServConfigureForm.FormDestroy(Sender: TObject);
begin
  DisposeObject([DBEng, Configure, ExecThreadList, ProgressPost, ConfigureService]);
end;

procedure TzsGatewayMiniServConfigureForm.GatewayTrayIconClick(Sender: TObject);
begin
  Show;
  GatewayTrayIcon.Visible := False;
end;

procedure TzsGatewayMiniServConfigureForm.AboutButtonClick(Sender: TObject);
begin
  MessageDlg('Gateway Service create qq600585' + #13#10 + '2018-1-15', mtInformation, [mbYes], 0);
end;

procedure TzsGatewayMiniServConfigureForm.AddItmButtonClick(Sender: TObject);
var
  i: Integer;
  n: string;
begin
  if umlTrimSpace(SharePortComboBox.Text).len = 0 then
      exit;

  n := Format('s%s', [SharePortComboBox.Text]);
  for i := 0 to ListView.Items.Count - 1 do
    begin
      if SameText(n, ListView.Items[i].Caption) then
          exit;
      if (ListView.Items[i].SubItems.Count > 0) and (SameText(SharePortComboBox.Text, ListView.Items[i].SubItems[0])) then
          exit;
    end;

  with ListView.Items.Add do
    begin
      Caption := n;
      SubItems.Add(SharePortComboBox.Text);
      ImageIndex := -1;
      StateIndex := -1;
    end;

  umlAddNewStrTo(SharePortComboBox.Text, SharePortComboBox.Items);
end;

procedure TzsGatewayMiniServConfigureForm.DeleteItmButtonClick(Sender: TObject);
begin
  ListView.DeleteSelected;
end;

procedure TzsGatewayMiniServConfigureForm.RandomTokenButtonClick(Sender: TObject);
var
  n: string;
  i: Integer;
  c: SystemChar;
begin
  n := '';
  for i := 1 to 16 do
    begin
      repeat
          c := SystemChar(umlRandomRange(32, 128));
      until charIn(c, [c1to9, cLoAtoZ, cHiAtoZ]);
      n := n + c;
    end;
  TokenEdit.Text := n;
end;

procedure TzsGatewayMiniServConfigureForm.saveButtonClick(Sender: TObject);
begin
  SaveConfig;
end;

procedure TzsGatewayMiniServConfigureForm.StartServerListenButtonClick(Sender: TObject);
var
  itmStream: TItemStream;
  m64      : TMemoryStream64;
  ns       : TCoreClassStringList;
begin
  if servTh <> nil then
    begin
      Self.StopAllTh(servTh);
      servTh := nil;
      StartServerListenButton.Caption := 'Start NAT Service';
      umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.ini'));
      umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.exe'));
      exit;
    end;

  SaveConfig;

  if x64RadioButton.Checked then
      itmStream := TItemStream.Create(DBEng, '/frp64', 'frps.exe')
  else
      itmStream := TItemStream.Create(DBEng, '/frp86', 'frps.exe');

  m64 := TMemoryStream64.Create;
  m64.CopyFrom(itmStream, itmStream.Size);
  DisposeObject(itmStream);
  try
      m64.SaveToFile(umlCombineFileName(DefaultPath, '_fs.exe'));
  except
  end;
  DisposeObject(m64);

  ns := TCoreClassStringList.Create;
  BuildFRPServerCfg(ns);
  ns.SaveToFile(umlCombineFileName(DefaultPath, '_fs.ini'));
  DisposeObject(ns);

  servTh := WinExecFile(umlCombineFileName(DefaultPath, '_fs.exe') + Format(' -c "%s"', [umlCombineFileName(DefaultPath, '_fs.ini').Text]));

  StartServerListenButton.Caption := 'Stop NAT Service';

  ProgressPost.PostExecute(2.0, procedure(Sender: TNPostExecute)
    begin
      umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.ini'));
    end);
end;

procedure TzsGatewayMiniServConfigureForm.StopAllTh(th: TExecThread);
var
  i: Integer;
begin
  if th = nil then
    begin
      while ExecThreadList.Count > 0 do
        begin
          th := TExecThread(ExecThreadList[0]);
          th.Suspended := True;
          ExecThreadList.Delete(0);
          TerminateProcess(th.PI.hProcess, 0);
          th.Terminate;
        end;
    end
  else
    begin
      i := 0;
      while i < ExecThreadList.Count do
        begin
          if ExecThreadList[i] = th then
            begin
              th.Suspended := True;
              ExecThreadList.Delete(i);
              TerminateProcess(th.PI.hProcess, 0);
              th.Terminate;
              break;
            end
          else
              inc(i);
        end;
    end;
  Memo.Visible := ExecThreadList.Count > 0;
  if not Memo.Visible then
    begin
      Memo.Clear;
      Position := TPosition.poScreenCenter;
    end;
end;

procedure TzsGatewayMiniServConfigureForm.sysProcessTimerTimer(Sender: TObject);
begin
  if servTh <> nil then
      StartServerListenButton.Caption := 'Stop NAT Service'
  else
    begin
      StartServerListenButton.Caption := 'Start NAT Service';
      EndProcess('_fs.exe');
      umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.ini'));
      umlDeleteFile(umlCombineFileName(DefaultPath, '_fs.exe'));
    end;
end;

procedure TzsGatewayMiniServConfigureForm.cmd_GetConfigure(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
begin
  SaveConfigAsMemory;
  OutData.WriteTextSection(Configure);
end;

procedure TzsGatewayMiniServConfigureForm.LoadConfig;
var
  ns: TCoreClassStrings;
  i : Integer;
  n : string;
begin
  if umlFileExists(umlCombineFileName(DefaultPath, 'ZSGatewayMiniServerConfigure.ini')) then
    begin
      Configure.LoadFromFile(umlCombineFileName(DefaultPath, 'ZSGatewayMiniServerConfigure.ini'));

      SharePortComboBox.Items.Assign(Configure.Names['SharePort']);

      SharePortComboBox.Text := Configure.GetDefaultValue('options', SharePortComboBox.Name, SharePortComboBox.Text);

      RemoteConfigurePortEdit.Text := Configure.GetDefaultValue('options', RemoteConfigurePortEdit.Name, RemoteConfigurePortEdit.Text);
      EnabledRemoteConfigureCheckBox.Checked := Configure.GetDefaultValue('options', EnabledRemoteConfigureCheckBox.Name, EnabledRemoteConfigureCheckBox.Checked);
      IPV6CheckBox.Checked := Configure.GetDefaultValue('options', IPV6CheckBox.Name, IPV6CheckBox.Checked);

      NatPortEdit.Text := Configure.GetDefaultValue('options', NatPortEdit.Name, NatPortEdit.Text);
      WebPortEdit.Text := Configure.GetDefaultValue('options', WebPortEdit.Name, WebPortEdit.Text);
      TokenEdit.Text := Configure.GetDefaultValue('options', TokenEdit.Name, TokenEdit.Text);

      ns := Configure.Names['NATListens'];

      ListView.Items.BeginUpdate;
      ListView.Items.Clear;
      for i := 0 to ns.Count - 1 do
        begin
          n := ns[i];
          with ListView.Items.Add do
            begin
              Caption := Format('s%s', [n]);
              SubItems.Add(n);
              ImageIndex := -1;
              StateIndex := -1;
            end;
        end;
      ListView.Items.EndUpdate;
    end;
end;

procedure TzsGatewayMiniServConfigureForm.MinimizedToTaskButtonClick(
  Sender: TObject);
begin
  Hide;
  GatewayTrayIcon.Visible := True;
end;

procedure TzsGatewayMiniServConfigureForm.NetworkTimerTimer(
  Sender: TObject);
begin
  ConfigureService.ProgressBackground;
  ProgressPost.Progress;
end;

procedure TzsGatewayMiniServConfigureForm.SaveConfigAsMemory;
var
  ns: TCoreClassStrings;
  i : Integer;
begin
  Configure.Names['SharePort'].Assign(SharePortComboBox.Items);

  Configure.SetDefaultValue('options', SharePortComboBox.Name, SharePortComboBox.Text);

  Configure.SetDefaultValue('options', RemoteConfigurePortEdit.Name, RemoteConfigurePortEdit.Text);
  Configure.SetDefaultValue('options', EnabledRemoteConfigureCheckBox.Name, EnabledRemoteConfigureCheckBox.Checked);
  Configure.SetDefaultValue('options', IPV6CheckBox.Name, IPV6CheckBox.Checked);

  Configure.SetDefaultValue('options', NatPortEdit.Name, NatPortEdit.Text);
  Configure.SetDefaultValue('options', WebPortEdit.Name, WebPortEdit.Text);
  Configure.SetDefaultValue('options', TokenEdit.Name, TokenEdit.Text);

  ns := Configure.Names['NATListens'];
  ns.Clear;

  for i := 0 to ListView.Items.Count - 1 do
    if ListView.Items[i].SubItems.Count > 0 then
        umlAddNewStrTo(ListView.Items[i].SubItems[0], ns);
end;

procedure TzsGatewayMiniServConfigureForm.SaveConfig;
begin
  Configure.SaveToFile(umlCombineFileName(DefaultPath, 'ZSGatewayMiniServerConfigure.ini'));
end;

procedure TzsGatewayMiniServConfigureForm.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  if not Memo.Visible then
    begin
      Memo.Visible := True;
      Position := TPosition.poScreenCenter;
    end;

  Memo.Lines.Add(AText);
end;

procedure TzsGatewayMiniServConfigureForm.EnabledRemoteConfigureCheckBoxClick(Sender: TObject);
begin
  ConfigureService.StopService;

  if EnabledRemoteConfigureCheckBox.Checked then
    begin
      ConfigureService.StartService('', umlStrToInt(RemoteConfigurePortEdit.Text, 4797));
    end
  else
    begin
      ConfigureService.StopService;
    end;
end;

procedure TzsGatewayMiniServConfigureForm.BuildFRPServerCfg(ns: TCoreClassStrings);
var
  i: Integer;
begin
  ns.Clear;

  ns.Add('# Service build from ZSGatewayMiniServ v1.0');
  ns.Add(Format('[common]', []));

  if IPV6CheckBox.Checked then
      ns.Add(Format('bind_addr = [::1]', []))
  else
      ns.Add(Format('bind_addr = 0.0.0.0', []));

  ns.Add(Format('bind_port = %s', [NatPortEdit.Text]));
  ns.Add(Format('dashboard_port = %s', [WebPortEdit.Text]));
  ns.Add(Format('dashboard_user = %s', [TokenEdit.Text]));
  ns.Add(Format('dashboard_pwd = %s', [TokenEdit.Text]));
  ns.Add(Format('privilege_mode = true', []));
  ns.Add(Format('privilege_token = %s', [TokenEdit.Text]));

  for i := 0 to ListView.Items.Count - 1 do
    if ListView.Items[i].SubItems.Count > 0 then
      begin
        ns.Add(Format('', []));
        ns.Add(Format('[%s]', [ListView.Items[i].Caption]));
        ns.Add(Format('type = tcp', []));
        ns.Add(Format('auth_token = %s', [TokenEdit.Text]));

        if IPV6CheckBox.Checked then
            ns.Add(Format('bind_addr = [::1]', []))
        else
            ns.Add(Format('bind_addr = 0.0.0.0', []));

        ns.Add(Format('listen_port = %s', [ListView.Items[i].SubItems[0]]));
      end;
end;

initialization

DefaultPath := System.IOUtils.TPath.GetTempPath;

finalization

end.
