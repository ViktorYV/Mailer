unit SettingsFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, IdBaseComponent, IdCoder, IdCoder3to4, IdCoder00E,
  IdCoderXXE, IdCoderUUE, IdCoderMIME, IdGlobal;

type
  RTempl = record
    LOGIN: array [0 .. 48] of char;
    PASS: array [0 .. 48] of char;
    SUBJ: array [0 .. 200] of char;
    BODY: array [0 .. 4096] of char;
  end;

const
  GUID = '64bcabf1-46da-4e00-a1ad-f93b1898347e';

type
  TSetFrm = class(TForm)
    Panel1: TPanel;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    edLogin: TEdit;
    edPass: TEdit;
    Label3: TLabel;
    edSubj: TEdit;
    btnOk: TButton;
    imgShowPass: TImage;
    imgHidePass: TImage;
    Button1: TButton;
    procedure imgShowPassClick(Sender: TObject);
    procedure imgHidePassClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    _strFileName: string;
    procedure SetPass(strPass: string);
    function GetPass: string;
    procedure SetUser(strUser: string);
    function GetUser: string;
    procedure SetSubj(strSubj: string);
    function GetSubj: string;
    procedure SetBody(strBody: string);
    function GetBody: string;
  public
    { Public declarations }
    class function Crypt(strText, strGuid: string; code: boolean): string;
    class function GetParam(strUser, strPass, strFileName: string;
      var info: RTempl): boolean;
    class function SaveParam(strUser, strPass, strFileName: string;
      info: RTempl): boolean;
    property PASS: string read GetPass write SetPass;
    property LOGIN: string read GetUser write SetUser;
    property SUBJ: string read GetSubj write SetSubj;
    property BODY: string read GetBody write SetBody;
    property FileName: string read _strFileName write _strFileName;
  end;

var
  SetFrm: TSetFrm;

implementation

{$R *.dfm}
{$REGION 'for property'}

procedure TSetFrm.SetPass(strPass: string);
begin
  edPass.Text := strPass;
end;

function TSetFrm.GetPass: string;
begin
  Result := edPass.Text;
end;

procedure TSetFrm.SetUser(strUser: string);
begin
  edLogin.Text := strUser;
end;

function TSetFrm.GetUser: string;
begin
  Result := edLogin.Text;
end;

procedure TSetFrm.SetSubj(strSubj: string);
begin
  edSubj.Text := strSubj;
end;

function TSetFrm.GetSubj: string;
begin
  Result := edSubj.Text;
end;

procedure TSetFrm.SetBody(strBody: string);
begin
  Memo1.Text := StringReplace(strBody, '%0D%0A', #13#10,
    [rfReplaceAll, rfIgnoreCase]);
end;

function TSetFrm.GetBody: string;
var
  strRes: string;
  I: integer;
begin
  strRes := '';

  for I := 0 to Memo1.Lines.Count - 1 do
  begin
    strRes := strRes + Memo1.Lines[I] + '%0D%0A';
  end;

  Result := strRes; // Memo1.Text;
end;
{$ENDREGION}

procedure TSetFrm.btnOkClick(Sender: TObject);
var
  saveDialog: TSaveDialog;
  info: RTempl;
begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Save your settings';
  saveDialog.Filter := 'Файл конфигурации|*.mcfg';
  saveDialog.DefaultExt := 'mcfg';
  if saveDialog.Execute then
  begin
    FillChar(info.LOGIN, Sizeof(info.LOGIN), 0);
    FillChar(info.PASS, Sizeof(info.PASS), 0);
    FillChar(info.BODY, Sizeof(info.BODY), 0);
    FillChar(info.SUBJ, Sizeof(info.SUBJ), 0);

    StrPLCopy(info.LOGIN, LOGIN, High(info.LOGIN));
    StrPLCopy(info.PASS, PASS, High(info.PASS));
    StrPLCopy(info.SUBJ, SUBJ, High(info.SUBJ));
    StrPLCopy(info.BODY, BODY, High(info.BODY));

    FileName := saveDialog.FileName;

    SaveParam(edLogin.Text, edPass.Text, saveDialog.FileName, info);
  end;
  self.ModalResult := mrOk;
end;

procedure TSetFrm.Button1Click(Sender: TObject);
begin
  self.ModalResult := mrCancel;
end;

procedure TSetFrm.imgHidePassClick(Sender: TObject);
begin
  edPass.PasswordChar := '*';
  imgHidePass.Visible := false;
  imgShowPass.Visible := true;
  imgShowPass.BringToFront;
end;

function XorEncodeU(Source, Key: String): String;
var
  I, nBytes: integer;
  C: Word;
