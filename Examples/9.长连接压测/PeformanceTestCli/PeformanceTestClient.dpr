program PeformanceTestClient;

uses
  Vcl.Forms,
  PeformanceTestCliFrm in 'PeformanceTestCliFrm.pas' {EZClientForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEZClientForm, EZClientForm);
  Application.Run;
end.
