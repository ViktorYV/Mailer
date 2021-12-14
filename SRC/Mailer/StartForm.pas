unit StartForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.jpeg,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage, SettingsFrm;

type
  TStartFrm = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    edLogin: TEdit;
    Label2: TLabel;
    edPass: TEdit;
    Label3: TLabel;
    edFilePath: TEdit;
    imgOk: TImage;
    imgNew: TImage;
    imgExit: TImage;
    imgOpenFile: TImage;
    imgHidePass: TImage;
    imgShowPass: TImage;
    procedure imgOpenFileClick(Sender: TObject);
    procedure imgOkClick(Sender: TObject);
    procedure imgExitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgNewClick(Sender: TObject);
    procedure imgShowPassClick(Sender: TObject);
    procedure imgHidePassClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
    Templ: RTempl;
    procedure SetPass(strPass: string);
    function GetPass: string;
    procedure SetUser(strUser: string);
    function GetUser: string;
    procedure SetFilePath(strFilePath: string);
    function GetFilePath: string;
    // procedure SetSubj(strSubj: string);
    function GetSubj: string;
    // procedure SetBody(strBody: string);
    function GetBody: string;
  public
    { Public declarations }

    property PASS: string read GetPass write SetPass;
    property User: string read GetUser write SetUser;
    property FilePath: string read GetFilePath write SetFilePath;
    property SUBJ: string read GetSubj; // write SetSubj;
    property BODY: string read GetBody; // write SetBody;
  end;

var
  StartFrm: TStartFrm;

implementation

{$R *.dfm}

procedure TStartFrm.FormActivate(Sender: TObject);
begin
  // //Self.BringToFront;
  // //BringWindowToTop(self.Handle);
  // SetForegroundWindow(self.Handle);
  // Application.ProcessMessages;
  // BringWindowToTop(self.Handle);
  // Application.ProcessMessages;
  SetWindowPos(self.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);
end;

procedure TStartFrm.FormCreate(Sender: TObject);
begin
  FillChar(Templ.BODY, Sizeof(Templ.BODY), 0);
  FillChar(Templ.SUBJ, Sizeof(Templ.SUBJ), 0);
  self.Left := (Screen.WorkAreaWidth - self.Width) div 2;
  self.Top := (Screen.WorkAreaHeight - self.Height) div 2;
end;

procedure TStartFrm.imgExitClick(Sender: TObject);
begin
  self.ModalResult := mrCancel;
end;

procedure TStartFrm.imgHidePassClick(Sender: TObject);
begin
  edPass.PasswordChar := '*';
  imgHidePass.Visible := false;
  imgShowPass.Visible := true;
  imgShowPass.BringToFront;
end;

procedure TStartFrm.imgNewClick(Sender: TObject);
var
  SettingsFrm: TSetFrm;
begin
  SettingsFrm := TSetFrm.Create(self);
  SetWindowPos(self.Handle, { HWND_TOPMOST } HWND_BOTTOM, 0, 0, 0, 0,
    SWP_NOSIZE or SWP_NOMOVE);
  if SettingsFrm.ShowModal = mrOk then
  begin
    edLogin.Text := SettingsFrm.LOGIN;
    edPass.Text := SettingsFrm.PASS;
    edFilePath.Text := SettingsFrm.FileName;
    SetWindowPos(self.Handle,  HWND_TOPMOST  , 0, 0, 0, 0,
    SWP_NOSIZE or SWP_NOMOVE);
  end;
end;

procedure TStartFrm.imgOkClick(Sender: TObject);
begin
  if ((edLogin.Text <> '') and (edPass.Text <> '') and
    (FileExists(edFilePath.Text))) then
  begin
    TSetFrm.GetParam(edLogin.Text, edPass.Text, edFilePath.Text, Templ);
    if ((Templ.LOGIN = edLogin.Text) and (edPass.Text = Templ.PASS)) then
    begin
      self.ModalResult := mrOk;
    end
    else
    begin
      MessageDlg('Логин или пароль не верны!', mtError, [mbOK], 0);
    end;
  end;

end;

procedure TStartFrm.imgOpenFileClick(Sender: TObject);
var
  OpenFileDlg: TOpenDialog;
  s: string;
  // SetFrm: TSetFrm;
begin
  OpenFileDlg := TOpenDialog.Create(nil);
  // OpenFileDlg.Filter := 'Текстовые файлы|*.txt; *.doc|Все файлы|*.*';
  OpenFileDlg.Filter := 'Файл конфигурации|*.mcfg|Все файлы|*.*';
  SetWindowPos(self.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE or
    SWP_NOMOVE);
  if OpenFileDlg.Execute then
  begin
    edFilePath.Text := OpenFileDlg.FileName;
  end;
  self.BringToFront;
end;

procedure TStartFrm.imgShowPassClick(Sender: TObject);
begin
  edPass.PasswordChar := #0;
  imgHidePass.Visible := true;
  imgShowPass.Visible := false;
  imgHidePass.BringToFront;
end;

procedure TStartFrm.SetPass(strPass: string);
begin
  edPass.Text := strPass;
end;

function TStartFrm.GetPass: string;
begin
  Result := edPass.Text;
end;

procedure TStartFrm.SetFilePath(strFilePath: string);
begin
  edFilePath.Text := strFilePath;
end;

function TStartFrm.GetFilePath: string;
begin
  Result := edFilePath.Text;
end;

procedure TStartFrm.SetUser(strUser: string);
begin
  edLogin.Text := strUser;
end;

function TStartFrm.GetUser: string;
begin
  Result := edLogin.Text;
end;

function TStartFrm.GetSubj: string;
begin
  Result := Templ.SUBJ;
end;

function TStartFrm.GetBody: string;
begin
  Result := Templ.BODY;
end;

end.