begin
  Result := '';
  if Length(Source) < 1 then
    exit;

  nBytes := 4; // * 2;//Source[1]) * 2;

  for I := 1 to Length(Source) do
  begin
    if Length(Key) > 0 then
      C := Word(Key[1 + ((I - 1) mod Length(Key))]) xor Word(Source[I])
    else
      C := Word(Source[I]);
    Result := Result + LowerCase(IntToHex(C, nBytes));
    // 4));     // Sizeof(Source[1])));
  end;
end;

function XorDecodeU(Source, Key: String): String;
var
  I, nBytes: integer;
  C: char;
begin

  Result := '';
  if Length(Source) < 1 then
    exit;

  nBytes := 4; // Sizeof(widechar);//Source[1]);// * 2;//Source[1]) * 2;

  for I := 0 to (Length(Source) div nBytes { 4 } ) - 1 do
  begin
    C := char(StrToIntDef('$' + Copy(Source, (I * nBytes { 4 } ) + 1,
      nBytes { 4 } ), Ord(' ')));
    if Length(Key) > 0 then
      C := char(Word(Key[1 + (I mod Length(Key))]) xor Word(C));
    Result := Result + C;
  end;
end;

class function TSetFrm.Crypt(strText, strGuid: string; code: boolean): string;
// var
// I, Delta, res, Pas: integer;
// guid: TGUID;
// arrbyte: TArray<Byte>;
// s: string;
begin
  if code then
  begin
    Result := XorEncodeU(strText, strGuid); // EncodeString( strText);
  end
  else
  begin
    Result := XorDecodeU(strText, strGuid);
  end;

end;

class function TSetFrm.GetParam(strUser, strPass, strFileName: string;
  var info: RTempl): boolean;
var
  res: boolean;
  fmtrem: TMemoryStream;
begin
  res := false;
  FillChar(info.LOGIN, Sizeof(info.LOGIN), 0);
  FillChar(info.PASS, Sizeof(info.PASS), 0);
  FillChar(info.SUBJ, Sizeof(info.SUBJ), 0);
  FillChar(info.BODY, Sizeof(info.BODY), 0);

  try
    fmtrem := TMemoryStream.Create;
    fmtrem.LoadFromFile(strFileName);

    fmtrem.Read(info.LOGIN, Sizeof(info.LOGIN));
    fmtrem.Read(info.PASS, Sizeof(info.PASS));
    fmtrem.Read(info.SUBJ, Sizeof(info.SUBJ));
    fmtrem.Read(info.BODY, Sizeof(info.BODY));

    StrPLCopy(info.LOGIN, Crypt(info.LOGIN, GUID { strPass } , false),
      High(info.LOGIN));
    StrPLCopy(info.PASS, Crypt(info.PASS, GUID { strUser } , false),
      High(info.PASS));
    StrPLCopy(info.SUBJ, Crypt(info.SUBJ, strUser + strPass, false),
      High(info.SUBJ));
    StrPLCopy(info.BODY, Crypt(info.BODY, strUser + strPass, false),
      High(info.BODY));

    fmtrem.Free;
    fmtrem := nil;
    res := true;
  except
    on E: Exception do
    begin
      MessageDlg('Ошибка!!!' + #13#10 + E.Message, mtError, [mbOK], 0);
    end;
  end;
  Result := res;
end;

class function TSetFrm.SaveParam(strUser, strPass, strFileName: string;
  info: RTempl): boolean;
var
  fstrem: TFileStream;
  res: boolean;
begin
  res := false;
  try

    StrPLCopy(info.LOGIN, Crypt(info.LOGIN, GUID { strUser + strPass } , true),
      High(info.LOGIN));
    StrPLCopy(info.PASS, Crypt(info.PASS, GUID { strUser + strPass } , true),
      High(info.PASS));
    StrPLCopy(info.SUBJ, Crypt(info.SUBJ, strUser + strPass, true),
      High(info.SUBJ));
    StrPLCopy(info.BODY, Crypt(info.BODY, strUser + strPass, true),
      High(info.BODY));

    fstrem := TFileStream.Create(strFileName, fmCreate);
    fstrem.write(info, Sizeof(info));
    fstrem.Free;
    fstrem := nil;
    res := true;
  except
    on E: Exception do
    begin
      MessageDlg('Ошибка!!!' + #13#10 + E.Message, mtError, [mbOK], 0);
    end;
  end;
  Result := res;
end;

procedure TSetFrm.imgShowPassClick(Sender: TObject);
begin
  edPass.PasswordChar := #0;
  imgHidePass.Visible := true;
  imgShowPass.Visible := false;
  imgHidePass.BringToFront;
end;

end.
