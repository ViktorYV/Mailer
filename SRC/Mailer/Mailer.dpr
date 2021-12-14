program Mailer;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {MainFms},
  Log in 'Log.pas',
  SettingsFrm in 'SettingsFrm.pas' {SetFrm},
  StartForm in 'StartForm.pas' {StartFrm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFms, MainFms);
  Application.CreateForm(TSetFrm, SetFrm);
  Application.CreateForm(TStartFrm, StartFrm);
  Application.Run;
end.
