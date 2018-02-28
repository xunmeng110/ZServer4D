unit MHMainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  DoStatusIO, PascalStrings, CoreClasses, UnicodeMixedLib, ListEngine;

type
  TMHMainForm = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
  end;

var
  MHMainForm: TMHMainForm;

implementation

{$R *.dfm}


uses MH_1, MH_2, MH_3, MH;

procedure TMHMainForm.Button1Click(Sender: TObject);

  procedure leakproc(x, m: Integer);
  begin
    GetMemory(x);
    if x > m then
        leakproc(x - 1, m);
  end;

begin
  MH.BeginMemoryHook_1;
  leakproc(100, 98);
  MH.EndMemoryHook_1;

  // �������ǻᷢ��й©
  DoStatus('leakproc���������� %d �ֽڵ��ڴ�', [MH.GetHookMemorySize_1]);

  MH.GetHookPtrList_1.Progress(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      DoStatus('й©�ĵ�ַ:0x%s', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2)]);
      DoStatus(NPtr, uData, 80);

      // �������ǿ���ֱ���ͷŸõ�ַ
      Dispose(NPtr);

      DoStatus('�ѳɹ��ͷ� ��ַ:0x%s ռ���� %d �ֽ��ڴ�', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2), uData]);
    end);
end;

procedure TMHMainForm.Button2Click(Sender: TObject);
type
  PMyRec = ^TMyRec;

  TMyRec = record
    s1: string;
    s2: string;
    s3: TPascalString;
    obj: TObject;
  end;

var
  p: PMyRec;
begin
  MH.BeginMemoryHook_1;
  new(p);
  p^.s1 := #7#8#9;
  p^.s2 := #$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20;
  p^.s3.Text := #1#2#3#4#5#6;
  p^.obj := TObject.Create;
  MH.EndMemoryHook_1;

  // �������ǻᷢ��й©
  DoStatus('TMyRec�ַܷ����� %d ���ڴ棬ռ�� %d �ֽڿռ䣬', [MH.GetHookPtrList_1.Count, MH.GetHookMemorySize_1]);

  MH.GetHookPtrList_1.Progress(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      DoStatus('й©�ĵ�ַ:0x%s', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2)]);
      DoStatus(NPtr, uData, 80);

      // �������ǿ���ֱ���ͷŸõ�ַ
      FreeMem(NPtr);

      DoStatus('�ѳɹ��ͷ� ��ַ:0x%s ռ���� %d �ֽ��ڴ�', [IntToHex(NativeUInt(NPtr), sizeof(Pointer) * 2), uData]);
    end);
end;

procedure TMHMainForm.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(AText)
end;

procedure TMHMainForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
end;

procedure TMHMainForm.Button3Click(Sender: TObject);
type
  PMyRec = ^TMyRec;

  TMyRec = record
    s1: string;
    p: PMyRec;
  end;

var
  p: PMyRec;
  i: Integer;
begin
  // 100��εķ������������ͷ�
  // ���ֳ����������������ͳ����ĳ���������¼�ڴ�����
  for i := 0 to 100 * 10000 do
    begin
      MH_2.BeginMemoryHook(4);
      new(p);
      p^.s1 := '12345';
      new(p^.p);
      p^.p^.s1 := '54321';
      MH_2.EndMemoryHook;

      MH_2.HookPtrList.Progress(procedure(NPtr: Pointer; uData: NativeUInt)
        begin
          // �������ǿ����ͷŸõ�ַ
          FreeMem(NPtr);
        end);
    end;
end;

procedure TMHMainForm.Button4Click(Sender: TObject);
type
  PMyRec = ^TMyRec;

  TMyRec = record
    s1: string;
    p: PMyRec;
  end;

var
  p : PMyRec;
  i : Integer;
  hl: TPointerHashNativeUIntList;
begin
  // 200��εĴ�������¼�ڴ����룬���һ�����ͷ�
  // ���ֳ���������������������ͷ�й©���ڴ�

  // �����ڽ�20���Hash������д洢
  // BeginMemoryHook�Ĳ���Խ����ԶԴ������洢�ĸ�Ƶ�ʼ�¼���ܾ�Խ�ã���ҲԽ�����ڴ�
  MH_3.BeginMemoryHook(200000);

  for i := 0 to 200 * 10000 do
    begin
      new(p);
      new(p^.p);
      // ģ���ַ�����ֵ����Ƶ�ʴ���Realloc����
      p^.s1 := '111111111111111';
      p^.s1 := '1111111111111111111111111111111111';
      p^.s1 := '11111111111111111111111111111111111111111111111111111111111111';
      p^.p^.s1 := '1';
      p^.p^.s1 := '11111111111111111111';
      p^.p^.s1 := '1111111111111111111111111111111111111';
      p^.p^.s1 := '11111111111111111111111111111111111111111111111111111111111111111111111111';

      if i mod 99999 = 0 then
        begin
          // �����ǵ������ã����ǲ���¼����MH_3.MemoryHooked����ΪFalse����
          MH_3.MemoryHooked := False;
          Button1Click(nil);
          Application.ProcessMessages;
          // ������¼�ڴ�����
          MH_3.MemoryHooked := True;
        end;
    end;
  MH_3.EndMemoryHook;

  DoStatus('�ܹ��ڴ���� %d �� ռ�� %s �ռ䣬��ַ���Ϊ��%s ', [MH_3.HookPtrList.Count, umlSizeToStr(MH_3.GetHookMemorySize).Text,
    umlSizeToStr(NativeUInt(MH_3.GetHookMemoryMaximumPtr) - NativeUInt(MH_3.GetHookMemoryMinimizePtr)).Text]);

  MH_3.HookPtrList.Progress(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      // �������ǿ����ͷŸõ�ַ
      FreeMem(NPtr);
    end);
  MH_3.HookPtrList.PrintHashReport;
  MH_3.HookPtrList.SetHashBlockCount(0);
end;

procedure TMHMainForm.Button5Click(Sender: TObject);

var
  s   : string;
  sptr: PString;
begin
  MH_1.BeginMemoryHook(16);

  Memo1.Lines.Add('123'); // ��Ϊû��ǰ���Ĳο��������Realloc��GetMem�����ᱻ��¼
  s := '12345';           // ��Ϊs�ַ����ڵ��ÿ�ʼʱ�Ѿ���ʼ����û��ǰ���Ĳο��������Realloc���ᱻ��¼

  new(sptr); // ������¼sptr��GetMem��ַ
  sptr^ := '123';
  sptr^ := '123456789'; // �ڷ����˶�sptr��Reallocʱ��mh��Ѱ��ǰ���ģ����������realloc�ļ�¼������mh����¼���������ں����ͷ�

  // mh֧�ֿؼ��������ͷ�
  // mh��֧��tform�����ͷţ���Ϊtform���ڻ�ע��ȫ�ֲ�����mh���ͷ���tform�Ժ�ĳЩ�ص�����û�е�ַ�ͻᱨ��
  TButton.Create(Self).Free;

  MH_1.EndMemoryHook;

  MH_1.HookPtrList.Progress(procedure(NPtr: Pointer; uData: NativeUInt)
    begin
      // �������ǿ����ͷŸõ�ַ
      DoStatus(NPtr, uData, 80);
      FreeMem(NPtr);
    end);

  MH_1.HookPtrList.SetHashBlockCount(0);
end;

end.
